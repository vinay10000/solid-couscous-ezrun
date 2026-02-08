import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../widgets/profile_settings_item.dart';
import '../state/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '...';
  String _cacheSize = '0 MB';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _calculateCacheSize();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = '${info.version} (${info.buildNumber})';
      });
    }
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int sizeBytes = 0;
      await for (var file in tempDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (file is File) {
          sizeBytes += await file.length();
        }
      }
      if (mounted) {
        setState(() {
          _cacheSize = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        });
      }
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
      await _calculateCacheSize();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
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
            const AppSectionHeader(title: 'Account'),
            ProfileSettingsItem(
              title: 'Account Settings',
              subtitle: 'Password, Units, Blocked Users',
              icon: Icons.person_outline,
              onTap: () => context.pushNamed('accountSettings'),
            ),

            const SizedBox(height: AppSizes.xl),
            const AppSectionHeader(title: 'General'),
            ProfileSettingsItem(
              title: 'Notifications',
              subtitle: 'Push, Social, Updates',
              icon: Icons.notifications_outlined,
              onTap: () => context.pushNamed('notificationSettings'),
            ),
            ProfileSettingsItem(
              title: 'Display & Map',
              subtitle: 'Theme mode, map styles, appearance',
              icon: Icons.map_outlined,
              onTap: () => context.pushNamed('displaySettings'),
            ),
            ProfileSettingsItem(
              title: 'Home Screen Widget',
              subtitle: 'Add days counter to home screen',
              icon: Icons.widgets_outlined,
              onTap: () => context.pushNamed('widgetConfig'),
            ),
            Consumer(
              builder: (context, ref, _) {
                final settings = ref.watch(settingsControllerProvider);
                final controller = ref.read(
                  settingsControllerProvider.notifier,
                );
                return ProfileSettingsItem(
                  title: 'Profile Theme',
                  subtitle: 'Blue/green background effect',
                  icon: Icons.palette_outlined,
                  iconColor: AppColors.territoryUser,
                  showArrow: false,
                  trailing: Switch(
                    value: settings.profileThemeEnabled,
                    onChanged: controller.setProfileThemeEnabled,
                  ),
                );
              },
            ),
            ProfileSettingsItem(
              title: 'Data & Privacy',
              subtitle: 'Export data',
              icon: Icons.data_usage,
              onTap: () => context.pushNamed('dataPrivacySettings'),
            ),

            const SizedBox(height: AppSizes.xl),
            const AppSectionHeader(title: 'App Information'),
            ProfileSettingsItem(
              title: 'App Version',
              subtitle: _version,
              icon: Icons.info_outline,
              showArrow: false,
            ),
            ProfileSettingsItem(
              title: 'Clear Cache',
              subtitle: _cacheSize,
              icon: Icons.cleaning_services_outlined,
              onTap: _clearCache,
            ),
            ProfileSettingsItem(
              title: 'Help & Support',
              icon: Icons.help_outline,
              onTap: () {
                // Navigate to help page or website
              },
            ),
            ProfileSettingsItem(
              title: 'Terms of Service',
              icon: Icons.description_outlined,
              onTap: () => _launchUrl('https://ezrun.app/terms'),
            ),
            ProfileSettingsItem(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip_outlined,
              onTap: () => _launchUrl('https://ezrun.app/privacy'),
            ),
            ProfileSettingsItem(
              title: 'About EZRUN',
              icon: Icons.run_circle_outlined,
              onTap: () {
                // Show about dialog
                showAboutDialog(
                  context: context,
                  applicationName: 'EZRUN',
                  applicationVersion: _version,
                  applicationIcon: Image.asset(
                    'assets/images/app_icon.png',
                    width: 48,
                    height: 48,
                    errorBuilder: (_, __, ___) => const Icon(Icons.run_circle),
                  ),
                  children: const [
                    Text(
                      'EZRUN is a gamified running application with territory capture features.',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
