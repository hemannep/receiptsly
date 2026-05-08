class GameProgress {
  int newbieGames = 0;
  int easyGames = 0;
  int regularGames = 0;
  int hardGames = 0;
  int expertGames = 0;
  int professionalGames = 0;
  int extremeGames = 0;
  int streak = 0;
  String lastPlayedDate = '';
  int bestTimeSeconds = 0; // 0 means no best time recorded yet

  GameProgress({
    this.newbieGames = 0,
    this.easyGames = 0,
    this.regularGames = 0,
    this.hardGames = 0,
    this.expertGames = 0,
    this.professionalGames = 0,
    this.extremeGames = 0,
    this.streak = 0,
    this.lastPlayedDate = '',
    this.bestTimeSeconds = 0,
  });

  /// Returns formatted best time as MM:SS or empty if never recorded
  String get bestTimeFormatted {
    if (bestTimeSeconds <= 0) return '';
    final m = bestTimeSeconds ~/ 60;
    final s = bestTimeSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'newbieGames': newbieGames,
      'easyGames': easyGames,
      'regularGames': regularGames,
      'hardGames': hardGames,
      'expertGames': expertGames,
      'professionalGames': professionalGames,
      'extremeGames': extremeGames,
      'streak': streak,
      'lastPlayedDate': lastPlayedDate,
      'bestTimeSeconds': bestTimeSeconds,
    };
  }

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    return GameProgress(
      newbieGames: json['newbieGames'] ?? 0,
      easyGames: json['easyGames'] ?? 0,
      regularGames: json['regularGames'] ?? 0,
      hardGames: json['hardGames'] ?? 0,
      expertGames: json['expertGames'] ?? 0,
      professionalGames: json['professionalGames'] ?? 0,
      extremeGames: json['extremeGames'] ?? 0,
      streak: json['streak'] ?? 0,
      lastPlayedDate: json['lastPlayedDate'] ?? '',
      bestTimeSeconds: json['bestTimeSeconds'] ?? 0,
    );
  }
}

class DifficultyRequirement {
  final String name;
  final String previousDifficulty;
  final int requiredGames;
  final int currentGames;

  DifficultyRequirement({
    required this.name,
    required this.previousDifficulty,
    required this.requiredGames,
    required this.currentGames,
  });

  bool get isUnlocked => currentGames >= requiredGames;
  int get remainingGames =>
      (requiredGames - currentGames).clamp(0, requiredGames);
}
