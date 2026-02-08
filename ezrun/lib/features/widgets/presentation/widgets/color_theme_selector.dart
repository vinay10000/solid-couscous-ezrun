import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/models/widget_config.dart';

class WidgetThemeOption {
  final WidgetThemeColor theme;
  final String label;
  final List<Color> colors;

  const WidgetThemeOption({
    required this.theme,
    required this.label,
    required this.colors,
  });
}

const List<WidgetThemeOption> widgetThemeOptions = [
  WidgetThemeOption(
    theme: WidgetThemeColor.blue,
    label: 'Blue',
    colors: [AppColors.primary, AppColors.primaryLight],
  ),
  WidgetThemeOption(
    theme: WidgetThemeColor.purple,
    label: 'Purple',
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
  ),
  WidgetThemeOption(
    theme: WidgetThemeColor.green,
    label: 'Green',
    colors: [AppColors.territoryUser, Color(0xFF00D4A5)],
  ),
  WidgetThemeOption(
    theme: WidgetThemeColor.orange,
    label: 'Orange',
    colors: [Color(0xFFFF8A00), Color(0xFFFFB347)],
  ),
  WidgetThemeOption(
    theme: WidgetThemeColor.pink,
    label: 'Pink',
    colors: [AppColors.secondary, Color(0xFFFF8ACB)],
  ),
  WidgetThemeOption(
    theme: WidgetThemeColor.cyan,
    label: 'Cyan',
    colors: [Color(0xFF00D4FF), Color(0xFF6FE7FF)],
  ),
];

class ColorThemeSelector extends StatelessWidget {
  final WidgetThemeColor selected;
  final ValueChanged<WidgetThemeColor> onChanged;

  const ColorThemeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.md,
      runSpacing: AppSizes.md,
      children: widgetThemeOptions.map((option) {
        final isSelected = option.theme == selected;
        return GestureDetector(
          onTap: () => onChanged(option.theme),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.glassBorderSubtle,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryGlow,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: option.colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                option.label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
