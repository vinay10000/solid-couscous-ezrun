import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/state/ui_visibility_providers.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/widgets/profile_theme_background.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_identity_section.dart';
import '../widgets/profile_stats_section.dart';
import '../widgets/profile_social_counts_row.dart';
import '../widgets/level_progress_card.dart';
import '../state/settings_controller.dart';
import '../../data/providers/level_providers.dart';
import '../../../runs/presentation/widgets/add_custom_run_sheet.dart';

/// Profile Screen - User profile with stats and settings
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploadingImage = false;
  bool _isUpdatingUsername = false;
  String _username = 'Runner';

  @override
  void initState() {
    super.initState();
    _syncUsernameFromAuth();
  }

  void _syncUsernameFromAuth() {
    final user = _authService.currentUser;
    final username = (user?.displayUsername?.trim().isNotEmpty == true)
        ? user!.displayUsername!.trim()
        : (user?.username?.trim().isNotEmpty == true)
        ? user!.username!.trim()
        : user?.name.trim();
    setState(() {
      _username = (username == null || username.isEmpty) ? 'Runner' : username;
    });
  }

  Future<File?> _editProfileImage(String sourcePath) async {
    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Profile Picture',
          toolbarColor: AppColors.backgroundSecondary,
          toolbarWidgetColor: AppColors.textPrimary,
          backgroundColor: AppColors.background,
          activeControlsWidgetColor: AppColors.primary,
          hideBottomControls: false,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
          initAspectRatio: CropAspectRatioPreset.square,
        ),
        IOSUiSettings(
          title: 'Edit Profile Picture',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        WebUiSettings(context: context, presentStyle: WebPresentStyle.dialog),
      ],
    );

    if (croppedFile == null) return null;
    return File(croppedFile.path);
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;
      final File? imageFile = await _editProfileImage(pickedFile.path);
      if (imageFile == null) return;

      if (mounted) {
        setState(() => _isUploadingImage = true);
      }

      // Validate image
      _imageUploadService.validateImage(imageFile);

      // Upload to ImageKit
      final imageUrl = await _imageUploadService.uploadImage(
        imageFile,
        fileName: pickedFile.name,
      );

      // Update user metadata in Supabase
      await _authService.updateProfilePicture(imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh the UI
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile picture: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _showEditUsernameDialog() async {
    final controller = TextEditingController(text: _username);

    final next = await showDialog<String>(
      context: context,
      builder: (context) {
        String draft = controller.text;

        bool canSave(String v) {
          final trimmed = v.trim();
          if (trimmed.isEmpty) return false;
          if (trimmed.length > 32) return false;
          return trimmed != _username;
        }

        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            backgroundColor: AppColors.backgroundSecondary,
            title: const Text(
              'Edit name',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 32,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                counterStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                hintText: 'Your name',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              onChanged: (v) => setLocalState(() => draft = v),
              onSubmitted: (v) {
                if (!canSave(v)) return;
                Navigator.of(context).pop(v);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: canSave(draft)
                    ? () => Navigator.of(context).pop(draft)
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  disabledForegroundColor: AppColors.textSecondary.withValues(
                    alpha: 0.5,
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (next == null) return;
    await _updateUsername(next);
  }

  Future<void> _updateUsername(String next) async {
    final trimmed = next.trim();
    if (trimmed.isEmpty || trimmed == _username) return;

    final previous = _username;
    setState(() {
      _username = trimmed;
      _isUpdatingUsername = true;
    });

    try {
      await _authService.updateUsername(trimmed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name updated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (_authService.isProfileNameSyncWarning(e)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e
                    .toString()
                    .replaceFirst('Exception: ', '')
                    .replaceFirst(
                      'PROFILE_NAME_SYNC_WARNING:',
                      'Name updated, but public profile may take a moment to sync:',
                    ),
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        } else {
          setState(() => _username = previous);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to update name: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingUsername = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: const Text(
          'Choose Image Source',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text(
                'Camera',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
              title: const Text(
                'Gallery',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: const Text(
          AppStrings.signOutConfirmTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          AppStrings.signOutConfirm,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          context.go('/sign-in');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error signing out: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final profileImageUrl = _authService.getProfilePictureUrl();
    final profileThemeEnabled = ref
        .watch(settingsControllerProvider)
        .profileThemeEnabled;

    return Scaffold(
      body: Stack(
        children: [
          ProfileThemeBackground(enabled: profileThemeEnabled),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.lg,
                AppSizes.lg,
                AppSizes.lg + AppSizes.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeader(
                    onSignOut: _signOut,
                    onSettings: () => context.pushNamed('settings'),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  ProfileIdentitySection(
                    username: _username,
                    profileImageUrl: profileImageUrl,
                    isUploadingImage: _isUploadingImage,
                    isUpdatingUsername: _isUpdatingUsername,
                    onChangePicture: _showImageSourceDialog,
                    onEditUsername: _showEditUsernameDialog,
                  ),
                  const SizedBox(height: AppSizes.md),
                  if (user != null) ProfileSocialCountsRow(userId: user.id),
                  const SizedBox(height: AppSizes.xl),
                  Consumer(
                    builder: (context, ref, child) {
                      final levelAsync = ref.watch(userLevelProvider);
                      return levelAsync.when(
                        data: (level) => LevelProgressCard(
                          userLevel: level,
                          onLevelTap: () => context.pushNamed(
                            'levelBenefits',
                            pathParameters: {
                              'currentLevel': level.currentLevel.toString(),
                            },
                          ),
                        ),
                        loading: () => Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  const ProfileStatsSection(),
                  const SizedBox(height: AppSizes.xxl),
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(AppSizes.sm),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.edit_road_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Add custom run',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Log distance, duration, and a note',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () async {
                        ref.read(bottomNavVisibleProvider.notifier).state =
                            false;
                        try {
                          await AddCustomRunSheet.show(context);
                        } finally {
                          ref.read(bottomNavVisibleProvider.notifier).state =
                              true;
                        }
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.xxl),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(AppSizes.sm),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.emoji_events,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Achievements',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.pushNamed('achievements'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(AppSizes.sm),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.notifications,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        AppStrings.notifications,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => context.pushNamed('notifications'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
