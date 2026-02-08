import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRepository {
  final SharedPreferences _prefs;
  final SupabaseClient? _supabase;

  static const String _keyUnits = 'settings_units';
  static const String _keyMapStyle = 'settings_map_style';
  static const String _keyNotifications = 'settings_notifications';
  static const String _keyProfileThemeEnabled =
      'settings_profile_theme_enabled';
  static const String _keyDisplayThemePreference = 'display_theme_preference';

  SettingsRepository(this._prefs, [this._supabase]);

  SharedPreferences get prefs => _prefs;

  // --- Start: Local Settings (Units, Map, Notifications) ---

  // Units: 'metric' or 'imperial'
  String getUnitSystem() {
    return _prefs.getString(_keyUnits) ?? 'metric';
  }

  Future<void> setUnitSystem(String value) async {
    await _prefs.setString(_keyUnits, value);
  }

  // Map Style
  String getMapStyle() {
    return _prefs.getString(_keyMapStyle) ??
        'mapbox://styles/mapbox/streets-v11';
  }

  Future<void> setMapStyle(String value) async {
    await _prefs.setString(_keyMapStyle, value);
  }

  // Notification Preferences
  // Stored as JSON: { 'push': true, 'follows': true, 'achievements': true, 'social': true }
  Map<String, bool> getNotificationSettings() {
    final jsonString = _prefs.getString(_keyNotifications);
    if (jsonString == null) {
      return {
        'push': true,
        'follows': true,
        'achievements': true,
        'social': true,
      };
    }
    try {
      return Map<String, bool>.from(json.decode(jsonString));
    } catch (_) {
      return {
        'push': true,
        'follows': true,
        'achievements': true,
        'social': true,
      };
    }
  }

  Future<void> setNotificationSettings(Map<String, bool> settings) async {
    await _prefs.setString(_keyNotifications, json.encode(settings));
  }

  Future<void> updateNotificationSetting(String key, bool value) async {
    final current = getNotificationSettings();
    current[key] = value;
    await setNotificationSettings(current);
  }

  // Profile theme (blue/green background effect on Profile screen)
  bool getProfileThemeEnabled() {
    return _prefs.getBool(_keyProfileThemeEnabled) ?? true;
  }

  Future<void> setProfileThemeEnabled(bool enabled) async {
    await _prefs.setBool(_keyProfileThemeEnabled, enabled);
  }

  String getDisplayThemePreference() {
    return _prefs.getString(_keyDisplayThemePreference) ?? 'dark';
  }

  Future<void> setDisplayThemePreference(String value) async {
    await _prefs.setString(_keyDisplayThemePreference, value);
  }

  // --- End: Local Settings ---

  // --- Start: Blocked Users (Backend) ---

  Future<List<Map<String, dynamic>>> fetchBlockedUsers() async {
    final supabase = _supabase;
    if (supabase == null) return [];
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    // Assuming a table `ezrun_blocked_users` with `blocker_id` and `blocked_id`
    // If it doesn't exist, we might need to create it.
    // For now we assume the standard pattern.
    try {
      final response = await supabase
          .from('ezrun_blocked_users')
          .select(
            'blocked_id, user:users!ezrun_blocked_users_blocked_id_fkey(id, name, email, profile_pic)',
          )
          .eq('blocker_id', user.id);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Table might not exist yet, return empty list gracefully
      return [];
    }
  }

  Future<void> blockUser(String userIdToBlock) async {
    final supabase = _supabase;
    if (supabase == null) throw Exception('Backend unavailable');
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await supabase.from('ezrun_blocked_users').upsert({
      'blocker_id': user.id,
      'blocked_id': userIdToBlock,
    });
  }

  Future<void> unblockUser(String userIdToUnblock) async {
    final supabase = _supabase;
    if (supabase == null) throw Exception('Backend unavailable');
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await supabase
        .from('ezrun_blocked_users')
        .delete()
        .eq('blocker_id', user.id)
        .eq('blocked_id', userIdToUnblock);
  }

  // --- End: Blocked Users ---
}
