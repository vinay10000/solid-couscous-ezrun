import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Reusable Error Dialog Widget
/// Displays error messages in a consistent, user-friendly format
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? actionButtonLabel;
  final VoidCallback? onActionPressed;
  final bool isDismissible;

  const ErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.actionButtonLabel,
    this.onActionPressed,
    this.isDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSizes.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),

            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),

            // Action Buttons
            Row(
              children: [
                if (isDismissible)
                  Expanded(
                    child: _buildButton(
                      label: 'Dismiss',
                      onPressed: () => Navigator.of(context).pop(),
                      isPrimary: false,
                    ),
                  ),
                if (isDismissible && actionButtonLabel != null)
                  const SizedBox(width: AppSizes.md),
                if (actionButtonLabel != null)
                  Expanded(
                    child: _buildButton(
                      label: actionButtonLabel!,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onActionPressed?.call();
                      },
                      isPrimary: true,
                    ),
                  ),
                if (!isDismissible && actionButtonLabel == null)
                  Expanded(
                    child: _buildButton(
                      label: 'OK',
                      onPressed: () => Navigator.of(context).pop(),
                      isPrimary: true,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.md,
          horizontal: AppSizes.lg,
        ),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.error
              : AppColors.backgroundTertiary ?? Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
