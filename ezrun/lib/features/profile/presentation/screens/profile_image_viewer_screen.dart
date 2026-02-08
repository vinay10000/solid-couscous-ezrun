import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/image_upload_service.dart';

/// Full-screen profile image viewer with rounded corners
class ProfileImageViewerScreen extends StatefulWidget {
  final String? imageUrl;
  final String username;
  final bool canDelete;

  const ProfileImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.username,
    required this.canDelete,
  });

  @override
  State<ProfileImageViewerScreen> createState() =>
      _ProfileImageViewerScreenState();
}

class _ProfileImageViewerScreenState extends State<ProfileImageViewerScreen> {
  final AuthService _authService = AuthService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  bool _isDeleting = false;

  Future<void> _deleteProfilePicture() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: const Text(
          'Delete Profile Picture',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete your profile picture? This will permanently remove the image from our servers and cannot be undone.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.imageUrl != null) {
      setState(() => _isDeleting = true);

      try {
        // First delete the image from ImageKit
        await _imageUploadService.deleteImage(widget.imageUrl!);

        // Then remove the profile picture URL from user metadata
        await _authService.removeProfilePicture();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture deleted successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate back to profile screen
          context.go('/profile');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete profile picture: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.canDelete && widget.imageUrl != null)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete, color: Colors.white, size: 24),
              onPressed: _isDeleting ? null : _deleteProfilePicture,
              tooltip: 'Delete profile picture',
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => context.pop(),
        child: Center(
          child: widget.imageUrl != null
              ? Hero(
                  tag: 'profile_image_${widget.imageUrl}',
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        24,
                      ), // Smooth rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        24,
                      ), // Smooth rounded corners
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl!,
                        fit: BoxFit
                            .contain, // Use contain to show full image without cropping
                        placeholder: (context, url) => Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.textSecondary,
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 80,
                  ),
                ),
        ),
      ),
    );
  }
}
