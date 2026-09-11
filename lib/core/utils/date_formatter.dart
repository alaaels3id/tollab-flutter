class DateFormatter {
  static const List<String> arabicMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// Returns localized Arabic month name (1 - 12)
  static String getArabicMonthName(int month) {
    if (month < 1 || month > 12) return '';
    return arabicMonths[month - 1];
  }

  /// Formats Month & Year, e.g. "سبتمبر 2026"
  static String formatPeriodLabel(int month, int year) {
    return '${getArabicMonthName(month)} $year';
  }

  /// Returns the maximum days in the given month and year (handles leap years)
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Clamps dueDay to the last valid day of that specific month
  /// e.g. Day 31 in Feb 2026 -> 2026-02-28, in Feb 2024 -> 2024-02-29
  static String calculateDueDate(int year, int month, int dueDay) {
    final maxDays = daysInMonth(year, month);
    final clampedDay = dueDay > maxDays ? maxDays : (dueDay < 1 ? 1 : dueDay);
    final mStr = month.toString().padLeft(2, '0');
    final dStr = clampedDay.toString().padLeft(2, '0');
    return '$year-$mStr-$dStr';
  }

  /// Format date string "YYYY-MM-DD" into Arabic date "10 سبتمبر 2026"
  static String formatFullArabicDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final parts = dateStr.split('T')[0].split('-');
      if (parts.length >= 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return '$day ${getArabicMonthName(month)} $year';
      }
      final dt = DateTime.parse(dateStr);
      return '${dt.day} ${getArabicMonthName(dt.month)} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  /// Format relative due date label
  static String formatRelativeDueDate(int dueDay) {
    final today = DateTime.now().day;
    final diff = dueDay - today;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    if (diff == 2) return 'بعد يومين';
    if (diff > 2) return 'خلال $diff أيام';
    if (diff == -1) return 'أمس (متأخر)';
    return 'متأخر منذ ${diff.abs()} يوم';
  }

  /// Returns today's date formatted as YYYY-MM-DD
  static String getTodayString() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}
