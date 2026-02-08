import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/settings_repository.dart';

enum ThemePreference {
  dark,
  light,
  system;

  static ThemePreference fromStorage(String? value) {
    switch (value) {
      case 'light':
        return ThemePreference.light;
      case 'system':
        return ThemePreference.system;
      case 'dark':
      default:
        return ThemePreference.dark;
    }
  }

  ThemeMode toThemeMode() {
    switch (this) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.system:
        return ThemeMode.system;
      case ThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  String get storageValue => name;
}

// Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this provider in main.dart');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final supabase = Supabase.instance.client;
  return SettingsRepository(prefs, supabase);
});

// State classes
class SettingsState {
  final String unitSystem;
  final String mapStyle;
  final Map<String, bool> notifications;
  final bool profileThemeEnabled;
  final ThemePreference themePreference;

  const SettingsState({
    this.unitSystem = 'metric',
    this.mapStyle = 'mapbox://styles/mapbox/streets-v11',
    this.notifications = const {
      'push': true,
      'follows': true,
      'achievements': true,
      'social': true,
    },
    this.profileThemeEnabled = true,
    this.themePreference = ThemePreference.dark,
  });

  SettingsState copyWith({
    String? unitSystem,
    String? mapStyle,
    Map<String, bool>? notifications,
    bool? profileThemeEnabled,
    ThemePreference? themePreference,
  }) {
    return SettingsState(
      unitSystem: unitSystem ?? this.unitSystem,
      mapStyle: mapStyle ?? this.mapStyle,
      notifications: notifications ?? this.notifications,
      profileThemeEnabled: profileThemeEnabled ?? this.profileThemeEnabled,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}

// Controller
class SettingsController extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;

  SettingsController(this._repository) : super(const SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    state = SettingsState(
      unitSystem: _repository.getUnitSystem(),
      mapStyle: _repository.getMapStyle(),
      notifications: _repository.getNotificationSettings(),
      profileThemeEnabled: _repository.getProfileThemeEnabled(),
      themePreference: ThemePreference.fromStorage(
        _repository.getDisplayThemePreference(),
      ),
    );
  }

  Future<void> setUnitSystem(String value) async {
    await _repository.setUnitSystem(value);
    state = state.copyWith(unitSystem: value);
  }

  Future<void> setMapStyle(String value) async {
    await _repository.setMapStyle(value);
    state = state.copyWith(mapStyle: value);
  }

  Future<void> toggleNotification(String key) async {
    final current = Map<String, bool>.from(state.notifications);
    final newValue = !(current[key] ?? false);
    current[key] = newValue;

    await _repository.setNotificationSettings(current);
    state = state.copyWith(notifications: current);
  }

  Future<void> updateAllNotifications(bool enabled) async {
    final current = Map<String, bool>.from(state.notifications);
    current.updateAll((key, value) => enabled);

    await _repository.setNotificationSettings(current);
    state = state.copyWith(notifications: current);
  }

  Future<void> setProfileThemeEnabled(bool enabled) async {
    await _repository.setProfileThemeEnabled(enabled);
    state = state.copyWith(profileThemeEnabled: enabled);
  }

  Future<void> setThemePreference(ThemePreference preference) async {
    await _repository.setDisplayThemePreference(preference.storageValue);
    state = state.copyWith(themePreference: preference);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      final repository = ref.watch(settingsRepositoryProvider);
      return SettingsController(repository);
    });
