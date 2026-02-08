import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/liquid_glass.dart';
import '../../../../core/widgets/liquid_glass_text_field.dart';
import '../state/widget_config_controller.dart';
import '../widgets/color_theme_selector.dart';
import '../widgets/widget_preview_card.dart';
import '../../data/models/widget_config.dart';

class WidgetConfigScreen extends ConsumerStatefulWidget {
  const WidgetConfigScreen({super.key});

  @override
  ConsumerState<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends ConsumerState<WidgetConfigScreen> {
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;

  @override
  void initState() {
    super.initState();
    final config = ref.read(widgetConfigControllerProvider).config;
    _titleController = TextEditingController(text: config.title);
    _subtitleController = TextEditingController(text: config.subtitle);

    ref.listen<WidgetConfigState>(widgetConfigControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.config.title != next.config.title &&
          _titleController.text != next.config.title) {
        _titleController.text = next.config.title;
      }
      if (previous?.config.subtitle != next.config.subtitle &&
          _subtitleController.text != next.config.subtitle) {
        _subtitleController.text = next.config.subtitle;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widgetConfigControllerProvider);
    final controller = ref.read(widgetConfigControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Home Screen Widget',
          style: TextStyle(
            color: AppColors.textPrimary,
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
            const Text(
              'Days Counter',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Customize your glass widget and pin it to the home screen.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: AppSizes.lg),
            const Text(
              'LIVE PREVIEW',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            WidgetPreviewCard(config: state.config),
            const SizedBox(height: AppSizes.xl),
            _sectionHeader('Goal Date'),
            LiquidGlass(
              blur: AppSizes.blurLight,
              backgroundColor: AppColors.glassDark,
              borderColor: AppColors.glassBorderSubtle,
              borderRadius: AppSizes.radiusLg,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.md,
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: AppColors.textSecondary),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Text(
                      DateFormat.yMMMMd().format(state.config.goalDate),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GlassButton(
                    text: 'Pick Date',
                    width: 120,
                    height: 40,
                    onPressed: () => _selectDate(context, controller),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            _sectionHeader('Text'),
            LiquidGlassTextField(
              label: 'Title',
              hint: 'DAYS TO',
              controller: _titleController,
              onChanged: controller.updateTitle,
            ),
            const SizedBox(height: AppSizes.md),
            LiquidGlassTextField(
              label: 'Subtitle',
              hint: 'Your next goal',
              controller: _subtitleController,
              onChanged: controller.updateSubtitle,
            ),
            const SizedBox(height: AppSizes.xl),
            _sectionHeader('Theme'),
            ColorThemeSelector(
              selected: state.config.themeColor,
              onChanged: controller.updateTheme,
            ),
            const SizedBox(height: AppSizes.xl),
            _sectionHeader('Text Size'),
            _TextSizeSelector(
              selected: state.config.textSize,
              onChanged: controller.updateTextSize,
            ),
            const SizedBox(height: AppSizes.xl),
            GradientButton(
              text: 'Save & Update Widget',
              isLoading: state.isSaving,
              icon: Icons.save_outlined,
              onPressed: state.isSaving
                  ? null
                  : () async {
                      await controller.saveConfig();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Widget settings saved')),
                      );
                    },
            ),
            const SizedBox(height: AppSizes.md),
            GlassButton(
              text: state.widgetExists
                  ? 'Widget Already Added'
                  : 'Add to Home Screen',
              icon: Icons.widgets_outlined,
              isLoading: state.isRequestingPin,
              onPressed: state.widgetExists || state.isRequestingPin
                  ? null
                  : () async {
                      await controller.saveConfig();
                      final result = await controller.requestPinWidget();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result
                                ? 'Widget pin request sent'
                                : 'Pinning is not supported on this device',
                          ),
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    WidgetConfigController controller,
  ) async {
    final state = ref.read(widgetConfigControllerProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.config.goalDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.backgroundSecondary,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: AppColors.backgroundSecondary,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      controller.updateGoalDate(picked);
    }
  }
}

class _TextSizeSelector extends StatelessWidget {
  final WidgetTextSize selected;
  final ValueChanged<WidgetTextSize> onChanged;

  const _TextSizeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.md,
      children: WidgetTextSize.values.map((size) {
        final isSelected = size == selected;
        final label = switch (size) {
          WidgetTextSize.small => 'Small',
          WidgetTextSize.medium => 'Medium',
          WidgetTextSize.large => 'Large',
        };
        return GestureDetector(
          onTap: () => onChanged(size),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.glassLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.glassBorderSubtle,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
