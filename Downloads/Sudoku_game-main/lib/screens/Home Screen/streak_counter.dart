import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/game_state.dart';
import '../Settings Screen/app_settings.dart';

class StreakCounter extends StatelessWidget {
  const StreakCounter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppSettings>().isDarkMode;

    return Consumer<GameState>(
      builder: (context, gameState, _) {
        return Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade500],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: isDark ? 0.5 : 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange.shade600,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${gameState.gameProgress.streak}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange.shade400,
                      height: 1,
                    ),
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
