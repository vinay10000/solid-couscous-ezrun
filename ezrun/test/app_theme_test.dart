import 'package:ezrun/core/theme/app_semantic_colors.dart';
import 'package:ezrun/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildDarkTheme has semantic extension and dark brightness', () {
    final theme = AppTheme.buildDarkTheme();
    expect(theme.brightness, Brightness.dark);
    final ext = theme.extension<AppSemanticColors>();
    expect(ext, isNotNull);
    expect(ext!.surfaceBase, isNot(equals(Colors.transparent)));
  });

  test('buildLightTheme has semantic extension and light brightness', () {
    final theme = AppTheme.buildLightTheme();
    expect(theme.brightness, Brightness.light);
    final ext = theme.extension<AppSemanticColors>();
    expect(ext, isNotNull);
    expect(ext!.surfaceBase, isNot(equals(Colors.transparent)));
  });
}
