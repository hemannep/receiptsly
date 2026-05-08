import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/game_progress.dart';
import '../../Ads/rewared_ads.dart';
import '../../utils/game_state.dart';
import '../Settings Screen/app_settings.dart';

class DifficultyDialogs {
  static void showUnlockAllDialog(BuildContext context) {
    final isDark = context.read<AppSettings>().isDarkMode;
    final bg = isDark ? AppTheme.darkSurface : Colors.white;
    final titleColor = isDark ? AppTheme.darkTextPrimary : Colors.black87;
    final descColor =
        isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600;
    final cancelBg = isDark ? const Color(0xFF333333) : Colors.grey.shade100;
    final cancelText =
        isDark ? AppTheme.darkTextSecondary : Colors.grey.shade700;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        backgroundColor: bg,
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.green.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_open_rounded,
                  color: Colors.green.shade400,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Unlock All For A Day?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'All 7 difficulty levels will be unlocked for 24 hours',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: descColor,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cancelBg,
                        foregroundColor: cancelText,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (RewardedAdHelper.isRewardedAdReady()) {
                          bool adShown = await RewardedAdHelper.showRewardedAd(
                            onRewardEarned: () async {
                              final gameState = Provider.of<GameState>(
                                context,
                                listen: false,
                              );
                              await gameState.unlockAllForDay();
                            },
                          );
                          if (adShown && dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } else {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ad not ready, please try again'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.of(dialogContext).pop();
                          }
                        }
                      },
                      child: const Text(
                        'Unlock',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showLockedDialog(
    BuildContext context,
    DifficultyRequirement req,
  ) {
    final isDark = context.read<AppSettings>().isDarkMode;
    final bg = isDark ? AppTheme.darkSurface : Colors.white;
    final titleColor = isDark ? AppTheme.darkTextPrimary : Colors.black87;
    final descColor =
        isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600;
    final amberBg =
        isDark ? Colors.amber.withValues(alpha: 0.12) : Colors.amber.shade50;
    final amberBorder = isDark ? Colors.amber.shade700 : Colors.amber.shade200;
    final progressBg = isDark ? const Color(0xFF333333) : Colors.white;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        backgroundColor: bg,
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: amberBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: Colors.amber.shade500,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${req.name} Locked',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Complete ${req.requiredGames} ${req.previousDifficulty} games to unlock this level',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: descColor,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: amberBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: amberBorder, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${req.currentGames}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber.shade400,
                          ),
                        ),
                        Text(
                          ' / ${req.requiredGames}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: req.currentGames / req.requiredGames,
                        minHeight: 10,
                        backgroundColor: progressBg,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.amber.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${req.remainingGames} more games to go! 💪',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Keep Playing!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
