import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../utils/app_theme.dart';
import '../../utils/daily_challenge_service.dart';
import 'Game Screen/game_screen.dart';
import 'Settings Screen/app_settings.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;
  late PageController _pageController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedDate = DateTime.now();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _playChallenge() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final challenge =
          await DailyChallengeService.getChallengeForDate(_selectedDate);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DailyChallengeGameScreen(
            challenge: challenge,
            challengeDate: _selectedDate,
          ),
        ),
      );

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading challenge: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppSettings>().isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : Colors.grey.shade900;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600;

    // Responsive font size based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = screenWidth < 360 ? 28.0 : 34.0;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Expanded prevents the text column from pushing the icon
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: isDark
                                  ? [
                                      Colors.green.shade300,
                                      Colors.green.shade500,
                                    ]
                                  : [
                                      Colors.green.shade500,
                                      Colors.green.shade700,
                                    ],
                            ).createShader(bounds),
                            child: Text(
                              "Daily Challenge",
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Play with everyone today",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 44,
                      color: Colors.green.shade400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Calendar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime(2024, 1, 1),
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDate,
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDate, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                        _focusedDate = focusedDay;
                        _errorMessage = null;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDate = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(color: textPrimary),
                      todayDecoration: BoxDecoration(
                        color: isDark
                            ? Colors.green.shade800
                            : Colors.green.shade200,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      weekendTextStyle: TextStyle(color: textSecondary),
                      outsideTextStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                      disabledTextStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade400,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      weekendStyle: TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.green.shade400,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.green.shade400,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Challenge info card ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.green.withValues(alpha: 0.15),
                              Colors.green.withValues(alpha: 0.08),
                            ]
                          : [
                              Colors.green.shade50,
                              Colors.green.shade100.withValues(alpha: 0.5),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.green.shade700
                          : Colors.green.shade300,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatDateForDisplay(_selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '🎲 Random Difficulty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Challenge changes every day\n'
                        'Difficulty varies: Newbie → Extreme\n'
                        'Same puzzle for all players worldwide',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Info badge ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.blue.withValues(alpha: 0.12)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? Colors.blue.shade700 : Colors.blue.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        color: Colors.blue.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🌍 All players worldwide play the EXACT same board',
                          style: TextStyle(
                            color: Colors.blue.shade400,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Error message ────────────────────────────────────────────
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.red.withValues(alpha: 0.15)
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isDark ? Colors.red.shade700 : Colors.red.shade300,
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // ── Play button ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isLoading
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _playChallenge,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Play Challenge',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateForDisplay(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class DailyChallengeGameScreen extends StatelessWidget {
  final dynamic challenge;
  final DateTime challengeDate;

  const DailyChallengeGameScreen({
    required this.challenge,
    required this.challengeDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateKey = '${challengeDate.year}-'
        '${challengeDate.month.toString().padLeft(2, '0')}-'
        '${challengeDate.day.toString().padLeft(2, '0')}';

    return GameScreen(
      key: ValueKey('daily_$dateKey'),
      difficulty: 'Daily Challenge',
      removeCount: 60,
      isContinue: false,
      isDailyChallenge: true,
      challengeDate: challengeDate,
      customGame: challenge,
    );
  }
}
