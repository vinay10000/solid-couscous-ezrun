import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_semantic_colors.dart';

class AuthPillButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AuthPillButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final bg = backgroundColor ?? colors.accentPrimary;
    final fg = foregroundColor ?? Theme.of(context).colorScheme.onPrimary;
    final isDisabled = isLoading || onPressed == null;

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withOpacity(0.5),
          disabledForegroundColor: fg.withOpacity(0.6),
          elevation: isDisabled ? 0 : 2,
          shadowColor: colors.shadowSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

class AuthOutlinePillButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Color? foregroundColor;
  final Color? borderColor;
  final Color? backgroundColor;

  const AuthOutlinePillButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.leading,
    this.foregroundColor,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final fg = foregroundColor ?? colors.textPrimary;
    final bg = backgroundColor ?? colors.surfaceGlass;
    final border = borderColor ?? colors.borderStrong;
    final isDisabled = onPressed == null;

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withOpacity(0.6),
          disabledForegroundColor: fg.withOpacity(0.5),
          side: BorderSide(color: border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          elevation: isDisabled ? 0 : 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthTopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final String title;
  final String? trailingText;
  final VoidCallback? onTrailing;
  final Color? foreground;

  const AuthTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailingText,
    this.onTrailing,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final fg = foreground ?? colors.textPrimary;
    return Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: onBack == null
              ? const SizedBox.shrink()
              : IconButton(
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back_ios_new, color: fg, size: 18),
                ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          width: 60,
          height: 44,
          child: Align(
            alignment: Alignment.centerRight,
            child: trailingText == null
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: onTrailing,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      foregroundColor: fg.withOpacity(0.7),
                    ),
                    child: Text(
                      trailingText!,
                      style: TextStyle(
                        color: fg.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colors.textMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(icon, color: colors.textMuted, size: 20),
            suffixIcon: suffix,
            prefixIconColor: colors.textMuted,
            suffixIconColor: colors.textMuted,
            filled: true,
            fillColor: colors.surfaceGlass,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: colors.accentPrimary.withOpacity(0.55),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.error.withOpacity(0.8)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.error.withOpacity(0.9)),
            ),
          ),
        ),
      ],
    );
  }
}
