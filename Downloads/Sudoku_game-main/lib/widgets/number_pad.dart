import 'package:flutter/material.dart';

class NumberPad extends StatelessWidget {
  final Function(int) onTap;
  final bool Function(int) isDisabled;
  final List<List<int>> board;

  const NumberPad({
    super.key,
    required this.onTap,
    required this.isDisabled,
    required this.board,
  });

  int _countOnBoard(int n) {
    int count = 0;
    for (var row in board) {
      for (var v in row) {
        if (v == n) count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(9, (i) {
            final n = i + 1;
            final disabled = isDisabled(n);
            final remaining = (9 - _countOnBoard(n)).clamp(0, 9);

            return Expanded(
              child: GestureDetector(
                onTap: disabled ? null : () => onTap(n),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$n',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: disabled
                              ? (isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade400)
                              : (isDark
                                  ? Colors.green.shade300
                                  : Colors.green.shade700),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        disabled ? '✓' : '$remaining',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: disabled
                              ? Colors.green.shade400
                              : (isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500),
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
    );
  }
}
