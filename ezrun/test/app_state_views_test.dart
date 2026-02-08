import 'package:ezrun/core/theme/app_theme.dart';
import 'package:ezrun/core/widgets/app_state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppEmptyState renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildLightTheme(),
        darkTheme: AppTheme.buildDarkTheme(),
        home: const Scaffold(
          body: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No data',
            subtitle: 'Nothing to show right now.',
          ),
        ),
      ),
    );

    expect(find.text('No data'), findsOneWidget);
    expect(find.text('Nothing to show right now.'), findsOneWidget);
  });
}
