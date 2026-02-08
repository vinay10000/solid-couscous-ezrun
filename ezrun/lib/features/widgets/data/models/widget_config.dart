enum WidgetThemeColor { blue, purple, green, orange, pink, cyan }

enum WidgetTextSize { small, medium, large }

class WidgetConfig {
  final DateTime goalDate;
  final String title;
  final String subtitle;
  final WidgetThemeColor themeColor;
  final WidgetTextSize textSize;

  const WidgetConfig({
    required this.goalDate,
    required this.title,
    required this.subtitle,
    required this.themeColor,
    required this.textSize,
  });

  factory WidgetConfig.defaults() {
    final now = DateTime.now();
    return WidgetConfig(
      goalDate: DateTime(now.year, now.month, now.day),
      title: 'DAYS TO',
      subtitle: 'Your next goal',
      themeColor: WidgetThemeColor.blue,
      textSize: WidgetTextSize.medium,
    );
  }

  WidgetConfig copyWith({
    DateTime? goalDate,
    String? title,
    String? subtitle,
    WidgetThemeColor? themeColor,
    WidgetTextSize? textSize,
  }) {
    return WidgetConfig(
      goalDate: goalDate ?? this.goalDate,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      themeColor: themeColor ?? this.themeColor,
      textSize: textSize ?? this.textSize,
    );
  }

  String get goalDateStorage {
    final dateOnly = DateTime(goalDate.year, goalDate.month, goalDate.day);
    final year = dateOnly.year.toString().padLeft(4, '0');
    final month = dateOnly.month.toString().padLeft(2, '0');
    final day = dateOnly.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime parseGoalDate(String? value) {
    if (value == null || value.isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    final parts = value.split('-');
    if (parts.length != 3) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    return DateTime(year, month, day);
  }

  static WidgetThemeColor parseTheme(String? value) {
    return WidgetThemeColor.values.firstWhere(
      (theme) => theme.name == value,
      orElse: () => WidgetThemeColor.blue,
    );
  }

  static WidgetTextSize parseTextSize(String? value) {
    return WidgetTextSize.values.firstWhere(
      (size) => size.name == value,
      orElse: () => WidgetTextSize.medium,
    );
  }
}
