enum Difficulty { easy, medium, hard }

int removedCells(Difficulty d) {
  switch (d) {
    case Difficulty.easy:
      return 35;
    case Difficulty.medium:
      return 45;
    case Difficulty.hard:
      return 55;
  }
}
