import 'package:ezrun/core/theme/app_theme.dart';
import 'package:ezrun/core/widgets/app_state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'golden scaffold: empty state dark and light',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.buildLightTheme(),
          darkTheme: AppTheme.buildDarkTheme(),
          home: const Scaffold(
            body: AppEmptyState(
              icon: Icons.image_not_supported_outlined,
              title: 'Placeholder',
              subtitle: 'Golden baseline scaffold.',
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('ui_golden_empty_state.png'),
      );
    },
    // Scaffolding only; baseline generation is explicit via --update-goldens.
    skip: true,
  );
}
