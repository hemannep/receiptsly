import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool Function(GameStats stats) isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });
}

class GameStats {
  int totalGamesPlayed;
  int totalGamesWon;
  int totalMistakes;
  int totalHintsUsed;
  int totalTimeSeconds;
  int bestStreak;
  int currentStreak;
  int dailyChallengesCompleted;
  int perfectGames; // games won with 0 mistakes
  int speedRunsUnder5Min;
  Map<String, int> winsByDifficulty;
  Map<String, int> bestTimesByDifficulty;
  Map<String, int> bestScoresByDifficulty;

  GameStats({
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.totalMistakes = 0,
    this.totalHintsUsed = 0,
    this.totalTimeSeconds = 0,
    this.bestStreak = 0,
    this.currentStreak = 0,
    this.dailyChallengesCompleted = 0,
    this.perfectGames = 0,
    this.speedRunsUnder5Min = 0,
    Map<String, int>? winsByDifficulty,
    Map<String, int>? bestTimesByDifficulty,
    Map<String, int>? bestScoresByDifficulty,
  })  : winsByDifficulty = winsByDifficulty ?? {},
        bestTimesByDifficulty = bestTimesByDifficulty ?? {},
        bestScoresByDifficulty = bestScoresByDifficulty ?? {};

  double get winRate {
    if (totalGamesPlayed == 0) return 0.0;
    return (totalGamesWon / totalGamesPlayed) * 100;
  }

  String get formattedTotalTime {
    final hours = totalTimeSeconds ~/ 3600;
    final minutes = (totalTimeSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Map<String, dynamic> toJson() => {
        'totalGamesPlayed': totalGamesPlayed,
        'totalGamesWon': totalGamesWon,
        'totalMistakes': totalMistakes,
        'totalHintsUsed': totalHintsUsed,
        'totalTimeSeconds': totalTimeSeconds,
        'bestStreak': bestStreak,
        'currentStreak': currentStreak,
        'dailyChallengesCompleted': dailyChallengesCompleted,
        'perfectGames': perfectGames,
        'speedRunsUnder5Min': speedRunsUnder5Min,
        'winsByDifficulty': winsByDifficulty,
        'bestTimesByDifficulty': bestTimesByDifficulty,
        'bestScoresByDifficulty': bestScoresByDifficulty,
      };

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalGamesWon: json['totalGamesWon'] ?? 0,
      totalMistakes: json['totalMistakes'] ?? 0,
      totalHintsUsed: json['totalHintsUsed'] ?? 0,
      totalTimeSeconds: json['totalTimeSeconds'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      dailyChallengesCompleted: json['dailyChallengesCompleted'] ?? 0,
      perfectGames: json['perfectGames'] ?? 0,
      speedRunsUnder5Min: json['speedRunsUnder5Min'] ?? 0,
      winsByDifficulty: Map<String, int>.from(json['winsByDifficulty'] ?? {}),
      bestTimesByDifficulty:
          Map<String, int>.from(json['bestTimesByDifficulty'] ?? {}),
      bestScoresByDifficulty:
          Map<String, int>.from(json['bestScoresByDifficulty'] ?? {}),
    );
  }
}

class AchievementsList {
  static List<Achievement> get all => [
        Achievement(
          id: 'first_win',
          title: 'First Victory',
          description: 'Win your first game',
          icon: Icons.emoji_events_rounded,
          color: Colors.amber,
          isUnlocked: (s) => s.totalGamesWon >= 1,
        ),
        Achievement(
          id: 'perfectionist',
          title: 'Perfectionist',
          description: 'Win a game without any mistakes',
          icon: Icons.verified_rounded,
          color: Colors.green,
          isUnlocked: (s) => s.perfectGames >= 1,
        ),
        Achievement(
          id: 'speed_demon',
          title: 'Speed Demon',
          description: 'Complete a puzzle in under 5 minutes',
          icon: Icons.bolt_rounded,
          color: Colors.orange,
          isUnlocked: (s) => s.speedRunsUnder5Min >= 1,
        ),
        Achievement(
          id: 'streak_3',
          title: 'On Fire',
          description: 'Get a 3-day streak',
          icon: Icons.local_fire_department_rounded,
          color: Colors.deepOrange,
          isUnlocked: (s) => s.bestStreak >= 3,
        ),
        Achievement(
          id: 'streak_7',
          title: 'Week Warrior',
          description: 'Get a 7-day streak',
          icon: Icons.whatshot_rounded,
          color: Colors.red,
          isUnlocked: (s) => s.bestStreak >= 7,
        ),
        Achievement(
          id: 'streak_30',
          title: 'Dedicated Master',
          description: 'Get a 30-day streak',
          icon: Icons.workspace_premium_rounded,
          color: Colors.purple,
          isUnlocked: (s) => s.bestStreak >= 30,
        ),
        Achievement(
          id: 'games_10',
          title: 'Getting Started',
          description: 'Play 10 games',
          icon: Icons.play_circle_rounded,
          color: Colors.blue,
          isUnlocked: (s) => s.totalGamesPlayed >= 10,
        ),
        Achievement(
          id: 'games_50',
          title: 'Sudoku Enthusiast',
          description: 'Play 50 games',
          icon: Icons.star_rounded,
          color: Colors.indigo,
          isUnlocked: (s) => s.totalGamesPlayed >= 50,
        ),
        Achievement(
          id: 'games_100',
          title: 'Centurion',
          description: 'Play 100 games',
          icon: Icons.military_tech_rounded,
          color: Colors.teal,
          isUnlocked: (s) => s.totalGamesPlayed >= 100,
        ),
        Achievement(
          id: 'no_hints',
          title: 'Independent Thinker',
          description: 'Win 5 games without using hints',
          icon: Icons.psychology_rounded,
          color: Colors.pink,
          isUnlocked: (s) => s.totalGamesWon >= 5 && s.totalHintsUsed == 0,
        ),
        Achievement(
          id: 'hard_master',
          title: 'Hard Mode Master',
          description: 'Win 10 Hard games',
          icon: Icons.fitness_center_rounded,
          color: Colors.red,
          isUnlocked: (s) => (s.winsByDifficulty['Hard'] ?? 0) >= 10,
        ),
        Achievement(
          id: 'extreme_master',
          title: 'Extreme Champion',
          description: 'Win an Extreme difficulty game',
          icon: Icons.bolt_rounded,
          color: Colors.deepOrange,
          isUnlocked: (s) => (s.winsByDifficulty['Extreme'] ?? 0) >= 1,
        ),
        Achievement(
          id: 'daily_warrior',
          title: 'Daily Warrior',
          description: 'Complete 7 Daily Challenges',
          icon: Icons.calendar_today_rounded,
          color: Colors.cyan,
          isUnlocked: (s) => s.dailyChallengesCompleted >= 7,
        ),
        Achievement(
          id: 'daily_legend',
          title: 'Daily Legend',
          description: 'Complete 30 Daily Challenges',
          icon: Icons.event_available_rounded,
          color: Colors.deepPurple,
          isUnlocked: (s) => s.dailyChallengesCompleted >= 30,
        ),
      ];
}
