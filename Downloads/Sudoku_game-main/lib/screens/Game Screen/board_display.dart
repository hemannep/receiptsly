import 'package:flutter/material.dart';
import '../../widgets/sudoku_borad.dart';
import '../../utils/game_state.dart';

class BoardDisplay extends StatelessWidget {
  final GameState gameState;

  const BoardDisplay({required this.gameState, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            SudokuBoard(
              board: gameState.game.board,
              solution: gameState.game.solution,
              fixed: gameState.game.fixed,
              notes: gameState.notes,
              selectedRow: gameState.selectedRow,
              selectedCol: gameState.selectedCol,
              activeNumber: gameState.activeNumber,
              onTap: gameState.selectCell,
            ),
            if (gameState.isPaused)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(
                    Icons.pause_circle_filled,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
