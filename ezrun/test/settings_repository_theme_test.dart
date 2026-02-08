import 'package:ezrun/features/profile/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists display theme preference', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final repository = SettingsRepository(prefs);

    expect(repository.getDisplayThemePreference(), 'dark');

    await repository.setDisplayThemePreference('light');
    expect(repository.getDisplayThemePreference(), 'light');

    await repository.setDisplayThemePreference('system');
    expect(repository.getDisplayThemePreference(), 'system');
  });
}
