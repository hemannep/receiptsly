import 'package:flutter/material.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  int _selectedCategory = 0;

  final List<_TipCategory> _categories = [
    _TipCategory(
      name: 'Beginner',
      icon: '🌱',
      color: Colors.green,
      tips: [
        _Tip(
          title: 'Start with obvious cells',
          body:
              'Scan the board for cells that can only hold one possible number. These are called "naked singles" — easy wins that help you fill in more of the board.',
          icon: '👀',
        ),
        _Tip(
          title: 'One digit at a time',
          body:
              'Pick a single digit (e.g., "1") and scan every row, column, and box. Mark where it can go. This cross-hatching technique is the fastest way to start.',
          icon: '🔢',
        ),
        _Tip(
          title: 'Use Notes liberally',
          body:
              'Enable Notes Mode and pencil in every candidate for a cell. As you fill in other cells, candidates get ruled out automatically — making it easy to spot singles.',
          icon: '✏️',
        ),
        _Tip(
          title: 'Row → Column → Box',
          body:
              'When placing a number, always verify three things: it doesn\'t exist in that row, that column, and that 3×3 box. This triple check prevents most mistakes.',
          icon: '✅',
        ),
        _Tip(
          title: 'Don\'t guess randomly',
          body:
              'Every Sudoku puzzle has a logical solution. If you\'re about to guess randomly, stop and look for a pattern you might have missed.',
          icon: '🚫',
        ),
      ],
    ),
    _TipCategory(
      name: 'Intermediate',
      icon: '⚡',
      color: Colors.orange,
      tips: [
        _Tip(
          title: 'Hidden singles',
          body:
              'A digit may appear in the notes of multiple cells, but only one cell in a row, column, or box has it. That cell MUST contain that digit. Look carefully!',
          icon: '🔍',
        ),
        _Tip(
          title: 'Naked pairs',
          body:
              'If two cells in the same row/column/box have the exact same two candidates (e.g., 4,7), those two digits must go in those cells — eliminate them from all other cells in that unit.',
          icon: '👥',
        ),
        _Tip(
          title: 'Pointing pairs',
          body:
              'If a digit\'s candidates in a box are all in the same row or column, that digit cannot appear elsewhere in that row or column — even outside the box.',
          icon: '👉',
        ),
        _Tip(
          title: 'Box-line reduction',
          body:
              'If a digit in a row/column is confined to one box, eliminate it from the rest of that box. This reveals new opportunities in rows and columns.',
          icon: '📦',
        ),
        _Tip(
          title: 'Work backwards',
          body:
              'When a row or column is nearly complete (7–8 cells filled), you can instantly deduce the missing one or two numbers without any complex logic.',
          icon: '↩️',
        ),
      ],
    ),
    _TipCategory(
      name: 'Advanced',
      icon: '🧠',
      color: Colors.purple,
      tips: [
        _Tip(
          title: 'X-Wing technique',
          body:
              'If a digit appears in only 2 cells in each of 2 rows, and those cells align in the same 2 columns, eliminate that digit from all other cells in those columns.',
          icon: '✈️',
        ),
        _Tip(
          title: 'Y-Wing (XY-Wing)',
          body:
              'A pivot cell with 2 candidates (AB) sees two cells with candidates (AC) and (BC). Any cell that sees both wings cannot contain C.',
          icon: '🦅',
        ),
        _Tip(
          title: 'Swordfish',
          body:
              'Like X-Wing but with 3 rows and 3 columns. If a digit appears in only 3 cells across 3 rows, and all those cells lie in 3 columns, eliminate it from those columns.',
          icon: '🐟',
        ),
        _Tip(
          title: 'Hidden triples',
          body:
              'Three digits that only appear in 3 cells within a unit form a hidden triple. All other candidates in those 3 cells can be eliminated.',
          icon: '🎭',
        ),
        _Tip(
          title: 'Coloring / Chaining',
          body:
              'Color cells that are conjugate pairs (only 2 positions for a digit in a unit). If two same-colored cells share a unit, that color is wrong — eliminate all of it.',
          icon: '🎨',
        ),
      ],
    ),
    _TipCategory(
      name: 'Habits',
      icon: '🏆',
      color: Colors.blue,
      tips: [
        _Tip(
          title: 'Play daily challenges',
          body:
              'The Daily Challenge gives you a new puzzle every day — same puzzle for all players worldwide. It\'s great for consistent practice and streak building.',
          icon: '📅',
        ),
        _Tip(
          title: 'Time yourself',
          body:
              'Tracking your solve time shows progress over weeks. Don\'t rush — accuracy matters more than speed. Speed comes naturally with practice.',
          icon: '⏱️',
        ),
        _Tip(
          title: 'Review your mistakes',
          body:
              'When a wrong number is highlighted in red, pause and ask yourself why you placed it. Understanding your errors is the fastest way to improve.',
          icon: '🔴',
        ),
        _Tip(
          title: 'Unlock harder levels',
          body:
              'Progress through the difficulties: Newbie → Easy → Regular → Hard → Expert → Professional → Extreme. Each level sharpens a new mental skill.',
          icon: '🔓',
        ),
        _Tip(
          title: 'Build a streak',
          body:
              'Playing at least one game every day builds your streak 🔥. Streaks are a great motivator and proof of consistent mental exercise.',
          icon: '🔥',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final category = _categories[_selectedCategory];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Colors.green.shade500,
                            Colors.green.shade700
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'Tips & Tricks',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Text(
                        'Master the art of Sudoku',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category tabs
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = i == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? cat.color : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: selected
                                ? cat.color.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(cat.icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Tips list
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ListView.builder(
                  key: ValueKey(_selectedCategory),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: category.tips.length,
                  itemBuilder: (_, i) {
                    return _TipCard(
                      tip: category.tips[i],
                      color: category.color,
                      index: i,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatefulWidget {
  final _Tip tip;
  final Color color;
  final int index;

  const _TipCard({required this.tip, required this.color, required this.index});

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: widget.color, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_expanded ? 0.12 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.tip.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.tip.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 4),
                  child: Text(
                    widget.tip.body,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCategory {
  final String name;
  final String icon;
  final Color color;
  final List<_Tip> tips;

  const _TipCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.tips,
  });
}

class _Tip {
  final String title;
  final String body;
  final String icon;

  const _Tip({
    required this.title,
    required this.body,
    required this.icon,
  });
}
