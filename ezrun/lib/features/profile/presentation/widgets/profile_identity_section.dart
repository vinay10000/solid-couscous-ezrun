import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class ProfileIdentitySection extends StatelessWidget {
  final String username;
  final String? profileImageUrl;
  final bool isUploadingImage;
  final bool isUpdatingUsername;
  final VoidCallback onChangePicture;
  final VoidCallback onEditUsername;

  const ProfileIdentitySection({
    super.key,
    required this.username,
    required this.profileImageUrl,
    required this.isUploadingImage,
    required this.isUpdatingUsername,
    required this.onChangePicture,
    required this.onEditUsername,
  });

  void _onProfileImageTap(BuildContext context) {
    final queryParams = {
      if (profileImageUrl != null) 'imageUrl': profileImageUrl!,
      'username': username,
      'canDelete': '1',
    };

    context.push(
      Uri(
        path: '/profile-image-viewer',
        queryParameters: queryParams,
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Avatar with gradient background or custom image
              GestureDetector(
                onTap: () => _onProfileImageTap(context),
                child: Hero(
                  tag: 'profile_image_$profileImageUrl',
                  child: Container(
                    width: AppSizes.avatarXl,
                    height: AppSizes.avatarXl,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.primaryGlow,
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      child: profileImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: profileImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 48,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 48,
                            ),
                    ),
                  ),
                ),
              ),

              // Camera button overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: isUploadingImage ? null : onChangePicture,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.secondary, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(color: AppColors.background, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.secondaryGlow,
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: isUploadingImage
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          InkWell(
            onTap: isUpdatingUsername ? null : onEditUsername,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isUpdatingUsername
                        ? const SizedBox(
                            key: ValueKey('updating'),
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.edit,
                            key: ValueKey('edit'),
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
        ],
      ),
    );
  }
}
