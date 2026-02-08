import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'gradient_button.dart';

/// Shows the "Email Verified" popup as a bottom sheet.
///
/// Uses `assets/images/email_verified.png` for the illustration (with a safe
/// fallback if the asset is missing).
Future<void> showEmailVerifiedBottomSheet(
  BuildContext context, {
  VoidCallback? onDone,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: const Color(0x00000000),
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) {
      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(AppSizes.md),
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.md,
              AppSizes.lg,
              AppSizes.lg,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                SizedBox(
                  height: 140,
                  child: Image.asset(
                    'assets/images/email_verified.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.mark_email_read_outlined,
                      size: 96,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                const Text(
                  'Email Verified',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                const Text(
                  'Your email address has been successfully verified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: AppSizes.lg),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: 'Done',
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onDone?.call();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
