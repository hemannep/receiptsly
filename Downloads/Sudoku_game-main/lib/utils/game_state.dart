import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudokugame/utils/game_progress.dart'
    show DifficultyRequirement, GameProgress;
import 'dart:convert';
import '../utils/sudoku_generator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GameStats — all the numbers the StatisticsScreen needs
// ─────────────────────────────────────────────────────────────────────────────

class GameStats {
  final int totalGamesPlayed;
  final int totalGamesWon;
  final int totalLosses;
  final int bestStreak;
  final int totalTimeSeconds;
  final int perfectGames; // wins with 0 mistakes
  final int dailyChallengesCompleted;
  final Map<String, int> bestTimesByDifficulty; // difficulty → best seconds
  final Map<String, int> bestScoresByDifficulty; // difficulty → best score

  const GameStats({
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.totalLosses = 0,
    this.bestStreak = 0,
    this.totalTimeSeconds = 0,
    this.perfectGames = 0,
    this.dailyChallengesCompleted = 0,
    this.bestTimesByDifficulty = const {},
    this.bestScoresByDifficulty = const {},
  });

  double get winRate =>
      totalGamesPlayed == 0 ? 0.0 : (totalGamesWon / totalGamesPlayed) * 100.0;

  /// Format total time as "Xh Ym" or "Ym Zs"
  String get formattedTotalTime {
    if (totalTimeSeconds <= 0) return '0m';
    final h = totalTimeSeconds ~/ 3600;
    final m = (totalTimeSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    final s = totalTimeSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Map<String, dynamic> toJson() => {
        'totalGamesPlayed': totalGamesPlayed,
        'totalGamesWon': totalGamesWon,
        'totalLosses': totalLosses,
        'bestStreak': bestStreak,
        'totalTimeSeconds': totalTimeSeconds,
        'perfectGames': perfectGames,
        'dailyChallengesCompleted': dailyChallengesCompleted,
        'bestTimesByDifficulty': bestTimesByDifficulty,
        'bestScoresByDifficulty': bestScoresByDifficulty,
      };

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
        totalGamesWon: json['totalGamesWon'] as int? ?? 0,
        totalLosses: json['totalLosses'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        totalTimeSeconds: json['totalTimeSeconds'] as int? ?? 0,
        perfectGames: json['perfectGames'] as int? ?? 0,
        dailyChallengesCompleted: json['dailyChallengesCompleted'] as int? ?? 0,
        bestTimesByDifficulty:
            (json['bestTimesByDifficulty'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(k, v as int)) ??
                {},
        bestScoresByDifficulty:
            (json['bestScoresByDifficulty'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(k, v as int)) ??
                {},
      );

  GameStats copyWith({
    int? totalGamesPlayed,
    int? totalGamesWon,
    int? totalLosses,
    int? bestStreak,
    int? totalTimeSeconds,
    int? perfectGames,
    int? dailyChallengesCompleted,
    Map<String, int>? bestTimesByDifficulty,
    Map<String, int>? bestScoresByDifficulty,
  }) =>
      GameStats(
        totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
        totalGamesWon: totalGamesWon ?? this.totalGamesWon,
        totalLosses: totalLosses ?? this.totalLosses,
        bestStreak: bestStreak ?? this.bestStreak,
        totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
        perfectGames: perfectGames ?? this.perfectGames,
        dailyChallengesCompleted:
            dailyChallengesCompleted ?? this.dailyChallengesCompleted,
        bestTimesByDifficulty:
            bestTimesByDifficulty ?? this.bestTimesByDifficulty,
        bestScoresByDifficulty:
            bestScoresByDifficulty ?? this.bestScoresByDifficulty,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Move
// ─────────────────────────────────────────────────────────────────────────────

class Move {
  final int r, c, value;
  final Set<int> notes;

  Move(this.r, this.c, this.value, this.notes);

  Map<String, dynamic> toJson() => {
        'r': r,
        'c': c,
        'value': value,
        'notes': notes.toList(),
      };

  factory Move.fromJson(Map<String, dynamic> json) => Move(
        json['r'] as int,
        json['c'] as int,
        json['value'] as int,
        Set<int>.from((json['notes'] as List).cast<int>()),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// GameState
// ─────────────────────────────────────────────────────────────────────────────

class GameState extends ChangeNotifier {
  late SudokuGame game;
  late List<List<Set<int>>> notes;
  final List<Move> history = [];

  int _selectedRow = -1;
  int _selectedCol = -1;
  int _activeNumber = 0;
  bool _notesMode = false;

  int _score = 0;
  int _mistakes = 0;
  int _seconds = 0;
  bool _isPaused = false;
  bool _showGameOverDialog = false;
  int _maxMistakes = 3;
  int _continueCount = 0;

  String difficulty = 'Newbie';
  int removeCount = 20;
  bool hasGameInProgress = false;

  String _unlockUntil = '';

  late GameProgress gameProgress;
  GameStats _stats = const GameStats();
  Set<String> _unlockedAchievements = {};

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Achievement notification
  String? _newlyUnlockedAchievementId;

  GameState() {
    game = SudokuGenerator.generate(20);
    notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    gameProgress = GameProgress();
    _initializeAsync();
  }

  // ── Public getters ──────────────────────────────────────────────────────────

  int get selectedRow => _selectedRow;
  int get selectedCol => _selectedCol;
  int get activeNumber => _activeNumber;
  bool get notesMode => _notesMode;
  int get score => _score;
  int get mistakes => _mistakes;
  int get seconds => _seconds;
  bool get isPaused => _isPaused;
  bool get showGameOverDialog => _showGameOverDialog;
  int get maxMistakes => _maxMistakes;
  int get continueCount => _continueCount;

  /// Full stats object — used by StatisticsScreen
  GameStats get stats => _stats;

  /// Set of achievement IDs that have been unlocked — used by StatisticsScreen
  Set<String> get unlockedAchievements =>
      Set.unmodifiable(_unlockedAchievements);

  /// The ID of an achievement unlocked in the last completed game, or null.
  String? get newlyUnlockedAchievementId => _newlyUnlockedAchievementId;

  /// Total losses (convenience getter)
  int get totalLosses => _stats.totalLosses;

  String get formattedTime {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Initialization ──────────────────────────────────────────────────────────

  Future<void> _initializeAsync() async {
    await _loadAll();
    _isInitialized = true;
  }

  Future<void> _loadAll() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadGameProgress();
    await _loadStats();
    await _loadUnlockedAchievements();
    await _loadContinueGame();
    notifyListeners();
  }

  // ── GameProgress persistence ────────────────────────────────────────────────

  Future<void> _loadGameProgress() async {
    final progressJson = _prefs.getString('gameProgress');
    if (progressJson != null) {
      gameProgress = GameProgress.fromJson(jsonDecode(progressJson));
    } else {
      gameProgress = GameProgress();
    }
    _unlockUntil = _prefs.getString('unlockUntil') ?? '';
  }

  Future<void> _saveGameProgress() async {
    await _prefs.setString('gameProgress', jsonEncode(gameProgress.toJson()));
  }

  // ── GameStats persistence ───────────────────────────────────────────────────

  Future<void> _loadStats() async {
    final json = _prefs.getString('gameStats');
    if (json != null) {
      try {
        _stats = GameStats.fromJson(jsonDecode(json));
      } catch (_) {
        _stats = const GameStats();
      }
    }
  }

  Future<void> _saveStats() async {
    await _prefs.setString('gameStats', jsonEncode(_stats.toJson()));
  }

  // ── Achievements persistence ────────────────────────────────────────────────

  Future<void> _loadUnlockedAchievements() async {
    final list = _prefs.getStringList('unlockedAchievements') ?? [];
    _unlockedAchievements = list.toSet();
  }

  Future<void> _saveUnlockedAchievements() async {
    await _prefs.setStringList(
        'unlockedAchievements', _unlockedAchievements.toList());
  }

  /// Unlock an achievement by ID. Returns true if newly unlocked.
  Future<bool> _unlockAchievement(String id) async {
    if (_unlockedAchievements.contains(id)) return false;
    _unlockedAchievements.add(id);
    await _saveUnlockedAchievements();
    return true;
  }

  /// Clear the pending achievement notification after it has been shown.
  void clearNewlyUnlockedAchievement() {
    _newlyUnlockedAchievementId = null;
  }

  // ── Continue game persistence ───────────────────────────────────────────────

  Future<void> _loadContinueGame() async {
    try {
      final continueGameJson = _prefs.getString('continueGame');
      if (continueGameJson != null) {
        final continueData =
            jsonDecode(continueGameJson) as Map<String, dynamic>;

        difficulty = continueData['difficulty'] as String;
        removeCount = continueData['removeCount'] as int;
        _score = continueData['score'] as int;
        _mistakes = continueData['mistakes'] as int;
        _seconds = continueData['seconds'] as int;
        _maxMistakes = continueData['maxMistakes'] as int;
        _continueCount = continueData['continueCount'] as int;
        _notesMode = continueData['notesMode'] as bool;

        final boardJson = continueData['board'] as List;
        final solutionJson = continueData['solution'] as List;
        final fixedJson = continueData['fixed'] as List;
        final notesJson = continueData['notes'] as List;

        game = SudokuGame(
          List<List<int>>.from(
            boardJson.map((row) => List<int>.from((row as List).cast<int>())),
          ),
          List<List<int>>.from(
            solutionJson.map(
              (row) => List<int>.from((row as List).cast<int>()),
            ),
          ),
          List<List<bool>>.from(
            fixedJson.map((row) => List<bool>.from((row as List).cast<bool>())),
          ),
        );

        notes = List<List<Set<int>>>.from(
          notesJson.map(
            (row) => List<Set<int>>.from(
              (row as List).map(
                (cell) => Set<int>.from((cell as List).cast<int>()),
              ),
            ),
          ),
        );

        final historyJson = continueData['history'] as List;
        history.clear();
        history.addAll(
          historyJson.map(
            (move) => Move.fromJson(move as Map<String, dynamic>),
          ),
        );

        hasGameInProgress = true;
      }
    } catch (e) {
      debugPrint('Error loading continue game: $e');
      await _clearContinueGame();
    }
  }

  Future<void> _saveContinueGame() async {
    try {
      final continueData = {
        'difficulty': difficulty,
        'removeCount': removeCount,
        'score': _score,
        'mistakes': _mistakes,
        'seconds': _seconds,
        'maxMistakes': _maxMistakes,
        'continueCount': _continueCount,
        'notesMode': _notesMode,
        'board': game.board,
        'solution': game.solution,
        'fixed': game.fixed,
        'notes': notes
            .map((row) => row.map((cell) => cell.toList()).toList())
            .toList(),
        'history': history.map((move) => move.toJson()).toList(),
      };
      await _prefs.setString('continueGame', jsonEncode(continueData));
    } catch (e) {
      debugPrint('Error saving continue game: $e');
    }
  }

  Future<void> _clearContinueGame() async {
    await _prefs.remove('continueGame');
    hasGameInProgress = false;
  }

  // ── Difficulty locking ──────────────────────────────────────────────────────

  bool _isDailyUnlockActive() {
    if (_unlockUntil.isEmpty) return false;
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final unlockDate = DateTime.tryParse(_unlockUntil);
    final todayDate = DateTime.tryParse(todayString);
    if (unlockDate == null || todayDate == null) return false;
    return todayDate.isBefore(unlockDate) ||
        todayDate.isAtSameMomentAs(unlockDate);
  }

  bool isDifficultyLocked(String difficultyName) {
    if (_isDailyUnlockActive()) return false;
    switch (difficultyName) {
      case 'Newbie':
        return false;
      case 'Easy':
        return gameProgress.newbieGames < 3;
      case 'Regular':
        return gameProgress.easyGames < 7;
      case 'Hard':
        return gameProgress.regularGames < 13;
      case 'Expert':
        return gameProgress.hardGames < 20;
      case 'Professional':
        return gameProgress.expertGames < 25;
      case 'Extreme':
        return gameProgress.professionalGames < 30;
      default:
        return false;
    }
  }

  DifficultyRequirement getDifficultyRequirement(String difficultyName) {
    switch (difficultyName) {
      case 'Easy':
        return DifficultyRequirement(
          name: 'Easy',
          previousDifficulty: 'Newbie',
          requiredGames: 3,
          currentGames: gameProgress.newbieGames,
        );
      case 'Regular':
        return DifficultyRequirement(
          name: 'Regular',
          previousDifficulty: 'Easy',
          requiredGames: 7,
          currentGames: gameProgress.easyGames,
        );
      case 'Hard':
        return DifficultyRequirement(
          name: 'Hard',
          previousDifficulty: 'Regular',
          requiredGames: 13,
          currentGames: gameProgress.regularGames,
        );
      case 'Expert':
        return DifficultyRequirement(
          name: 'Expert',
          previousDifficulty: 'Hard',
          requiredGames: 20,
          currentGames: gameProgress.hardGames,
        );
      case 'Professional':
        return DifficultyRequirement(
          name: 'Professional',
          previousDifficulty: 'Expert',
          requiredGames: 25,
          currentGames: gameProgress.expertGames,
        );
      case 'Extreme':
        return DifficultyRequirement(
          name: 'Extreme',
          previousDifficulty: 'Professional',
          requiredGames: 30,
          currentGames: gameProgress.professionalGames,
        );
      default:
        return DifficultyRequirement(
          name: difficultyName,
          previousDifficulty: '',
          requiredGames: 0,
          currentGames: 0,
        );
    }
  }

  // ── Game init ───────────────────────────────────────────────────────────────

  void initGame(String diff, int removeC, {bool isContinue = false}) {
    if (!isContinue) {
      difficulty = diff;
      removeCount = removeC;
      game = SudokuGenerator.generate(removeCount);
      notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
      history.clear();
      _selectedRow = -1;
      _selectedCol = -1;
      _activeNumber = 0;
      _notesMode = false;
      _score = 0;
      _mistakes = 0;
      _seconds = 0;
      _maxMistakes = 3;
      _showGameOverDialog = false;
      _continueCount = 0;
    }
    _isPaused = false;
    hasGameInProgress = true;
    notifyListeners();
    _saveContinueGame();
  }

  void initDailyChallenge(dynamic customGame, String diff, int removeC) {
    try {
      _resetGameState();
      difficulty = diff;
      removeCount = removeC;

      if (customGame is SudokuGame) {
        game = customGame;
      } else {
        game = customGame != null
            ? (customGame as SudokuGame)
            : SudokuGenerator.generate(60);
      }

      if (game.board.isEmpty || game.board.length != 9) {
        game = SudokuGenerator.generate(60);
      }

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error initializing daily challenge: $e');
      debugPrint('Stack: $stackTrace');
      _resetGameState();
      game = SudokuGenerator.generate(60);
      notifyListeners();
    }
  }

  void _resetGameState() {
    notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    history.clear();
    _selectedRow = -1;
    _selectedCol = -1;
    _activeNumber = 0;
    _notesMode = false;
    _score = 0;
    _mistakes = 0;
    _seconds = 0;
    _maxMistakes = 3;
    _showGameOverDialog = false;
    _continueCount = 0;
    _isPaused = false;
    hasGameInProgress = true;
  }

  // ── Game completion ─────────────────────────────────────────────────────────

  Future<void> completeGame() async {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // ── Update streak ──────────────────────────────────────────────────────
    if (gameProgress.lastPlayedDate.isEmpty) {
      gameProgress.streak = 1;
    } else if (gameProgress.lastPlayedDate == todayString) {
      // already played today — streak unchanged
    } else {
      final lastDate = DateTime.parse(gameProgress.lastPlayedDate);
      final difference = today.difference(lastDate).inDays;
      gameProgress.streak = difference == 1 ? gameProgress.streak + 1 : 1;
    }
    gameProgress.lastPlayedDate = todayString;

    // ── Update best time ───────────────────────────────────────────────────
    if (difficulty != 'Daily Challenge') {
      if (gameProgress.bestTimeSeconds <= 0 ||
          _seconds < gameProgress.bestTimeSeconds) {
        gameProgress.bestTimeSeconds = _seconds;
      }
    }

    // ── Increment difficulty counter ───────────────────────────────────────
    switch (difficulty) {
      case 'Newbie':
        gameProgress.newbieGames++;
        break;
      case 'Easy':
        gameProgress.easyGames++;
        break;
      case 'Regular':
        gameProgress.regularGames++;
        break;
      case 'Hard':
        gameProgress.hardGames++;
        break;
      case 'Expert':
        gameProgress.expertGames++;
        break;
      case 'Professional':
        gameProgress.professionalGames++;
        break;
      case 'Extreme':
        gameProgress.extremeGames++;
        break;
    }

    // ── Update GameStats ───────────────────────────────────────────────────
    final isPerfect = _mistakes == 0;
    final isDaily = difficulty == 'Daily Challenge';

    // Best time per difficulty
    final bestTimes = Map<String, int>.from(_stats.bestTimesByDifficulty);
    if (!isDaily) {
      final prev = bestTimes[difficulty];
      if (prev == null || _seconds < prev) {
        bestTimes[difficulty] = _seconds;
      }
    }

    // Best score per difficulty
    final bestScores = Map<String, int>.from(_stats.bestScoresByDifficulty);
    if (!isDaily) {
      final prev = bestScores[difficulty];
      if (prev == null || _score > prev) {
        bestScores[difficulty] = _score;
      }
    }

    _stats = _stats.copyWith(
      totalGamesPlayed: _stats.totalGamesPlayed + 1,
      totalGamesWon: _stats.totalGamesWon + 1,
      bestStreak: gameProgress.streak > _stats.bestStreak
          ? gameProgress.streak
          : _stats.bestStreak,
      totalTimeSeconds: _stats.totalTimeSeconds + _seconds,
      perfectGames: isPerfect ? _stats.perfectGames + 1 : _stats.perfectGames,
      dailyChallengesCompleted: isDaily
          ? _stats.dailyChallengesCompleted + 1
          : _stats.dailyChallengesCompleted,
      bestTimesByDifficulty: bestTimes,
      bestScoresByDifficulty: bestScores,
    );

    // ── Check achievements ─────────────────────────────────────────────────
    await _checkAndUnlockAchievements();

    await _saveGameProgress();
    await _saveStats();
    await _clearContinueGame();
    notifyListeners();
  }

  /// Called when player loses (too many mistakes, final game over).
  Future<void> recordLoss() async {
    _stats = _stats.copyWith(
      totalGamesPlayed: _stats.totalGamesPlayed + 1,
      totalLosses: _stats.totalLosses + 1,
    );
    await _saveStats();
    await _checkAndUnlockAchievements();
    notifyListeners();
  }

  // ── Achievement checks ──────────────────────────────────────────────────────

  Future<void> _checkAndUnlockAchievements() async {
    // First win
    if (_stats.totalGamesWon == 1) {
      final isNew = await _unlockAchievement('first_win');
      if (isNew) _newlyUnlockedAchievementId = 'first_win';
    }
    // First loss
    if (_stats.totalLosses == 1) {
      final isNew = await _unlockAchievement('first_loss');
      if (isNew) _newlyUnlockedAchievementId = 'first_loss';
    }
    // Perfect game
    if (_stats.perfectGames >= 1) {
      final isNew = await _unlockAchievement('perfect_game');
      if (isNew) _newlyUnlockedAchievementId = 'perfect_game';
    }
    // 10 wins
    if (_stats.totalGamesWon >= 10) {
      final isNew = await _unlockAchievement('ten_wins');
      if (isNew) _newlyUnlockedAchievementId = 'ten_wins';
    }
    // 50 wins
    if (_stats.totalGamesWon >= 50) {
      final isNew = await _unlockAchievement('fifty_wins');
      if (isNew) _newlyUnlockedAchievementId = 'fifty_wins';
    }
    // 3-day streak
    if (gameProgress.streak >= 3) {
      final isNew = await _unlockAchievement('streak_3');
      if (isNew) _newlyUnlockedAchievementId = 'streak_3';
    }
    // 7-day streak
    if (gameProgress.streak >= 7) {
      final isNew = await _unlockAchievement('streak_7');
      if (isNew) _newlyUnlockedAchievementId = 'streak_7';
    }
    // 30-day streak
    if (gameProgress.streak >= 30) {
      final isNew = await _unlockAchievement('streak_30');
      if (isNew) _newlyUnlockedAchievementId = 'streak_30';
    }
    // Daily challenge
    if (_stats.dailyChallengesCompleted >= 1) {
      final isNew = await _unlockAchievement('daily_first');
      if (isNew) _newlyUnlockedAchievementId = 'daily_first';
    }
    // Extreme win
    if (difficulty == 'Extreme') {
      final isNew = await _unlockAchievement('extreme_win');
      if (isNew) _newlyUnlockedAchievementId = 'extreme_win';
    }
    // Speed demon — win in under 3 minutes
    if (_seconds < 180 && _stats.totalGamesWon >= 1) {
      final isNew = await _unlockAchievement('speed_demon');
      if (isNew) _newlyUnlockedAchievementId = 'speed_demon';
    }
    // 5 perfect games
    if (_stats.perfectGames >= 5) {
      final isNew = await _unlockAchievement('five_perfect');
      if (isNew) _newlyUnlockedAchievementId = 'five_perfect';
    }
  }

  // ── Cell selection ──────────────────────────────────────────────────────────

  void selectCell(int r, int c) {
    if (_isPaused || _showGameOverDialog) return;
    if (_selectedRow != r || _selectedCol != c) {
      _selectedRow = r;
      _selectedCol = c;
      _activeNumber = game.board[r][c];
      notifyListeners();
    }
  }

  // ── Number input ────────────────────────────────────────────────────────────

  void inputNumber(int n) {
    if (_selectedRow == -1 ||
        game.fixed[_selectedRow][_selectedCol] ||
        _isPaused ||
        _showGameOverDialog) {
      return;
    }

    _activeNumber = n;
    history.add(
      Move(_selectedRow, _selectedCol, game.board[_selectedRow][_selectedCol],
          {...notes[_selectedRow][_selectedCol]}),
    );

    if (_notesMode) {
      notes[_selectedRow][_selectedCol].contains(n)
          ? notes[_selectedRow][_selectedCol].remove(n)
          : notes[_selectedRow][_selectedCol].add(n);
    } else {
      game.board[_selectedRow][_selectedCol] = n;
      notes[_selectedRow][_selectedCol].clear();

      if (game.solution[_selectedRow][_selectedCol] == n) {
        _score += 10;
        _clearNotesForPlacedNumber(_selectedRow, _selectedCol, n);
      } else {
        _mistakes++;
        _score = (_score - 5).clamp(0, 9999);
      }

      if (isBoardComplete()) _showGameOverDialog = true;
      if (_mistakes >= _maxMistakes) _showGameOverDialog = true;
    }
    notifyListeners();
    _saveContinueGame();
  }

  /// Auto-clear candidate notes when a number is correctly placed.
  void _clearNotesForPlacedNumber(int row, int col, int n) {
    for (int i = 0; i < 9; i++) {
      notes[row][i].remove(n);
      notes[i][col].remove(n);
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        notes[r][c].remove(n);
      }
    }
  }

  void erase() {
    if (_selectedRow == -1 ||
        game.fixed[_selectedRow][_selectedCol] ||
        _isPaused ||
        _showGameOverDialog) return;

    history.add(Move(
        _selectedRow,
        _selectedCol,
        game.board[_selectedRow][_selectedCol],
        {...notes[_selectedRow][_selectedCol]}));

    game.board[_selectedRow][_selectedCol] = 0;
    notes[_selectedRow][_selectedCol].clear();
    _activeNumber = 0;
    notifyListeners();
    _saveContinueGame();
  }

  void undo() {
    if (history.isEmpty || _isPaused || _showGameOverDialog) return;
    final m = history.removeLast();
    game.board[m.r][m.c] = m.value;
    notes[m.r][m.c] = {...m.notes};
    _activeNumber = m.value;
    notifyListeners();
    _saveContinueGame();
  }

  void hint() {
    if (_selectedRow == -1 ||
        game.fixed[_selectedRow][_selectedCol] ||
        _isPaused ||
        _showGameOverDialog) return;

    history.add(Move(
        _selectedRow,
        _selectedCol,
        game.board[_selectedRow][_selectedCol],
        {...notes[_selectedRow][_selectedCol]}));

    final correctVal = game.solution[_selectedRow][_selectedCol];
    game.board[_selectedRow][_selectedCol] = correctVal;
    notes[_selectedRow][_selectedCol].clear();
    _clearNotesForPlacedNumber(_selectedRow, _selectedCol, correctVal);
    _score = (_score - 15).clamp(0, 9999);
    _activeNumber = correctVal;
    notifyListeners();
    _saveContinueGame();
  }

  void toggleNotesMode() {
    if (_isPaused || _showGameOverDialog) return;
    _notesMode = !_notesMode;
    notifyListeners();
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void incrementSeconds() {
    if (!_isPaused && !_showGameOverDialog) {
      _seconds++;
      notifyListeners();
      if (_seconds % 5 == 0) _saveContinueGame();
    }
  }

  void addExtraChance() {
    if (!canContinue()) return;
    _continueCount++;
    _maxMistakes++;
    _showGameOverDialog = false;
    _mistakes = 0;
    notifyListeners();
    _saveContinueGame();
  }

  bool canContinue() => _continueCount < 7;

  bool isNumberCompleted(int n) {
    int count = 0;
    for (var r in game.board) {
      for (var v in r) {
        if (v == n) count++;
      }
    }
    return count >= 9;
  }

  bool isBoardComplete() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (game.board[r][c] != game.solution[r][c]) return false;
      }
    }
    return true;
  }

  bool checkGameOver() => _mistakes >= _maxMistakes || isBoardComplete();

  Future<void> unlockAllForDay() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowString =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    _unlockUntil = tomorrowString;
    await _prefs.setString('unlockUntil', tomorrowString);
    notifyListeners();
  }

  String getUnlockExpiryTime() {
    if (_unlockUntil.isEmpty) return '';
    try {
      final unlockDate = DateTime.parse(_unlockUntil);
      final difference = unlockDate.difference(DateTime.now());
      if (difference.isNegative) return '';
      final h = difference.inHours;
      final m = difference.inMinutes % 60;
      return h > 0 ? '$h h $m m left' : '$m m left';
    } catch (_) {
      return '';
    }
  }

  void markGameOverShown() {
    _showGameOverDialog = true;
  }

  void clearGameProgress() {
    hasGameInProgress = false;
    _showGameOverDialog = false;
    _isPaused = false;
    _clearContinueGame();
    notifyListeners();
  }

  void resetGameOverDialog() {
    _showGameOverDialog = false;
    notifyListeners();
  }
}
