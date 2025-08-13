// lib/core/utils/date_utils.dart
import 'package:intl/intl.dart';

/// Comprehensive date utilities for Receiptsly app
/// Handles date formatting, parsing, calculations, and business logic
class DateUtils {
  // Common date formatters
  static final DateFormat _shortDateFormat = DateFormat('MMM d, y');
  static final DateFormat _longDateFormat = DateFormat('MMMM d, y');
  static final DateFormat _numericDateFormat = DateFormat('MM/dd/yyyy');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _fullTimeFormat = DateFormat('h:mm:ss a');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, y h:mm a');
  static final DateFormat _shortMonthFormat = DateFormat('MMM');
  static final DateFormat _fullMonthFormat = DateFormat('MMMM');
  static final DateFormat _yearFormat = DateFormat('y');

  // Date Formatting Methods
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  static String formatLongDate(DateTime date) {
    return _longDateFormat.format(date);
  }

  static String formatNumericDate(DateTime date) {
    return _numericDateFormat.format(date);
  }

  static String formatISODate(DateTime date) {
    return _isoDateFormat.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  static String formatFullTime(DateTime date) {
    return _fullTimeFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  static String formatCustom(DateTime date, String pattern) {
    try {
      final formatter = DateFormat(pattern);
      return formatter.format(date);
    } catch (e) {
      return formatShortDate(date);
    }
  }

  // Relative Time Formatting
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 30) {
      return 'Just now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return formatShortDate(date);
    }
  }

  static String formatFutureTime(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inSeconds < 60) {
      return 'In ${difference.inSeconds} seconds';
    } else if (difference.inMinutes < 60) {
      return 'In ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else if (difference.inHours < 24) {
      return 'In ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inDays < 7) {
      return 'In ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else {
      return formatShortDate(date);
    }
  }

  // Date Parsing Methods
  static DateTime? parseDate(String dateString) {
    if (dateString.isEmpty) return null;

    // Try common date formats
    final formats = [
      'yyyy-MM-dd',
      'MM/dd/yyyy',
      'dd/MM/yyyy',
      'MMM d, y',
      'MMMM d, y',
      'yyyy-MM-dd HH:mm:ss',
      'MM/dd/yyyy HH:mm:ss',
      'yyyy-MM-ddTHH:mm:ss',
      'yyyy-MM-ddTHH:mm:ssZ',
    ];

    for (final format in formats) {
      try {
        final formatter = DateFormat(format);
        return formatter.parseStrict(dateString);
      } catch (e) {
        continue;
      }
    }

    // Try DateTime.parse as fallback
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static DateTime? parseTime(String timeString) {
    if (timeString.isEmpty) return null;

    final timeFormats = ['HH:mm', 'HH:mm:ss', 'h:mm a', 'h:mm:ss a'];

    final today = DateTime.now();

    for (final format in timeFormats) {
      try {
        final formatter = DateFormat(format);
        final parsedTime = formatter.parseStrict(timeString);

        return DateTime(
          today.year,
          today.month,
          today.day,
          parsedTime.hour,
          parsedTime.minute,
          parsedTime.second,
        );
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  // Date Calculation Methods
  static DateTime addBusinessDays(DateTime date, int businessDays) {
    int daysToAdd = businessDays;
    DateTime result = date;

    while (daysToAdd > 0) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday &&
          result.weekday != DateTime.sunday) {
        daysToAdd--;
      }
    }

    return result;
  }

  static int getBusinessDaysBetween(DateTime startDate, DateTime endDate) {
    if (startDate.isAfter(endDate)) return 0;

    int businessDays = 0;
    DateTime current = startDate;

    while (current.isBefore(endDate) || isSameDay(current, endDate)) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        businessDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return businessDays;
  }

  static int getDaysBetween(DateTime startDate, DateTime endDate) {
    return endDate.difference(startDate).inDays;
  }

  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  static DateTime getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return getStartOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  static DateTime getEndOfWeek(DateTime date) {
    final daysUntilSunday = 7 - date.weekday;
    return getEndOfDay(date.add(Duration(days: daysUntilSunday)));
  }

  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    final nextMonth = date.month == 12
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }

  static DateTime getStartOfQuarter(DateTime date) {
    final quarterStartMonth = ((date.month - 1) ~/ 3) * 3 + 1;
    return DateTime(date.year, quarterStartMonth, 1);
  }

  static DateTime getEndOfQuarter(DateTime date) {
    final quarterStartMonth = ((date.month - 1) ~/ 3) * 3 + 1;
    final quarterEndMonth = quarterStartMonth + 2;
    return getEndOfMonth(DateTime(date.year, quarterEndMonth, 1));
  }

  static DateTime getStartOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  static DateTime getEndOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
  }

  // Date Comparison Methods
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isSameWeek(DateTime date1, DateTime date2) {
    final startOfWeek1 = getStartOfWeek(date1);
    final startOfWeek2 = getStartOfWeek(date2);
    return isSameDay(startOfWeek1, startOfWeek2);
  }

  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  static bool isSameYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  static bool isThisWeek(DateTime date) {
    return isSameWeek(date, DateTime.now());
  }

  static bool isThisMonth(DateTime date) {
    return isSameMonth(date, DateTime.now());
  }

  static bool isThisYear(DateTime date) {
    return isSameYear(date, DateTime.now());
  }

  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  static bool isBusinessDay(DateTime date) {
    return !isWeekend(date);
  }

  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  // Business-specific Date Methods
  static DateTime getNextBusinessDay(DateTime date) {
    DateTime nextDay = date.add(const Duration(days: 1));

    while (isWeekend(nextDay)) {
      nextDay = nextDay.add(const Duration(days: 1));
    }

    return nextDay;
  }

  static DateTime getPreviousBusinessDay(DateTime date) {
    DateTime prevDay = date.subtract(const Duration(days: 1));

    while (isWeekend(prevDay)) {
      prevDay = prevDay.subtract(const Duration(days: 1));
    }

    return prevDay;
  }

  static List<DateTime> getBusinessDaysInRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    final businessDays = <DateTime>[];
    DateTime current = startDate;

    while (current.isBefore(endDate) || isSameDay(current, endDate)) {
      if (isBusinessDay(current)) {
        businessDays.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    return businessDays;
  }

  // Financial/Tax Year Methods
  static DateTime getFinancialYearStart(DateTime date, {int startMonth = 4}) {
    if (date.month >= startMonth) {
      return DateTime(date.year, startMonth, 1);
    } else {
      return DateTime(date.year - 1, startMonth, 1);
    }
  }

  static DateTime getFinancialYearEnd(DateTime date, {int startMonth = 4}) {
    final startDate = getFinancialYearStart(date, startMonth: startMonth);
    return getEndOfMonth(DateTime(startDate.year + 1, startMonth - 1, 1));
  }

  static DateTime getTaxYearStart(DateTime date) {
    // US tax year starts January 1
    if (date.month >= 1) {
      return DateTime(date.year, 1, 1);
    } else {
      return DateTime(date.year - 1, 1, 1);
    }
  }

  static DateTime getTaxYearEnd(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
  }

  // Quarter Methods
  static int getQuarter(DateTime date) {
    return ((date.month - 1) ~/ 3) + 1;
  }

  static String getQuarterName(DateTime date) {
    final quarter = getQuarter(date);
    return 'Q$quarter ${date.year}';
  }

  static List<DateTime> getQuarterMonths(DateTime date) {
    final quarterStartMonth = ((date.month - 1) ~/ 3) * 3 + 1;
    return [
      DateTime(date.year, quarterStartMonth, 1),
      DateTime(date.year, quarterStartMonth + 1, 1),
      DateTime(date.year, quarterStartMonth + 2, 1),
    ];
  }

  // Age Calculation
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  // Date Range Methods
  static List<DateTime> getDateRange(DateTime startDate, DateTime endDate) {
    final dates = <DateTime>[];
    DateTime current = startDate;

    while (current.isBefore(endDate) || isSameDay(current, endDate)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  static List<DateTime> getMonthsInRange(DateTime startDate, DateTime endDate) {
    final months = <DateTime>[];
    DateTime current = DateTime(startDate.year, startDate.month, 1);
    final endMonth = DateTime(endDate.year, endDate.month, 1);

    while (current.isBefore(endMonth) || isSameMonth(current, endMonth)) {
      months.add(current);
      if (current.month == 12) {
        current = DateTime(current.year + 1, 1, 1);
      } else {
        current = DateTime(current.year, current.month + 1, 1);
      }
    }

    return months;
  }

  // Date Validation
  static bool isValidDate(int year, int month, int day) {
    if (year < 1 || month < 1 || month > 12 || day < 1) {
      return false;
    }

    try {
      final date = DateTime(year, month, day);
      return date.year == year && date.month == month && date.day == day;
    } catch (e) {
      return false;
    }
  }

  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  static int getDaysInMonth(int year, int month) {
    if (month < 1 || month > 12) return 0;

    const daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    if (month == 2 && isLeapYear(year)) {
      return 29;
    }

    return daysInMonth[month - 1];
  }

  // Locale-specific Formatting
  static String formatDateForLocale(DateTime date, String locale) {
    try {
      switch (locale.toLowerCase()) {
        case 'en_us':
          return DateFormat('MM/dd/yyyy').format(date);
        case 'en_gb':
          return DateFormat('dd/MM/yyyy').format(date);
        case 'de_de':
          return DateFormat('dd.MM.yyyy').format(date);
        case 'fr_fr':
          return DateFormat('dd/MM/yyyy').format(date);
        case 'es_es':
          return DateFormat('dd/MM/yyyy').format(date);
        case 'it_it':
          return DateFormat('dd/MM/yyyy').format(date);
        case 'ja_jp':
          return DateFormat('yyyy/MM/dd').format(date);
        case 'ko_kr':
          return DateFormat('yyyy. MM. dd.').format(date);
        case 'zh_cn':
          return DateFormat('yyyy年MM月dd日').format(date);
        default:
          return formatShortDate(date);
      }
    } catch (e) {
      return formatShortDate(date);
    }
  }

  // Receipt-specific Date Methods
  static bool isReceiptDateValid(DateTime receiptDate) {
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));

    return receiptDate.isAfter(oneYearAgo) &&
        receiptDate.isBefore(now.add(const Duration(days: 1)));
  }

  static String formatReceiptDate(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else if (isThisWeek(date)) {
      return DateFormat('EEEE').format(date);
    } else if (isThisYear(date)) {
      return formatShortDate(date);
    } else {
      return formatShortDate(date);
    }
  }

  // Invoice Due Date Methods
  static DateTime calculateDueDate(DateTime issueDate, int paymentTerms) {
    return issueDate.add(Duration(days: paymentTerms));
  }

  static bool isInvoiceOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }

  static int getDaysUntilDue(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference;
  }

  static String formatDueStatus(DateTime dueDate) {
    final daysUntilDue = getDaysUntilDue(dueDate);

    if (daysUntilDue < 0) {
      return 'Overdue by ${-daysUntilDue} day${-daysUntilDue == 1 ? '' : 's'}';
    } else if (daysUntilDue == 0) {
      return 'Due today';
    } else if (daysUntilDue == 1) {
      return 'Due tomorrow';
    } else if (daysUntilDue <= 7) {
      return 'Due in $daysUntilDue days';
    } else {
      return 'Due ${formatShortDate(dueDate)}';
    }
  }

  // Expense Period Methods
  static String getExpensePeriod(DateTime date) {
    if (isThisMonth(date)) {
      return 'This month';
    } else if (isSameMonth(
      date,
      DateTime.now().subtract(const Duration(days: 30)),
    )) {
      return 'Last month';
    } else {
      return DateFormat('MMMM y').format(date);
    }
  }

  static List<DateTime> getExpenseMonths(List<DateTime> expenseDates) {
    final uniqueMonths = <DateTime>{};

    for (final date in expenseDates) {
      uniqueMonths.add(DateTime(date.year, date.month, 1));
    }

    final sortedMonths = uniqueMonths.toList()..sort();
    return sortedMonths;
  }

  // Report Period Methods
  static Map<String, DateTime> getReportingPeriods() {
    final now = DateTime.now();

    return {
      'today': getStartOfDay(now),
      'yesterday': getStartOfDay(now.subtract(const Duration(days: 1))),
      'thisWeek': getStartOfWeek(now),
      'lastWeek': getStartOfWeek(now.subtract(const Duration(days: 7))),
      'thisMonth': getStartOfMonth(now),
      'lastMonth': getStartOfMonth(DateTime(now.year, now.month - 1, 1)),
      'thisQuarter': getStartOfQuarter(now),
      'lastQuarter': getStartOfQuarter(now.subtract(const Duration(days: 90))),
      'thisYear': getStartOfYear(now),
      'lastYear': getStartOfYear(DateTime(now.year - 1, 1, 1)),
      'ytd': getStartOfYear(now),
      'last30Days': now.subtract(const Duration(days: 30)),
      'last90Days': now.subtract(const Duration(days: 90)),
      'last365Days': now.subtract(const Duration(days: 365)),
    };
  }

  static String getReportPeriodName(String period) {
    const periodNames = {
      'today': 'Today',
      'yesterday': 'Yesterday',
      'thisWeek': 'This Week',
      'lastWeek': 'Last Week',
      'thisMonth': 'This Month',
      'lastMonth': 'Last Month',
      'thisQuarter': 'This Quarter',
      'lastQuarter': 'Last Quarter',
      'thisYear': 'This Year',
      'lastYear': 'Last Year',
      'ytd': 'Year to Date',
      'last30Days': 'Last 30 Days',
      'last90Days': 'Last 90 Days',
      'last365Days': 'Last 365 Days',
    };

    return periodNames[period] ?? period;
  }

  // Time Zone Methods
  static DateTime convertToLocal(DateTime utcDate) {
    return utcDate.toLocal();
  }

  static DateTime convertToUtc(DateTime localDate) {
    return localDate.toUtc();
  }

  static String formatWithTimezone(DateTime date, {bool showTimezone = true}) {
    final formatted = formatDateTime(date);

    if (showTimezone) {
      final timezone = date.timeZoneName;
      return '$formatted $timezone';
    }

    return formatted;
  }

  // Calendar Methods
  static List<DateTime> getCalendarDates(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final dates = <DateTime>[];

    // Add previous month's trailing dates
    final firstWeekday = firstDay.weekday;
    for (int i = firstWeekday - 1; i > 0; i--) {
      dates.add(firstDay.subtract(Duration(days: i)));
    }

    // Add current month's dates
    for (int day = 1; day <= lastDay.day; day++) {
      dates.add(DateTime(year, month, day));
    }

    // Add next month's leading dates to complete the grid
    final remainingCells = 42 - dates.length; // 6 rows * 7 days
    for (int i = 1; i <= remainingCells; i++) {
      dates.add(lastDay.add(Duration(days: i)));
    }

    return dates;
  }

  static List<String> getWeekdayNames({bool short = false}) {
    if (short) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } else {
      return [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
    }
  }

  static List<String> getMonthNames({bool short = false}) {
    if (short) {
      return [
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
    } else {
      return [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
    }
  }

  // Backup and Sync Methods
  static String formatForBackup(DateTime date) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(date.toUtc());
  }

  static DateTime? parseFromBackup(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Birthday and Anniversary Methods
  static DateTime getNextBirthday(DateTime birthDate) {
    final now = DateTime.now();
    final thisYearBirthday = DateTime(now.year, birthDate.month, birthDate.day);

    if (thisYearBirthday.isAfter(now)) {
      return thisYearBirthday;
    } else {
      return DateTime(now.year + 1, birthDate.month, birthDate.day);
    }
  }

  static int getDaysUntilBirthday(DateTime birthDate) {
    final nextBirthday = getNextBirthday(birthDate);
    return nextBirthday.difference(DateTime.now()).inDays;
  }

  // Scheduling Methods
  static DateTime getNextScheduledDate(DateTime lastDate, String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return lastDate.add(const Duration(days: 1));
      case 'weekly':
        return lastDate.add(const Duration(days: 7));
      case 'biweekly':
        return lastDate.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
      case 'quarterly':
        return DateTime(lastDate.year, lastDate.month + 3, lastDate.day);
      case 'yearly':
        return DateTime(lastDate.year + 1, lastDate.month, lastDate.day);
      default:
        return lastDate;
    }
  }

  // Productivity Methods
  static String getProductivityPeriod(DateTime date) {
    final hour = date.hour;

    if (hour >= 6 && hour < 12) {
      return 'Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }

  static bool isWorkingHours(DateTime date) {
    final hour = date.hour;
    final isWeekday = date.weekday <= 5;

    return isWeekday && hour >= 9 && hour < 17;
  }

  // Reminder Methods
  static List<DateTime> generateReminders(
    DateTime dueDate,
    List<int> daysBefore,
  ) {
    return daysBefore
        .map((days) => dueDate.subtract(Duration(days: days)))
        .where((reminder) => reminder.isAfter(DateTime.now()))
        .toList();
  }

  static DateTime getOptimalReminderTime(DateTime baseDate) {
    // Set reminder for 9 AM on the same day, or next business day if weekend
    var reminderDate = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      9,
      0,
    );

    if (isWeekend(reminderDate)) {
      reminderDate = getNextBusinessDay(reminderDate);
      reminderDate = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        9,
        0,
      );
    }

    return reminderDate;
  }

  // Utility Methods
  static DateTime max(DateTime date1, DateTime date2) {
    return date1.isAfter(date2) ? date1 : date2;
  }

  static DateTime min(DateTime date1, DateTime date2) {
    return date1.isBefore(date2) ? date1 : date2;
  }

  static DateTime clamp(DateTime date, DateTime min, DateTime max) {
    if (date.isBefore(min)) return min;
    if (date.isAfter(max)) return max;
    return date;
  }

  static List<DateTime> sortDates(
    List<DateTime> dates, {
    bool ascending = true,
  }) {
    final sortedDates = List<DateTime>.from(dates);

    if (ascending) {
      sortedDates.sort((a, b) => a.compareTo(b));
    } else {
      sortedDates.sort((a, b) => b.compareTo(a));
    }

    return sortedDates;
  }

  static List<DateTime> getUniqueMonths(List<DateTime> dates) {
    final uniqueMonths = <DateTime>{};

    for (final date in dates) {
      uniqueMonths.add(DateTime(date.year, date.month, 1));
    }

    return sortDates(uniqueMonths.toList());
  }

  static List<DateTime> getUniqueDates(List<DateTime> dates) {
    final uniqueDates = <DateTime>{};

    for (final date in dates) {
      uniqueDates.add(getStartOfDay(date));
    }

    return sortDates(uniqueDates.toList());
  }
}
