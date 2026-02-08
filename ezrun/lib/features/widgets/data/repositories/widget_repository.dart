import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../profile/data/repositories/settings_repository.dart';
import '../models/widget_config.dart';

class WidgetRepository extends SettingsRepository {
  WidgetRepository(SharedPreferences prefs, SupabaseClient supabase)
    : super(prefs, supabase);

  static const String _keyGoalDate = 'widget_goal_date';
  static const String _keyTitle = 'widget_title';
  static const String _keySubtitle = 'widget_subtitle';
  static const String _keyThemeColor = 'widget_theme_color';
  static const String _keyTextSize = 'widget_text_size';

  WidgetConfig getConfig() {
    final defaults = WidgetConfig.defaults();
    return WidgetConfig(
      goalDate: WidgetConfig.parseGoalDate(prefs.getString(_keyGoalDate)),
      title: prefs.getString(_keyTitle) ?? defaults.title,
      subtitle: prefs.getString(_keySubtitle) ?? defaults.subtitle,
      themeColor: WidgetConfig.parseTheme(prefs.getString(_keyThemeColor)),
      textSize: WidgetConfig.parseTextSize(prefs.getString(_keyTextSize)),
    );
  }

  Future<void> saveConfig(WidgetConfig config) async {
    await prefs.setString(_keyGoalDate, config.goalDateStorage);
    await prefs.setString(_keyTitle, config.title);
    await prefs.setString(_keySubtitle, config.subtitle);
    await prefs.setString(_keyThemeColor, config.themeColor.name);
    await prefs.setString(_keyTextSize, config.textSize.name);
  }

  Future<void> clearConfig() async {
    await prefs.remove(_keyGoalDate);
    await prefs.remove(_keyTitle);
    await prefs.remove(_keySubtitle);
    await prefs.remove(_keyThemeColor);
    await prefs.remove(_keyTextSize);
  }
}
