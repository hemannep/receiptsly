import 'package:flutter/material.dart';

import '../screens/Settings Screen/app_settings.dart';

class SudokuBoard extends StatelessWidget {
  final List<List<int>> board;
  final List<List<int>> solution;
  final List<List<bool>> fixed;
  final List<List<Set<int>>> notes;

  final int selectedRow;
  final int selectedCol;
  final int activeNumber;

  final void Function(int, int) onTap;

  const SudokuBoard({
    super.key,
    required this.board,
    required this.solution,
    required this.fixed,
    required this.notes,
    required this.selectedRow,
    required this.selectedCol,
    required this.activeNumber,
    required this.onTap,
  });

  bool _hasRowConflict(int r, int c, int n) {
    for (int i = 0; i < 9; i++) {
      if (i != c && board[r][i] == n) return true;
    }
    return false;
  }

  bool _hasColConflict(int r, int c, int n) {
    for (int i = 0; i < 9; i++) {
      if (i != r && board[i][c] == n) return true;
    }
    return false;
  }

  bool _hasBoxConflict(int r, int c, int n) {
    final br = (r ~/ 3) * 3;
    final bc = (c ~/ 3) * 3;
    for (int i = br; i < br + 3; i++) {
      for (int j = bc; j < bc + 3; j++) {
        if ((i != r || j != c) && board[i][j] == n) return true;
      }
    }
    return false;
  }

  bool _hasConflict(int r, int c) {
    final n = board[r][c];
    if (n == 0) return false;
    return _hasRowConflict(r, c, n) ||
        _hasColConflict(r, c, n) ||
        _hasBoxConflict(r, c, n);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = AppSettings();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade800,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List.generate(9, (r) {
          return Expanded(
            child: Row(
              children: List.generate(9, (c) {
                final val = board[r][c];

                final selected = r == selectedRow && c == selectedCol;
                final sameRow = r == selectedRow;
                final sameCol = c == selectedCol;
                final sameBox = selectedRow >= 0 &&
                    (r ~/ 3 == selectedRow ~/ 3) &&
                    (c ~/ 3 == selectedCol ~/ 3);
                final sameNumber = activeNumber != 0 && val == activeNumber;

                final wrong = val != 0 && val != solution[r][c] && !fixed[r][c];

                final hasConflict =
                    settings.highlightConflicts && _hasConflict(r, c);

                // 🎨 BACKGROUND COLOR LOGIC (theme-aware)
                Color bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

                if (selected && wrong) {
                  bgColor = isDark
                      ? Colors.red.shade900.withValues(alpha: 0.6)
                      : Colors.red.shade100;
                } else if (selected) {
                  bgColor = Colors.green.shade500;
                } else if (settings.highlightSameNumber &&
                    sameNumber &&
                    val != 0) {
                  bgColor = isDark
                      ? Colors.green.shade900.withValues(alpha: 0.5)
                      : Colors.green.shade100;
                } else if (sameRow || sameCol || sameBox) {
                  bgColor = isDark
                      ? const Color(0xFF263A2A)
                      : const Color.fromARGB(255, 226, 246, 229);
                } else if (hasConflict && !fixed[r][c]) {
                  // Subtle conflict highlight
                  bgColor = isDark
                      ? Colors.orange.shade900.withValues(alpha: 0.3)
                      : Colors.orange.shade50;
                }

                final divColor =
                    isDark ? Colors.grey.shade700 : Colors.grey.shade300;
                final divThickColor =
                    isDark ? Colors.grey.shade500 : Colors.grey.shade800;

                final borderRight = BorderSide(
                  color: (c + 1) % 3 == 0 ? divThickColor : divColor,
                  width: (c + 1) % 3 == 0 ? 2 : 1,
                );

                final borderBottom = BorderSide(
                  color: (r + 1) % 3 == 0 ? divThickColor : divColor,
                  width: (r + 1) % 3 == 0 ? 2 : 1,
                );

                Color textColor;
                if (selected) {
                  textColor = Colors.white;
                } else if (wrong) {
                  textColor = Colors.red.shade400;
                } else if (fixed[r][c]) {
                  textColor = isDark ? Colors.white : Colors.black87;
                } else {
                  textColor =
                      isDark ? Colors.green.shade300 : Colors.green.shade700;
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(r, c),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border(
                          right: borderRight,
                          bottom: borderBottom,
                        ),
                      ),
                      child: val != 0
                          ? Text(
                              "$val",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: fixed[r][c]
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: textColor,
                              ),
                            )
                          : _buildNotes(r, c, isDark),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNotes(int r, int c, bool isDark) {
    if (notes[r][c].isEmpty) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(3),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(9, (i) {
        final n = i + 1;
        final isHighlighted = activeNumber != 0 && n == activeNumber;
        return Center(
          child: Text(
            notes[r][c].contains(n) ? "$n" : "",
            style: TextStyle(
              fontSize: 10,
              fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w600,
              color: isHighlighted
                  ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                  : (isDark ? Colors.grey.shade400 : Colors.black87),
            ),
          ),
        );
      }),
    );
  }
}
