import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSignOut;
  final VoidCallback? onSettings;

  const ProfileHeader({
    super.key,
    this.onBack,
    this.onSignOut,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final hasBack = onBack != null;
    return Row(
      children: [
        if (hasBack)
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.textPrimary,
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              AppStrings.navProfile,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        const Spacer(),
        if (onSettings != null)
          IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
          ),
        if (onSignOut != null)
          IconButton(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
          ),
      ],
    );
  }
}
