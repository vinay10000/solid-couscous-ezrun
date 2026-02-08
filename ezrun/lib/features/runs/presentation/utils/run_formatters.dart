String formatKm(double km) {
  // Match screenshot style: 2.00KM
  return '${km.toStringAsFixed(2)}KM';
}

String formatDurationHms(int seconds) {
  // Match screenshot style: 20:00 (mm:ss) unless >= 1h.
  final s = seconds.clamp(0, 1 << 30);
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

String formatPacePerKm(int? secondsPerKm) {
  if (secondsPerKm == null || secondsPerKm <= 0) return '--:--/KM';
  final s = secondsPerKm.clamp(0, 1 << 30);
  final m = s ~/ 60;
  final sec = s % 60;
  return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}/KM';
}

String formatTimeAgo(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m minute${m == 1 ? '' : 's'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h hour${h == 1 ? '' : 's'} ago';
  }
  final d = diff.inDays;
  return '$d day${d == 1 ? '' : 's'} ago';
}

String formatRunDateLine(DateTime dt) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
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

  final weekday = weekdays[(dt.weekday - 1).clamp(0, 6)];
  final month = months[(dt.month - 1).clamp(0, 11)];

  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final minute = dt.minute.toString().padLeft(2, '0');

  // Example: Sunday 7 December 19:19 PM (screenshot-like; hour is 12h-ish there,
  // but many UIs show 12h with AM/PM. We'll use 12h here.)
  return '$weekday ${dt.day} $month $hour12:$minute $ampm';
}
