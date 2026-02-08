import 'package:ezrun/features/profile/presentation/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemePreference', () {
    test('fromStorage maps values', () {
      expect(ThemePreference.fromStorage('dark'), ThemePreference.dark);
      expect(ThemePreference.fromStorage('light'), ThemePreference.light);
      expect(ThemePreference.fromStorage('system'), ThemePreference.system);
      expect(ThemePreference.fromStorage('unknown'), ThemePreference.dark);
      expect(ThemePreference.fromStorage(null), ThemePreference.dark);
    });

    test('toThemeMode maps enum values', () {
      expect(ThemePreference.dark.toThemeMode(), ThemeMode.dark);
      expect(ThemePreference.light.toThemeMode(), ThemeMode.light);
      expect(ThemePreference.system.toThemeMode(), ThemeMode.system);
    });

    test('storageValue uses enum names', () {
      expect(ThemePreference.dark.storageValue, 'dark');
      expect(ThemePreference.light.storageValue, 'light');
      expect(ThemePreference.system.storageValue, 'system');
    });
  });
}
