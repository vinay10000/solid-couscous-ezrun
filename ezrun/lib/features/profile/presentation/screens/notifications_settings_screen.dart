import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../state/settings_controller.dart';
import '../widgets/profile_settings_item.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

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
          'Notifications',
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
          children: [
            _buildSwitchItem(
              'Push Notifications',
              'Master toggle for all push notifications',
              settingsState.notifications['push'] ?? true,
              (val) => controller.updateAllNotifications(val),
            ),
            const Divider(color: AppColors.textMuted),
            _buildSwitchItem(
              'Follow Requests',
              'When someone asks to follow you',
              settingsState.notifications['follows'] ?? true,
              (val) => controller.toggleNotification('follows'),
            ),
            _buildSwitchItem(
              'Achievements',
              'When you earn a new achievement',
              settingsState.notifications['achievements'] ?? true,
              (val) => controller.toggleNotification('achievements'),
            ),
            _buildSwitchItem(
              'Social Activity',
              'Likes, comments, and mentions',
              settingsState.notifications['social'] ?? true,
              (val) => controller.toggleNotification('social'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ProfileSettingsItem(
      title: title,
      subtitle: subtitle,
      icon: Icons.notifications_active_outlined,
      showArrow: false,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}
