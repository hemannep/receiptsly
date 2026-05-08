import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sudokugame/utils/sudoku_generator.dart';
import 'dart:convert';

class DailyChallengeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'dailyChallenges';

  // In-memory cache: once fetched/generated this session, never re-fetch.
  static final Map<String, SudokuGame> _cache = {};

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<SudokuGame> getTodayChallenge() async {
    return getChallengeForDate(DateTime.now());
  }

  static Future<SudokuGame> getChallengeForDate(DateTime date) async {
    final dateString = _formatDate(date);

    // 1. Return cached result immediately — no network call at all.
    if (_cache.containsKey(dateString)) {
      print('⚡ Returning cached challenge for $dateString');
      return _cache[dateString]!;
    }

    // 2. Try Firebase with a 6-second timeout so the user isn't stuck waiting.
    try {
      print('🔍 Checking Firebase for challenge: $dateString');

      final doc = await _firestore
          .collection(_collection)
          .doc(dateString)
          .get()
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () => throw Exception('Firebase timeout'),
          );

      if (doc.exists) {
        print('✅ FOUND challenge in Firebase for $dateString');
        final game = _parseSudokuGame(doc.data() as Map<String, dynamic>);
        _cache[dateString] = game;
        return game;
      }

      // Document doesn't exist yet — generate, save, and cache it.
      print('⚠️ No challenge in Firebase for $dateString — generating...');
      final game = _deterministicGame(date);
      _cache[dateString] = game;

      // Save in background; don't await so the user isn't blocked.
      _saveChallengeToFirebase(dateString, game).catchError(
        (e) => print('⚠️ Background save failed (non-critical): $e'),
      );

      return game;
    } catch (e) {
      // 3. Offline / timeout fallback: generate a DETERMINISTIC puzzle from
      //    the date so every user gets the same board even without internet.
      print(
          '⚠️ Firebase unavailable ($e) — using deterministic offline puzzle');
      final game = _deterministicGame(date);
      _cache[dateString] = game;
      return game;
    }
  }

  // ── Deterministic generation ──────────────────────────────────────────────

  /// Converts a date into a stable integer seed so the same date always
  /// produces the same puzzle regardless of device or locale.
  static int _seedFromDate(DateTime date) {
    // e.g. 2026-05-07  →  20260507
    return date.year * 10000 + date.month * 100 + date.day;
  }

  /// Difficulty cycles across the week (same day-of-week → same difficulty).
  static int _removeCountForDate(DateTime date) {
    const counts = [20, 30, 40, 45, 50, 55, 60]; // Sun–Sat
    return counts[date.weekday % 7];
  }

  static SudokuGame _deterministicGame(DateTime date) {
    final seed = _seedFromDate(date);
    final removeCount = _removeCountForDate(date);
    print('🎲 Deterministic puzzle: seed=$seed, removals=$removeCount');
    return SudokuGenerator.generateSeeded(removeCount, seed);
  }

  // ── Firebase helpers ──────────────────────────────────────────────────────

  static Future<void> generateAndSaveChallengeToFirebase(
    String dateString,
  ) async {
    try {
      print('🎲 MANUAL: Generating challenge for $dateString...');

      final existingDoc =
          await _firestore.collection(_collection).doc(dateString).get();
      if (existingDoc.exists) {
        print('⚠️ Challenge already exists for $dateString');
        return;
      }

      final date = DateTime.parse(dateString);
      final game = _deterministicGame(date);
      await _saveChallengeToFirebase(dateString, game);
      print('✅ SAVED to Firebase: $dateString');
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  static Future<void> _saveChallengeToFirebase(
    String dateString,
    SudokuGame game,
  ) async {
    final clueCount = _countClues(game.board);
    final difficulty = _difficultyLabel(clueCount);

    await _firestore.collection(_collection).doc(dateString).set({
      'date': dateString,
      'difficulty': difficulty,
      'board': jsonEncode(game.board),
      'solution': jsonEncode(game.solution),
      'fixed': jsonEncode(game.fixed),
      'createdAt': FieldValue.serverTimestamp(),
      'clueCount': clueCount,
    });
    print('✅ Challenge saved: $dateString ($difficulty, $clueCount clues)');
  }

  static SudokuGame _parseSudokuGame(Map<String, dynamic> data) {
    try {
      List<List<int>> parseIntGrid(dynamic raw) {
        final list = raw is String ? jsonDecode(raw) as List : raw as List;
        return list
            .map((row) => List<int>.from((row as List).cast<int>()))
            .toList();
      }

      List<List<bool>> parseBoolGrid(dynamic raw) {
        final list = raw is String ? jsonDecode(raw) as List : raw as List;
        return list
            .map((row) => List<bool>.from((row as List).cast<bool>()))
            .toList();
      }

      final board = parseIntGrid(data['board']);
      final solution = parseIntGrid(data['solution']);
      final fixed = parseBoolGrid(data['fixed']);

      return SudokuGame(board, solution, fixed);
    } catch (e) {
      print('❌ Parse error: $e — falling back to deterministic puzzle');
      return _deterministicGame(DateTime.now());
    }
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  static int _countClues(List<List<int>> board) =>
      board.expand((r) => r).where((v) => v != 0).length;

  static String _difficultyLabel(int clueCount) {
    if (clueCount >= 60) return 'Newbie';
    if (clueCount >= 50) return 'Easy';
    if (clueCount >= 40) return 'Medium';
    if (clueCount >= 30) return 'Hard';
    return 'Extreme';
  }

  static String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  // ── Completion tracking (unchanged) ───────────────────────────────────────

  static Future<bool> hasUserCompletedChallenge(
    String userId,
    String dateString,
  ) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(dateString)
          .collection('completions')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking completion: $e');
      return false;
    }
  }

  static Future<void> markChallengeCompleted(
    String userId,
    String dateString,
    int score,
    int timeSpent,
  ) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(dateString)
          .collection('completions')
          .doc(userId)
          .set({
        'userId': userId,
        'score': score,
        'timeSpent': timeSpent,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking completion: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getLeaderboardForDate(
    String dateString,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(dateString)
          .collection('completions')
          .orderBy('score', descending: true)
          .limit(10)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTodayLeaderboard() async =>
      getLeaderboardForDate(_formatDate(DateTime.now()));
}
