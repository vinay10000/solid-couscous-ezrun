import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Reusable Error Dialog Widget
/// Displays error messages in a consistent, user-friendly format
/// Features expandable technical details section for debugging
class ErrorDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? technicalDetails;
  final String? actionButtonLabel;
  final VoidCallback? onActionPressed;
  final bool isDismissible;

  const ErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.technicalDetails,
    this.actionButtonLabel,
    this.onActionPressed,
    this.isDismissible = true,
  });

  @override
  State<ErrorDialog> createState() => _ErrorDialogState();
}

class _ErrorDialogState extends State<ErrorDialog>
    with SingleTickerProviderStateMixin {
  bool _showTechnicalDetails = false;
  late AnimationController _iconAnimationController;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _iconAnimation = CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.elasticOut,
    );
    _iconAnimationController.forward();
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _copyTechnicalDetails() {
    if (widget.technicalDetails != null) {
      Clipboard.setData(ClipboardData(text: widget.technicalDetails!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Technical details copied to clipboard'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSizes.lg),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Error Icon
            ScaleTransition(
              scale: _iconAnimation,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Title
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),

            // User-friendly Message
            Text(
              widget.message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),

            // Technical Details Section (if available)
            if (widget.technicalDetails != null &&
                widget.technicalDetails!.isNotEmpty) ...[
              _buildTechnicalDetailsToggle(),
              const SizedBox(height: AppSizes.md),
            ],

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalDetailsToggle() {
    return Column(
      children: [
        // Toggle Button
        GestureDetector(
          onTap: () {
            setState(() {
              _showTechnicalDetails = !_showTechnicalDetails;
            });
            HapticFeedback.lightImpact();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.glassLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: AppColors.glassBorderSubtle,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.code_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  _showTechnicalDetails
                      ? 'Hide Technical Details'
                      : 'Show Technical Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                AnimatedRotation(
                  turns: _showTechnicalDetails ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable Technical Details
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _showTechnicalDetails
              ? Container(
                  margin: const EdgeInsets.only(top: AppSizes.md),
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: AppColors.glassBorderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Technical Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: _copyTechnicalDetails,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.glassLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      SelectableText(
                        widget.technicalDetails!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.isDismissible)
          Expanded(
            child: _buildButton(
              label: 'Dismiss',
              onPressed: () => Navigator.of(context).pop(),
              isPrimary: false,
            ),
          ),
        if (widget.isDismissible && widget.actionButtonLabel != null)
          const SizedBox(width: AppSizes.md),
        if (widget.actionButtonLabel != null)
          Expanded(
            child: _buildButton(
              label: widget.actionButtonLabel!,
              onPressed: () {
                Navigator.of(context).pop();
                widget.onActionPressed?.call();
              },
              isPrimary: true,
            ),
          ),
        if (!widget.isDismissible && widget.actionButtonLabel == null)
          Expanded(
            child: _buildButton(
              label: 'OK',
              onPressed: () => Navigator.of(context).pop(),
              isPrimary: true,
            ),
          ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.md,
          horizontal: AppSizes.lg,
        ),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.error
              : AppColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: isPrimary
              ? null
              : Border.all(
                  color: AppColors.glassBorderLight,
                  width: 1,
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
