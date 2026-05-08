import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sudokugame/utils/achievements.dart';

import '../../utils/app_theme.dart';
import '../../utils/game_state.dart';
import '../Settings Screen/app_settings.dart';
import '../Settings Screen/settings_screen.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppSettings>().isDarkMode;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : Colors.grey.shade900;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Consumer<GameState>(
          builder: (context, gameState, _) {
            final stats = gameState.stats;
            final unlocked = gameState.unlockedAchievements;
            final prog = gameState.gameProgress;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: isDark
                                    ? [
                                        Colors.green.shade300,
                                        Colors.green.shade500,
                                      ]
                                    : [
                                        Colors.green.shade500,
                                        Colors.green.shade700,
                                      ],
                              ).createShader(bounds),
                              child: const Text(
                                "Statistics",
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Your sudoku journey",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Settings button
                      GestureDetector(
                        onTap: () {
                          AppSettings().lightHaptic();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.4 : 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            color: Colors.green.shade400,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Hero card ─────────────────────────────────────────
                  _HeroCard(stats: stats, isDark: isDark),
                  const SizedBox(height: 16),

                  // ── 4 stat cards in 2×2 grid ──────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Best Streak',
                          value: '${stats.bestStreak}',
                          subtitle: 'days',
                          color: Colors.orange,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.schedule_rounded,
                          label: 'Total Time',
                          value: stats.formattedTotalTime,
                          subtitle: 'played',
                          color: Colors.blue,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.workspace_premium_rounded,
                          label: 'Perfect Games',
                          value: '${stats.perfectGames}',
                          subtitle: 'no errors',
                          color: Colors.amber,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.calendar_today_rounded,
                          label: 'Daily Wins',
                          value: '${stats.dailyChallengesCompleted}',
                          subtitle: 'challenges',
                          color: Colors.purple,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── NEW: Games by Difficulty ───────────────────────────
                  _SectionTitle(
                    title: 'Games by Difficulty',
                    icon: Icons.bar_chart_rounded,
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _GamesByDifficultyCard(
                    prog: prog,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 28),

                  // ── NEW: Unlock Progression ───────────────────────────
                  _SectionTitle(
                    title: 'Unlock Progression',
                    icon: Icons.lock_open_rounded,
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _UnlockProgressionCard(
                    prog: prog,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 28),

                  // ── Best by Difficulty ────────────────────────────────
                  if (stats.bestTimesByDifficulty.isNotEmpty ||
                      stats.bestScoresByDifficulty.isNotEmpty)
                    _SectionTitle(
                      title: 'Best by Difficulty',
                      icon: Icons.emoji_events_rounded,
                      textPrimary: textPrimary,
                    ),
                  if (stats.bestTimesByDifficulty.isNotEmpty ||
                      stats.bestScoresByDifficulty.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _BestByDifficultyCard(
                      stats: stats,
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Achievements ──────────────────────────────────────
                  _SectionTitle(
                    title: 'Achievements',
                    icon: Icons.military_tech_rounded,
                    textPrimary: textPrimary,
                    trailing:
                        '${unlocked.length}/${AchievementsList.all.length}',
                    trailingColor: Colors.green.shade400,
                  ),
                  const SizedBox(height: 12),
                  _AchievementsGrid(
                    unlocked: unlocked,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW: Games by Difficulty — horizontal bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _GamesByDifficultyCard extends StatelessWidget {
  final dynamic prog;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _GamesByDifficultyCard({
    required this.prog,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  static const _difficulties = [
    ('Newbie', Colors.blue, '🎮'),
    ('Easy', Colors.green, '😊'),
    ('Regular', Colors.orange, '🎯'),
    ('Hard', Colors.red, '💪'),
    ('Expert', Colors.purple, '🧠'),
    ('Professional', Colors.amber, '👑'),
    ('Extreme', Colors.deepOrange, '⚡'),
  ];

  int _countFor(String name) {
    switch (name) {
      case 'Newbie':
        return (prog.newbieGames as int?) ?? 0;
      case 'Easy':
        return (prog.easyGames as int?) ?? 0;
      case 'Regular':
        return (prog.regularGames as int?) ?? 0;
      case 'Hard':
        return (prog.hardGames as int?) ?? 0;
      case 'Expert':
        return (prog.expertGames as int?) ?? 0;
      case 'Professional':
        return (prog.professionalGames as int?) ?? 0;
      case 'Extreme':
        return (prog.extremeGames as int?) ?? 0;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = _difficulties.map((d) => _countFor(d.$1)).toList();
    final maxCount = counts.fold(0, (a, b) => a > b ? a : b);
    final total = counts.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total completed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade400.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$total games',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.green.shade400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._difficulties.asMap().entries.map((entry) {
            final i = entry.key;
            final (name, color, emoji) = entry.value;
            final count = counts[i];
            final fraction =
                maxCount == 0 ? 0.0 : (count / maxCount).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 112,
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.shade100,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color as Color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: count > 0 ? (color as Color) : textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW: Unlock Progression
// ─────────────────────────────────────────────────────────────────────────────

class _UnlockProgressionCard extends StatelessWidget {
  final dynamic prog;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _UnlockProgressionCard({
    required this.prog,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      _UnlockRowData('Easy', '😊', Colors.green,
          (prog.newbieGames as int?) ?? 0, 3, false),
      _UnlockRowData('Regular', '🎯', Colors.orange,
          (prog.easyGames as int?) ?? 0, 7, false),
      _UnlockRowData('Hard', '💪', Colors.red, (prog.regularGames as int?) ?? 0,
          13, false),
      _UnlockRowData('Expert', '🧠', Colors.purple,
          (prog.hardGames as int?) ?? 0, 20, false),
      _UnlockRowData('Professional', '👑', Colors.amber,
          (prog.expertGames as int?) ?? 0, 25, false),
      _UnlockRowData('Extreme', '⚡', Colors.deepOrange,
          (prog.professionalGames as int?) ?? 0, 30, true),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: rows.map((r) {
          final isUnlocked = r.current >= r.required;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Text(r.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                r.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isUnlocked ? textPrimary : textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${r.current.clamp(0, r.required)}/${r.required}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isUnlocked ? r.color : textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
                                    isUnlocked
                                        ? Icons.lock_open_rounded
                                        : Icons.lock_rounded,
                                    size: 13,
                                    color: isUnlocked
                                        ? r.color
                                        : textSecondary.withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (r.current / r.required).clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isUnlocked ? r.color : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!r.isLast)
                Divider(
                  color: isDark ? AppTheme.darkDivider : Colors.grey.shade100,
                  height: 1,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _UnlockRowData {
  final String label;
  final String emoji;
  final Color color;
  final int current;
  final int required;
  final bool isLast;

  const _UnlockRowData(this.label, this.emoji, this.color, this.current,
      this.required, this.isLast);
}

// ─────────────────────────────────────────────────────────────────────────────
// Existing widgets — unchanged from your original file
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final dynamic stats;
  final bool isDark;

  const _HeroCard({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: isDark ? 0.4 : 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeroStat(
                value: '${stats.totalGamesWon}',
                label: 'Games Won',
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _HeroStat(
                value: '${stats.totalGamesPlayed}',
                label: 'Games Played',
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _HeroStat(
                value: '${stats.winRate.toStringAsFixed(0)}%',
                label: 'Win Rate',
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (stats.winRate / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color textPrimary;
  final String? trailing;
  final Color? trailingColor;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.textPrimary,
    this.trailing,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade400, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (trailingColor ?? Colors.green).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trailing!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: trailingColor ?? Colors.green,
              ),
            ),
          ),
      ],
    );
  }
}

class _BestByDifficultyCard extends StatelessWidget {
  final dynamic stats;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _BestByDifficultyCard({
    required this.stats,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  static const _diffOrder = [
    'Newbie',
    'Easy',
    'Regular',
    'Hard',
    'Expert',
    'Professional',
    'Extreme',
  ];

  static const _diffColors = {
    'Newbie': Colors.blue,
    'Easy': Colors.green,
    'Regular': Colors.orange,
    'Hard': Colors.red,
    'Expert': Colors.purple,
    'Professional': Colors.amber,
    'Extreme': Colors.deepOrange,
  };

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final entries = _diffOrder.where((d) {
      return (stats.bestTimesByDifficulty[d] != null) ||
          (stats.bestScoresByDifficulty[d] != null);
    }).toList();

    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No records yet. Win a game to set your first record!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'DIFFICULTY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'BEST TIME',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'HIGH SCORE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...entries.asMap().entries.map((e) {
            final idx = e.key;
            final diff = e.value;
            final color = _diffColors[diff]!;
            final bestTime = stats.bestTimesByDifficulty[diff] as int?;
            final bestScore = stats.bestScoresByDifficulty[diff] as int?;
            final isLast = idx == entries.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: isDark
                              ? AppTheme.darkDivider
                              : Colors.grey.shade100,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          diff,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      bestTime != null ? _formatTime(bestTime) : '—',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: bestTime != null ? textPrimary : textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      bestScore != null ? '$bestScore' : '—',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: bestScore != null
                            ? Colors.green.shade400
                            : textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  final Set<String> unlocked;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _AchievementsGrid({
    required this.unlocked,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final achievements = AchievementsList.all;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final ach = achievements[index];
        final isUnlocked = unlocked.contains(ach.id);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: isUnlocked
                ? Border.all(color: Colors.green.shade400, width: 2)
                : Border.all(
                    color: isDark ? AppTheme.darkDivider : Colors.grey.shade200,
                    width: 1,
                  ),
            boxShadow: [
              BoxShadow(
                color: isUnlocked
                    ? Colors.green.withValues(alpha: isDark ? 0.25 : 0.15)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: isUnlocked ? 1.0 : 0.3,
                child: Icon(
                  ach.icon,
                  size: 36,
                  color: isUnlocked ? ach.color : textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ach.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isUnlocked
                      ? textPrimary
                      : textSecondary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ach.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                  height: 1.3,
                ),
              ),
              if (isUnlocked) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '✓ UNLOCKED',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
