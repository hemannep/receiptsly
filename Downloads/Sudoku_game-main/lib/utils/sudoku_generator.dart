import 'dart:math';

class SudokuGame {
  final List<List<int>> board;
  final List<List<int>> solution;
  final List<List<bool>> fixed;

  SudokuGame(this.board, this.solution, this.fixed);
}

class SudokuGenerator {
  /// Standard random generation (for normal game modes).
  static SudokuGame generate(int removeCount) {
    return _generateWithRandom(removeCount, Random());
  }

  /// Seeded generation — given the same [seed] and [removeCount] this always
  /// produces the exact same puzzle. Used for daily challenges so all users
  /// (online or offline) see an identical board for a given date.
  static SudokuGame generateSeeded(int removeCount, int seed) {
    return _generateWithRandom(removeCount, Random(seed));
  }

  static SudokuGame _generateWithRandom(int removeCount, Random rand) {
    final solution = _generateSolved(rand);
    final board = solution.map((e) => [...e]).toList();
    final fixed = List.generate(9, (_) => List.filled(9, true));

    int removed = 0;
    while (removed < removeCount) {
      int r = rand.nextInt(9);
      int c = rand.nextInt(9);
      if (board[r][c] != 0) {
        board[r][c] = 0;
        fixed[r][c] = false;
        removed++;
      }
    }

    return SudokuGame(board, solution, fixed);
  }

  static List<List<int>> _generateSolved(Random rand) {
    List<List<int>> grid = List.generate(9, (_) => List.filled(9, 0));
    _fill(grid, rand);
    return grid;
  }

  static bool _fill(List<List<int>> g, Random rand) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (g[r][c] == 0) {
          final nums = List.generate(9, (i) => i + 1)..shuffle(rand);
          for (var n in nums) {
            if (_valid(g, r, c, n)) {
              g[r][c] = n;
              if (_fill(g, rand)) return true;
              g[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static bool _valid(List<List<int>> g, int r, int c, int n) {
    for (int i = 0; i < 9; i++) {
      if (g[r][i] == n || g[i][c] == n) return false;
    }
    final br = (r ~/ 3) * 3;
    final bc = (c ~/ 3) * 3;
    for (int i = br; i < br + 3; i++) {
      for (int j = bc; j < bc + 3; j++) {
        if (g[i][j] == n) return false;
      }
    }
    return true;
  }
}
