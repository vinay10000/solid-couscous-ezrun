import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../state/settings_controller.dart';

class DisplaySettingsScreen extends ConsumerWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final colors = context.semanticColors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Display & Map',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(title: 'Theme'),
            AppGlassCard(
              child: Column(
                children: [
                  _buildThemeChoice(
                    context: context,
                    title: 'Dark',
                    value: ThemePreference.dark,
                    groupValue: settingsState.themePreference,
                    onChanged: controller.setThemePreference,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _buildThemeChoice(
                    context: context,
                    title: 'Light',
                    value: ThemePreference.light,
                    groupValue: settingsState.themePreference,
                    onChanged: controller.setThemePreference,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _buildThemeChoice(
                    context: context,
                    title: 'System',
                    value: ThemePreference.system,
                    groupValue: settingsState.themePreference,
                    onChanged: controller.setThemePreference,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            const AppSectionHeader(title: 'Map Style'),
            AppGlassCard(
              child: Column(
                children: [
                  _buildMapChoice(
                    context: context,
                    title: 'Standard',
                    value: 'mapbox://styles/mapbox/streets-v11',
                    groupValue: settingsState.mapStyle,
                    onChanged: controller.setMapStyle,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _buildMapChoice(
                    context: context,
                    title: 'Satellite',
                    value: 'mapbox://styles/mapbox/satellite-v9',
                    groupValue: settingsState.mapStyle,
                    onChanged: controller.setMapStyle,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _buildMapChoice(
                    context: context,
                    title: 'Dark',
                    value: 'mapbox://styles/mapbox/dark-v10',
                    groupValue: settingsState.mapStyle,
                    onChanged: controller.setMapStyle,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _buildMapChoice(
                    context: context,
                    title: 'Light',
                    value: 'mapbox://styles/mapbox/light-v10',
                    groupValue: settingsState.mapStyle,
                    onChanged: controller.setMapStyle,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _buildMapChoice(
                    context: context,
                    title: 'Outdoors',
                    value: 'mapbox://styles/mapbox/outdoors-v11',
                    groupValue: settingsState.mapStyle,
                    onChanged: controller.setMapStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChoice({
    required BuildContext context,
    required String title,
    required ThemePreference value,
    required ThemePreference groupValue,
    required ValueChanged<ThemePreference> onChanged,
  }) {
    final colors = context.semanticColors;
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentPrimary.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? colors.accentPrimary : colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? colors.accentPrimary : colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapChoice({
    required BuildContext context,
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String> onChanged,
  }) {
    final colors = context.semanticColors;
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentPrimary.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? colors.accentPrimary : colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? colors.accentPrimary : colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
