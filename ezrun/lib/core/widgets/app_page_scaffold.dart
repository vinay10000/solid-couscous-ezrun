import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../theme/app_semantic_colors.dart';

class AppPageScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final bool safeArea;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradientColors;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  const AppPageScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.safeArea = true,
    this.scrollable = false,
    this.padding = const EdgeInsets.all(AppSizes.lg),
    this.gradientColors,
    this.floatingActionButtonLocation,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final defaults = <Color>[colors.surfaceRaised, colors.surfaceBase];

    Widget body = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors ?? defaults,
        ),
      ),
      child: scrollable
          ? SingleChildScrollView(padding: padding, child: child)
          : Padding(padding: padding, child: child),
    );

    if (safeArea) {
      body = SafeArea(child: body);
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      extendBody: extendBody,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
