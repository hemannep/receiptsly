import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/Home Screen/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      emoji: '🎯',
      color1: Color(0xFF43A047),
      color2: Color(0xFF1B5E20),
      title: 'Welcome to Sudoku!',
      subtitle: 'Train your brain every day',
      description:
          'Fill the 9×9 grid so that every row, column, and 3×3 box contains the digits 1 through 9. Simple rules — endless fun!',
      tip: null,
    ),
    _OnboardingData(
      emoji: '📋',
      color1: Color(0xFF1E88E5),
      color2: Color(0xFF0D47A1),
      title: 'The Rules',
      subtitle: 'Three simple constraints',
      description: null,
      tip: null,
      rules: [
        _Rule(
            'Each ROW must contain 1–9', Icons.table_rows_rounded, Colors.blue),
        _Rule('Each COLUMN must contain 1–9', Icons.view_column_rounded,
            Colors.green),
        _Rule('Each 3×3 BOX must contain 1–9', Icons.grid_view_rounded,
            Colors.purple),
      ],
    ),
    _OnboardingData(
      emoji: '✏️',
      color1: Color(0xFF8E24AA),
      color2: Color(0xFF4A148C),
      title: 'Notes Mode',
      subtitle: 'Your secret weapon',
      description:
          'Tap the Notes button to toggle note-taking mode. Pencil in candidate numbers in any cell — just like solving on paper. Tap the same number again to remove the note.',
      tip:
          '💡 Pro Tip: Use notes to track possibilities in tricky cells before committing.',
    ),
    _OnboardingData(
      emoji: '🔦',
      color1: Color(0xFFF57C00),
      color2: Color(0xFFE65100),
      title: 'Hints & Undo',
      subtitle: 'Always a way forward',
      description:
          'Stuck? Use a Hint — watch a short ad to reveal the correct number for any selected cell. Made a wrong move? Tap Undo to go back. Use Erase to clear a cell completely.',
      tip: '💡 Pro Tip: Undo is unlimited — never fear experimenting!',
    ),
    _OnboardingData(
      emoji: '🧠',
      color1: Color(0xFF00897B),
      color2: Color(0xFF004D40),
      title: 'Tips & Strategies',
      subtitle: 'Think like a Sudoku master',
      description: null,
      tip: null,
      strategies: [
        _Strategy('Scan rows & columns first',
            'Look for cells where only one number fits.'),
        _Strategy('Box elimination',
            'If a digit appears in 2 rows of a box, it must be in the 3rd row.'),
        _Strategy('Naked singles',
            'If a cell has only one possible candidate, place it immediately.'),
        _Strategy('Cross-hatching',
            'Draw mental lines from known numbers to eliminate cells.'),
      ],
    ),
    _OnboardingData(
      emoji: '🔥',
      color1: Color(0xFFE53935),
      color2: Color(0xFFB71C1C),
      title: 'Streaks & Levels',
      subtitle: 'Grow every day',
      description:
          'Complete games daily to build your streak 🔥. Start with Newbie and unlock harder difficulties as you progress. Watch your skills grow!',
      tip:
          '💡 Daily Challenge: Everyone worldwide plays the exact same puzzle each day!',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _animController.reset();
    _animController.forward();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [page.color1, page.color2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (_, index) {
                    return FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: _OnboardingPage(data: _pages[index]),
                      ),
                    );
                  },
                ),
              ),

              // Dots + Button
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),

                    // Next / Get Started Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: page.color2,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        onPressed: _next,
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? '🎮  Start Playing!'
                              : 'Next  →',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Emoji icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 58),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 28),

          // Description or special content
          if (data.description != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                data.description!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.6,
                ),
              ),
            ),

          if (data.rules != null) ...[
            ...data.rules!.map(
              (r) => _RuleCard(rule: r),
            ),
          ],

          if (data.strategies != null) ...[
            ...data.strategies!.map(
              (s) => _StrategyCard(strategy: s),
            ),
          ],

          if (data.tip != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Text(
                data.tip!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final _Rule rule;

  const _RuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: rule.color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(rule.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              rule.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final _Strategy strategy;

  const _StrategyCard({required this.strategy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strategy.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strategy.desc,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String emoji;
  final Color color1;
  final Color color2;
  final String title;
  final String subtitle;
  final String? description;
  final String? tip;
  final List<_Rule>? rules;
  final List<_Strategy>? strategies;

  const _OnboardingData({
    required this.emoji,
    required this.color1,
    required this.color2,
    required this.title,
    required this.subtitle,
    this.description,
    this.tip,
    this.rules,
    this.strategies,
  });
}

class _Rule {
  final String text;
  final IconData icon;
  final Color color;

  const _Rule(this.text, this.icon, this.color);
}

class _Strategy {
  final String title;
  final String desc;

  const _Strategy(this.title, this.desc);
}
