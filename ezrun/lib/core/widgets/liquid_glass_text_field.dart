import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Liquid Glass text input field
class LiquidGlassTextField extends StatelessWidget {
  /// Optional label above the field
  final String? label;

  /// Hint text inside the field
  final String? hint;

  /// Text controller
  final TextEditingController? controller;

  /// Whether to obscure text (for passwords)
  final bool obscureText;

  /// Leading icon
  final IconData? prefixIcon;

  /// Trailing widget (e.g., visibility toggle)
  final Widget? suffix;

  /// Validation function
  final String? Function(String?)? validator;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Callback when submitted
  final void Function(String)? onSubmitted;

  /// Callback on text change
  final void Function(String)? onChanged;

  /// Auto-focus
  final bool autofocus;

  /// Enabled state
  final bool enabled;

  const LiquidGlassTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Input field with glass effect
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              validator: validator,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onFieldSubmitted: onSubmitted,
              onChanged: onChanged,
              autofocus: autofocus,
              enabled: enabled,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.glassLight,
                prefixIcon: prefixIcon != null
                    ? Icon(prefixIcon, color: AppColors.textSecondary, size: 22)
                    : null,
                suffixIcon: suffix,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  borderSide: const BorderSide(
                    color: AppColors.glassBorderSubtle,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  borderSide: const BorderSide(
                    color: AppColors.glassBorderSubtle,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  borderSide: const BorderSide(
                    color: AppColors.glassBorderSubtle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Password field with visibility toggle
class LiquidGlassPasswordField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const LiquidGlassPasswordField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<LiquidGlassPasswordField> createState() =>
      _LiquidGlassPasswordFieldState();
}

class _LiquidGlassPasswordFieldState extends State<LiquidGlassPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassTextField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      obscureText: _obscureText,
      prefixIcon: Icons.lock_outline,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      suffix: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textMuted,
          size: 22,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}
