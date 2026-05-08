import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Ads/interstitial_ads.dart';
import '../../utils/app_theme.dart';
import '../Game Screen/game_screen.dart';
import '../../utils/game_state.dart';
import '../Settings Screen/app_settings.dart';

class DifficultyCard extends StatelessWidget {
  final Map<String, dynamic> difficulty;
  final VoidCallback onLockedTap;

  const DifficultyCard({
    required this.difficulty,
    required this.onLockedTap,
    super.key,
  });

  Future<void> _handleDifficultyTap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    int playCount = prefs.getInt('global_play_count') ?? 0;
    playCount++;
    await prefs.setInt('global_play_count', playCount);

    if (playCount % 2 == 0) {
      await InterstitialAdHelper.showInterstitialAd();
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            difficulty: difficulty['name'] as String,
            removeCount: difficulty['remove'] as int,
            isContinue: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppSettings>().isDarkMode;

    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final color = difficulty['color'] as Color;
        final emoji = difficulty['emoji'] as String;
        final diffName = difficulty['name'] as String;
        final isLocked = gameState.isDifficultyLocked(diffName);
        final requirement = gameState.getDifficultyRequirement(diffName);

        // Background
        final cardBg = isDark
            ? (isLocked
                ? AppTheme.darkSurface.withValues(alpha: 0.5)
                : AppTheme.darkSurface)
            : (isLocked ? Colors.grey.shade50 : Colors.white);

        // Title
        final titleColor = isLocked
            ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
            : (isDark ? AppTheme.darkTextPrimary : Colors.black87);

        // Description
        final descColor =
            isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600;

        // Progress bg
        final progressBg =
            isDark ? const Color(0xFF333333) : Colors.grey.shade200;

        return GestureDetector(
          onTap: isLocked ? onLockedTap : () => _handleDifficultyTap(context),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border(
                left: BorderSide(
                  color: isLocked
                      ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                      : color,
                  width: 5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(
                      alpha: isLocked ? 0.03 : (isDark ? 0.2 : 0.12)),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            difficulty['name'] as String,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (isLocked)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.lock_rounded,
                                size: 16,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (diffName == 'Newbie')
                        Text(
                          difficulty['desc'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: descColor,
                            letterSpacing: 0.1,
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete ${requirement.requiredGames} ${requirement.previousDifficulty} games',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLocked
                                    ? (isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400)
                                    : color,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (requirement.currentGames /
                                    requirement.requiredGames),
                                minHeight: 6,
                                backgroundColor: progressBg,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${requirement.currentGames}/${requirement.requiredGames}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: descColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: isLocked ? 0.35 : 1.0,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (!isLocked)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: color,
                        size: 18,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF333333)
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                          size: 14,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
