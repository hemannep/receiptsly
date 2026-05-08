import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Ads/interstitial_ads.dart';

import '../../utils/app_theme.dart';
import '../../utils/game_state.dart';
import '../Difficulty Screen/difficulty_screen.dart';
import '../Settings Screen/app_settings.dart';
import '../Settings Screen/settings_screen.dart';
import '../Statistics Screen/statistics_screen.dart';
import '../daily_challenge_screen.dart';
import '../tipsscreen.dart';
import 'streak_counter.dart';
import 'continue_control.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _HomeContent(),
    DailyChallengeScreen(),
    StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppSettings>().isDarkMode;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        isDark: isDark,
        onTap: (i) {
          AppSettings().selectionHaptic();
          setState(() => _selectedIndex = i);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Daily'),
    (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Stats'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(_items.length, (i) {
              final (activeIcon, inactiveIcon, label) = _items[i];
              final isSelected = i == selectedIndex;
              final color = isSelected
                  ? Colors.green.shade500
                  : (isDark ? Colors.grey.shade500 : Colors.grey.shade400);

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Active indicator pill
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          height: 3,
                          width: isSelected ? 28 : 0,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Icon(
                          isSelected ? activeIcon : inactiveIcon,
                          size: 25,
                          color: color,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home content
// ─────────────────────────────────────────────────────────────────────────────

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  Future<void> _handleNewGameClick() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('first_new_game') ?? true;

    if (isFirstTime) {
      await prefs.setBool('first_new_game', false);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DifficultyScreen()),
        );
      }
    } else {
      int playCount = prefs.getInt('global_play_count') ?? 0;
      playCount++;
      await prefs.setInt('global_play_count', playCount);
      if (playCount % 2 == 0) {
        await InterstitialAdHelper.showInterstitialAd();
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DifficultyScreen()),
        );
      }
    }
  }

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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              _Header(
                isDark: isDark,
                textSecondary: textSecondary,
                cardBg: cardBg,
              ),
              const SizedBox(height: 20),

              // ── Quick Stats Strip ───────────────────────────────────────
              _QuickStatsStrip(
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // ── New Game CTA ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _NewGameButton(
                  isDark: isDark,
                  onTap: _handleNewGameClick,
                ),
              ),
              const SizedBox(height: 14),

              // ── Quick action row: Tips + Settings ───────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.lightbulb_rounded,
                        label: 'Tips & Tricks',
                        subtitle: '20+ strategies',
                        color: Colors.orange,
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TipsScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        subtitle: 'Theme & sound',
                        color: Colors.blue,
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Continue Game ───────────────────────────────────────────
              const ContinueControl(),
              const SizedBox(height: 20),

              // ── Difficulty Preview ──────────────────────────────────────
              _DifficultyPreview(
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
                cardBg: cardBg,
                onTap: _handleNewGameClick,
              ),
              const SizedBox(height: 20),

              // ── Feature cards ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _FeatureSection(
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 20),

              // ── How to Play ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _HowToPlay(
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                  onMoreTips: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TipsScreen()),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  '© 2026 Sudoku Game App. All rights reserved. Mango Juice',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isDark;
  final Color textSecondary;
  final Color cardBg;

  const _Header({
    required this.isDark,
    required this.textSecondary,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDark
                      ? [Colors.green.shade300, Colors.green.shade500]
                      : [Colors.green.shade500, Colors.green.shade700],
                ).createShader(bounds),
                child: const Text(
                  'Sudoku',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep your mind sharp',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          // Streak + settings
          // Row(
          //   children: [
          //     const StreakCounter(),
          //     const SizedBox(width: 10),
          //     GestureDetector(
          //         // onTap: () {
          //         //   AppSettings().lightHaptic();
          //         //   Navigator.push(
          //         //     context,
          //         //     MaterialPageRoute(builder: (_) => const SettingsScreen()),
          //         //   );
          //         // },
          //         // child: Container(
          //         //   width: 44,
          //         //   height: 44,
          //         //   decoration: BoxDecoration(
          //         //     color: cardBg,
          //         //     shape: BoxShape.circle,
          //         //     boxShadow: [
          //         //       BoxShadow(
          //         //         color:
          //         //             Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
          //         //         blurRadius: 10,
          //         //         offset: const Offset(0, 3),
          //         //       ),
          //         //     ],
          //         //   ),
          //         //   // child: Icon(
          //         //   //   Icons.settings_rounded,
          //         //   //   color: Colors.green.shade400,
          //         //   //   size: 20,
          //         //   // ),
          //         // ),
          //         ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick stats strip — reads from GameState
// ─────────────────────────────────────────────────────────────────────────────

class _QuickStatsStrip extends StatelessWidget {
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _QuickStatsStrip({
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final prog = gameState.gameProgress;
        final stats = gameState.stats;

        final total = prog.newbieGames +
            prog.easyGames +
            prog.regularGames +
            prog.hardGames +
            prog.expertGames +
            prog.professionalGames +
            prog.extremeGames;

        final bestTime =
            prog.bestTimeFormatted.isEmpty ? '--:--' : prog.bestTimeFormatted;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _StatChip(
                  emoji: '🎮',
                  value: '$total',
                  label: 'Played',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _VertDivider(isDark: isDark),
                _StatChip(
                  emoji: '🏆',
                  value: '${stats.totalGamesWon}',
                  label: 'Won',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _VertDivider(isDark: isDark),
                _StatChip(
                  emoji: '🔥',
                  value: '${prog.streak}',
                  label: 'Streak',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _VertDivider(isDark: isDark),
                _StatChip(
                  emoji: '⏱️',
                  value: bestTime,
                  label: 'Best',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color textPrimary;
  final Color textSecondary;

  const _StatChip({
    required this.emoji,
    required this.value,
    required this.label,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  final bool isDark;
  const _VertDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.shade200,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// New Game button
// ─────────────────────────────────────────────────────────────────────────────

class _NewGameButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _NewGameButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: isDark ? 0.4 : 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Game',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select difficulty & start',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick action cards row (Tips + Settings)
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Difficulty preview strip
// ─────────────────────────────────────────────────────────────────────────────

class _DifficultyPreview extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final Color cardBg;
  final VoidCallback onTap;

  const _DifficultyPreview({
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.cardBg,
    required this.onTap,
  });

  static const _levels = [
    ('🎮', 'Newbie', Colors.blue),
    ('😊', 'Easy', Colors.green),
    ('🎯', 'Regular', Colors.orange),
    ('💪', 'Hard', Colors.red),
    ('🧠', 'Expert', Colors.purple),
    ('👑', 'Pro', Colors.amber),
    ('⚡', 'Extreme', Colors.deepOrange),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7 Difficulty Levels',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  'Play now →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _levels.length,
            itemBuilder: (context, i) {
              final (emoji, name, color) = _levels[i];
              return GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      bottom: BorderSide(
                        color: color as Color,
                        width: 3,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (color as Color)
                            .withValues(alpha: isDark ? 0.2 : 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature cards 2×2 grid
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureSection extends StatelessWidget {
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _FeatureSection({
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: '🏆',
                title: 'Achievements',
                desc: 'Unlock badges',
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureCard(
                icon: '📊',
                title: 'Statistics',
                desc: 'Track progress',
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
              child: _FeatureCard(
                icon: '🔓',
                title: 'Progressive',
                desc: 'Unlock levels',
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureCard(
                icon: '🌍',
                title: 'Daily Global',
                desc: 'Same puzzle worldwide',
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// How to Play
// ─────────────────────────────────────────────────────────────────────────────

class _HowToPlay extends StatelessWidget {
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onMoreTips;

  const _HowToPlay({
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onMoreTips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'How to Play',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: onMoreTips,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade500
                        .withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'More tips →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RuleItem(
            number: '1',
            text: 'Fill each row with digits 1–9',
            color: Colors.blue,
            textPrimary: textPrimary,
          ),
          const SizedBox(height: 12),
          _RuleItem(
            number: '2',
            text: 'Fill each column with digits 1–9',
            color: Colors.green,
            textPrimary: textPrimary,
          ),
          const SizedBox(height: 12),
          _RuleItem(
            number: '3',
            text: 'Fill each 3×3 box with digits 1–9',
            color: Colors.purple,
            textPrimary: textPrimary,
          ),
          const SizedBox(height: 16),
          // Pro tip banner
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color:
                  Colors.green.shade500.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    Colors.green.shade500.withValues(alpha: isDark ? 0.3 : 0.2),
              ),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use Notes mode to pencil in candidates — tap the ✏️ button during a game.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.green.shade300
                          : Colors.green.shade800,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String number;
  final String text;
  final Color color;
  final Color textPrimary;

  const _RuleItem({
    required this.number,
    required this.text,
    required this.color,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
