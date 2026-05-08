import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/game_state.dart';
import '../Settings Screen/app_settings.dart';

class GameHeader extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onBack;
  final VoidCallback onPauseToggle;

  const GameHeader({
    required this.gameState,
    required this.onBack,
    required this.onPauseToggle,
    super.key,
  });

  @override
  State<GameHeader> createState() => _GameHeaderState();
}

class _GameHeaderState extends State<GameHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _gainController;
  int _displayedScore = 0;
  int _shownGain = 0;

  @override
  void initState() {
    super.initState();
    _displayedScore = widget.gameState.score;
    _gainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didUpdateWidget(covariant GameHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newScore = widget.gameState.score;
    if (newScore != _displayedScore) {
      final delta = newScore - _displayedScore;
      if (delta != 0) {
        setState(() => _shownGain = delta);
        _gainController.forward(from: 0);
      }
      _displayedScore = newScore;
    }
  }

  @override
  void dispose() {
    _gainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;
    final gameState = widget.gameState;

    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final iconBg = isDark ? AppTheme.darkSurfaceElevated : Colors.grey.shade100;
    final iconColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final dividerColor = isDark ? AppTheme.darkDivider : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
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
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Text(
                      "${gameState.score}",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.green.shade400,
                        letterSpacing: -0.5,
                      ),
                    ),
                    // Animated +/- gain bubble
                    Positioned(
                      top: -28,
                      child: AnimatedBuilder(
                        animation: _gainController,
                        builder: (context, _) {
                          final v = _gainController.value;
                          if (v == 0 || v == 1) {
                            return const SizedBox.shrink();
                          }
                          final positive = _shownGain >= 0;
                          return Opacity(
                            opacity: (1 - v).clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, -20 * v),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: positive
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${positive ? "+" : ""}$_shownGain',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: widget.onPauseToggle,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          gameState.isPaused ? Colors.green.shade600 : iconBg,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      gameState.isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: gameState.isPaused ? Colors.white : iconColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HeaderStat(
                  icon: Icons.speed_rounded,
                  label: 'Difficulty',
                  value: gameState.difficulty,
                  isDark: isDark,
                ),
                if (settings.showMistakeLimit) ...[
                  Container(width: 1, height: 40, color: dividerColor),
                  _HeaderStat(
                    icon: Icons.error_outline_rounded,
                    label: 'Mistakes',
                    value: "${gameState.mistakes}/${gameState.maxMistakes}",
                    showError: gameState.mistakes > 1,
                    isDark: isDark,
                  ),
                ],
                if (settings.showTimer) ...[
                  Container(width: 1, height: 40, color: dividerColor),
                  GestureDetector(
                    onTap: widget.onPauseToggle,
                    child: _HeaderStat(
                      icon: Icons.schedule_rounded,
                      label: 'Time',
                      value: gameState.formattedTime,
                      isDark: isDark,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showError;
  final bool isDark;

  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: showError ? Colors.red.shade400 : Colors.green.shade400,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: showError
                ? Colors.red.shade400
                : (isDark ? AppTheme.darkTextPrimary : Colors.black87),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
