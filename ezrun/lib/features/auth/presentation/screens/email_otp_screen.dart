import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/error_handler.dart';
import '../widgets/auth_components.dart';

class EmailOtpArgs {
  final String email;
  final String? password;
  final bool isSignUp;

  const EmailOtpArgs({
    required this.email,
    this.password,
    this.isSignUp = false,
  });
}

/// OTP verification screen (matches screenshot #3 styling).
class EmailOtpScreen extends StatefulWidget {
  final EmailOtpArgs args;

  const EmailOtpScreen({super.key, required this.args});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen>
    with SingleTickerProviderStateMixin {
  // Backend sends 6-digit codes.
  static const int _otpLength = 6;
  static const Duration _resendCooldown = Duration(seconds: 30);

  final AuthService _authService = AuthService();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;
  DateTime? _nextResendAllowedAt;
  Timer? _ticker;
  late final AnimationController _entryController;
  late final Animation<double> _headerAnim;
  late final Animation<double> _otpAnim;
  late final Animation<double> _keyboardAnim;
  late final Animation<double> _actionsAnim;

  String get _otp => _otpController.text;

  bool get _canResend {
    final next = _nextResendAllowedAt;
    if (next == null) return true;
    return DateTime.now().isAfter(next);
  }

  int get _secondsLeft {
    final next = _nextResendAllowedAt;
    if (next == null) return 0;
    return next.difference(DateTime.now()).inSeconds.clamp(0, 9999);
  }

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _headerAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );
    _otpAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    );
    _keyboardAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.35, 0.82, curve: Curves.easeOutCubic),
    );
    _actionsAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _entryController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Only tick while cooldown active.
      if (_canResend) {
        _ticker?.cancel();
        _ticker = null;
      }
      setState(() {});
    });
  }

  Future<void> _resendOtp() async {
    if (_isResending || !_canResend) return;
    setState(() {
      _isResending = true;
      _nextResendAllowedAt = DateTime.now().add(_resendCooldown);
    });
    _ensureTicker();

    try {
      await _authService.sendEmailOtp(email: widget.args.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your email.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.handleException(context, e, title: 'OTP Failed');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != _otpLength || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _authService.verifyEmailOtp(email: widget.args.email, otp: _otp);

      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.handleException(context, e, title: 'OTP Failed');
      HapticFeedback.heavyImpact();
      _otpController.clear();
      setState(() {});
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _appendDigit(String digit) {
    if (_isLoading || _otp.length >= _otpLength) return;
    final nextOtp = '$_otp$digit';
    _otpController.value = TextEditingValue(
      text: nextOtp,
      selection: TextSelection.collapsed(offset: nextOtp.length),
    );
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _removeDigit() {
    if (_isLoading || _otp.isEmpty) return;
    final nextOtp = _otp.substring(0, _otp.length - 1);
    _otpController.value = TextEditingValue(
      text: nextOtp,
      selection: TextSelection.collapsed(offset: nextOtp.length),
    );
    HapticFeedback.selectionClick();
    setState(() {});
  }

  Widget _animateIn({
    required Widget child,
    required Animation<double> animation,
    double yOffset = 12,
  }) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, builtChild) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * yOffset),
            child: builtChild,
          ),
        );
      },
    );
  }

  Widget _buildDigitKey(String digit) {
    return _buildKeyButton(
      onTap: () => _appendDigit(digit),
      child: Text(
        digit,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildKeyButton({
    required Widget child,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final isEnabled = enabled && onTap != null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: _OtpKeyButton(
          onTap: isEnabled ? onTap : null,
          enabled: isEnabled,
          child: child,
        ),
      ),
    );
  }

  Widget _buildCustomKeyboard() {
    return Column(
      children: [
        Row(
          children: [
            _buildDigitKey('1'),
            _buildDigitKey('2'),
            _buildDigitKey('3'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildDigitKey('4'),
            _buildDigitKey('5'),
            _buildDigitKey('6'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildDigitKey('7'),
            _buildDigitKey('8'),
            _buildDigitKey('9'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildKeyButton(child: const SizedBox.shrink(), enabled: false),
            _buildDigitKey('0'),
            _buildKeyButton(
              onTap: _otp.isNotEmpty ? _removeDigit : null,
              child: Icon(
                Icons.backspace_rounded,
                color: _otp.isNotEmpty
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.args.email;
    final canContinue = _otp.length == _otpLength && !_isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundSecondary,
              AppColors.background,
              Colors.black,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            child: Column(
              children: [
                AuthTopBar(
                  title: '',
                  onBack: () => context.pop(),
                  foreground: AppColors.textPrimary,
                ),
                const SizedBox(height: 16),
                _animateIn(
                  animation: _headerAnim,
                  child: Column(
                    children: [
                      const Text(
                        'Enter OTP',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We have just sent you $_otpLength digit code via\nyour email $email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                _animateIn(
                  animation: _otpAnim,
                  yOffset: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_otpLength, (i) {
                      final filled = i < _otp.length;
                      final isActive =
                          i == _otp.length && _otp.length < _otpLength;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: AnimatedScale(
                          scale: filled ? 1 : 0.94,
                          duration: const Duration(milliseconds: 170),
                          curve: Curves.easeOutCubic,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: filled
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryLight,
                                      ],
                                    )
                                  : null,
                              border: Border.all(
                                color: filled
                                    ? AppColors.primary.withValues(alpha: 0.6)
                                    : AppColors.glassBorderLight,
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                switchInCurve: Curves.easeOutBack,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: filled
                                    ? Container(
                                        key: ValueKey('filled-$i'),
                                        width: 9,
                                        height: 9,
                                        decoration: const BoxDecoration(
                                          color: AppColors.textPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : AnimatedOpacity(
                                        key: ValueKey('empty-$i-$isActive'),
                                        opacity: isActive ? 1 : 0,
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        child: Container(
                                          width: 2,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: AppColors.textPrimary
                                                .withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 26),
                _animateIn(
                  animation: _keyboardAnim,
                  yOffset: 14,
                  child: _buildCustomKeyboard(),
                ),
                const SizedBox(height: 26),
                _animateIn(
                  animation: _actionsAnim,
                  yOffset: 10,
                  child: AnimatedScale(
                    scale: canContinue ? 1 : 0.985,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: canContinue ? 1 : 0.92,
                      duration: const Duration(milliseconds: 180),
                      child: AuthPillButton(
                        text: 'Continue',
                        onPressed: canContinue ? _verifyOtp : null,
                        isLoading: _isLoading,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _animateIn(
                  animation: _actionsAnim,
                  yOffset: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive code? ",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      TextButton(
                        onPressed: (_canResend && !_isResending)
                            ? _resendOtp
                            : null,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            _canResend
                                ? 'Resend Code'
                                : 'Resend in ${_secondsLeft}s',
                            key: ValueKey(
                              _canResend ? 'resend-ready' : _secondsLeft,
                            ),
                            style: TextStyle(
                              color: _canResend
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: _canResend
                                  ? AppColors.primary.withValues(alpha: 0.45)
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpKeyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const _OtpKeyButton({
    required this.child,
    required this.onTap,
    required this.enabled,
  });

  @override
  State<_OtpKeyButton> createState() => _OtpKeyButtonState();
}

class _OtpKeyButtonState extends State<_OtpKeyButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && widget.onTap != null;
    final borderColor = isEnabled
        ? (_pressed
              ? AppColors.primary.withValues(alpha: 0.42)
              : AppColors.glassBorderLight)
        : Colors.transparent;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isEnabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _pressed
                      ? [
                          AppColors.primary.withValues(alpha: 0.14),
                          AppColors.glassDark,
                        ]
                      : [AppColors.glassMedium, AppColors.glassDark],
                )
              : null,
          border: Border.all(color: borderColor),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            onTapDown: isEnabled ? (_) => _setPressed(true) : null,
            onTapUp: isEnabled ? (_) => _setPressed(false) : null,
            onTapCancel: isEnabled ? () => _setPressed(false) : null,
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
