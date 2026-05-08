import 'package:flutter/material.dart';
import '../../utils/game_state.dart';

class GameOverDialog {
  static void show(
    BuildContext context,
    GameState gameState, {
    required VoidCallback onContinue,
    required VoidCallback onHome,
    required VoidCallback onMarkGameOverShown,
  }) {
    final isGameWon = gameState.isBoardComplete();
    final canContinue = gameState.canContinue();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isGameWon
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isGameWon
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    isGameWon ? Icons.check_circle : Icons.favorite_border,
                    color: isGameWon
                        ? Colors.green.shade500
                        : Colors.red.shade500,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isGameWon
                      ? '🎉 Congratulations! 🎉'
                      : (canContinue ? 'Game Over!' : 'Final Game Over!'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isGameWon
                      ? 'You solved the puzzle perfectly!'
                      : (canContinue
                            ? 'You\'ve reached the maximum number of mistakes'
                            : 'No more chances left!'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isGameWon
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isGameWon
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: isGameWon
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Final Score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isGameWon
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${gameState.score}',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: isGameWon
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ScoreBadge(
                            icon: Icons.schedule_rounded,
                            label: gameState.formattedTime,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _ScoreBadge(
                            icon: Icons.error_outline_rounded,
                            label: '${gameState.mistakes} mistakes',
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if (!isGameWon && canContinue)
                  Row(
                    children: [
                      Expanded(
                        child: _GameOverButton(
                          label: 'Continue',
                          color: Colors.blue.shade600,
                          icon: Icons.play_arrow_rounded,
                          onPressed: () {
                            if (Navigator.of(dialogContext).canPop()) {
                              onContinue();
                              Navigator.of(dialogContext).pop();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GameOverButton(
                          label: 'Home',
                          color: Colors.green.shade600,
                          icon: Icons.home_rounded,
                          onPressed: () {
                            if (Navigator.of(dialogContext).canPop()) {
                              onHome();
                              Navigator.of(dialogContext).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: _GameOverButton(
                      label: 'Home',
                      color: isGameWon
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      icon: Icons.home_rounded,
                      onPressed: () {
                        if (Navigator.of(dialogContext).canPop()) {
                          onHome();
                          Navigator.of(dialogContext).pop();
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ScoreBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverButton extends StatefulWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _GameOverButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_GameOverButton> createState() => _GameOverButtonState();
}

class _GameOverButtonState extends State<_GameOverButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: _isProcessing
          ? null
          : () {
              if (!_isProcessing) {
                setState(() => _isProcessing = true);
                widget.onPressed();
              }
            },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 20),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
