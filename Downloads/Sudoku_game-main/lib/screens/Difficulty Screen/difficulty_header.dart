import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/game_state.dart';
import '../Settings Screen/app_settings.dart';
import 'difficulty_dialog.dart';

class DifficultyHeader extends StatelessWidget {
  const DifficultyHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppSettings>().isDarkMode;

    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final allUnlocked = !gameState.isDifficultyLocked('Easy') &&
            !gameState.isDifficultyLocked('Regular') &&
            !gameState.isDifficultyLocked('Hard') &&
            !gameState.isDifficultyLocked('Expert') &&
            !gameState.isDifficultyLocked('Professional') &&
            !gameState.isDifficultyLocked('Extreme');

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurfaceElevated
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.green.shade400,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: isDark
                          ? [Colors.green.shade300, Colors.green.shade500]
                          : [Colors.green.shade500, Colors.green.shade700],
                    ).createShader(bounds),
                    child: const Text(
                      "Sudoku",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (!allUnlocked)
                GestureDetector(
                  onTap: () {
                    DifficultyDialogs.showUnlockAllDialog(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_open_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        SizedBox(width: 5),
                        Text(
                          "Unlock All",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
