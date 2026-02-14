import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/error_handler.dart';

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

/// Email OTP verification screen with in-app numeric keyboard.
class EmailOtpScreen extends StatefulWidget {
  final EmailOtpArgs args;

  const EmailOtpScreen({super.key, required this.args});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen>
    with TickerProviderStateMixin {
  // Keep this in sync with server OTP_LENGTH.
  static const int _otpLength = 6;
  static const Duration _resendCooldown = Duration(seconds: 30);

  final AuthService _authService = AuthService();

  String _otp = '';
  bool _isLoading = false;
  bool _isResending = false;
  DateTime? _nextResendAllowedAt;
  Timer? _ticker;

  late final AnimationController _entry;
  late final AnimationController _ambient;
  late final AnimationController _cursor;
  late final Animation<double> _headerIn;
  late final Animation<double> _slotIn;
  late final Animation<double> _resendIn;
  late final Animation<double> _keyboardIn;

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
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _cursor = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _headerIn = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
    );
    _slotIn = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.18, 0.62, curve: Curves.easeOutCubic),
    );
    _resendIn = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.42, 0.82, curve: Curves.easeOutCubic),
    );
    _keyboardIn = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.32, 1.0, curve: Curves.easeOutCubic),
    );

    _entry.forward();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _entry.dispose();
    _ambient.dispose();
    _cursor.dispose();
    super.dispose();
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
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
      if (widget.args.isSignUp) {
        // Explicit sign-up flow: verify email only (marks emailVerified = true)
        await _authService.verifyEmailOtp(
          email: widget.args.email,
          otp: _otp,
        );
      } else {
        // Passwordless sign-in flow: verify OTP AND create session
        await _authService.signInWithEmailOtp(
          email: widget.args.email,
          otp: _otp,
        );
      }

      if (!mounted) return;
      context.go(
        '/email-otp-success?email=${Uri.encodeQueryComponent(widget.args.email)}',
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.handleException(context, e, title: 'OTP Failed');
      HapticFeedback.heavyImpact();
      setState(() => _otp = '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _appendDigit(String digit) {
    if (_isLoading || _otp.length >= _otpLength) return;

    HapticFeedback.selectionClick();
    setState(() => _otp = '$_otp$digit');

    if (_otp.length == _otpLength) {
      unawaited(_verifyOtp());
    }
  }

  void _removeDigit() {
    if (_isLoading || _otp.isEmpty) return;

    HapticFeedback.selectionClick();
    setState(() => _otp = _otp.substring(0, _otp.length - 1));
  }

  Widget _fadeSlideIn({
    required Widget child,
    required Animation<double> animation,
    double yOffset = 14,
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

  String get _cooldownText => '00:${_secondsLeft.toString().padLeft(2, '0')}';

  Widget _buildOtpSlots() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 48;
        final slotWidth =
            ((availableWidth - ((_otpLength - 1) * gap)) / _otpLength).clamp(
              38.0,
              50.0,
            );
        final slotHeight = slotWidth + 6;
        final digitSize = (slotWidth * 0.5).clamp(19.0, 24.0);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_otpLength, (index) {
            final isFilled = index < _otp.length;
            final isActive = index == _otp.length && _otp.length < _otpLength;
            final borderColor = isFilled || isActive
                ? AppColors.primary
                : AppColors.glassBorderLight;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: gap / 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: slotWidth,
                height: slotHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.glassDark,
                  border: Border.all(
                    color: borderColor.withValues(alpha: isActive ? 1 : 0.5),
                    width: isActive ? 1.5 : 1.2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 18,
                            spreadRadius: -4,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: isFilled
                        ? Text(
                            _otp[index],
                            key: ValueKey<String>(
                              'digit-$index-${_otp[index]}',
                            ),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: digitSize,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : isActive
                        ? FadeTransition(
                            key: ValueKey<String>('cursor-$index'),
                            opacity: _cursor,
                            child: Container(
                              width: 2,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey<String>('empty')),
                  ),
                ),
              ),
            );
            }),
          ),
        );
      },
    );
  }

  Widget _buildDigitKey(String digit) {
    return _buildKeyboardButton(
      onTap: () => _appendDigit(digit),
      child: Text(
        digit,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildKeyboardButton({
    required Widget child,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final isEnabled = enabled && onTap != null;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: _OtpKeyboardKey(
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
            _buildKeyboardButton(
              child: const SizedBox.shrink(),
              enabled: false,
            ),
            _buildDigitKey('0'),
            _buildKeyboardButton(
              onTap: _otp.isNotEmpty ? _removeDigit : null,
              child: Icon(
                Icons.backspace_outlined,
                color: _otp.isNotEmpty
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                size: 28,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.args.email.trim();

    return Scaffold(
      body: AnimatedBuilder(
        animation: _ambient,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.8 + (_ambient.value * 0.2)),
                radius: 1.3,
                colors: const [
                  Color(0xFF111D34),
                  AppColors.background,
                  Color(0xFF020308),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 150 + (_ambient.value * 16),
                    left: 38,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 120 - (_ambient.value * 12),
                    right: 62,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _fadeSlideIn(
                          animation: _headerIn,
                          child: AnimatedBuilder(
                            animation: _ambient,
                            builder: (context, child) {
                              final scale = 1 + (_ambient.value * 0.05);
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF123063),
                                    Color(0xFF0C1E42),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.28,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.26,
                                    ),
                                    blurRadius: 26,
                                    spreadRadius: -10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mark_email_read_outlined,
                                size: 34,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _fadeSlideIn(
                          animation: _headerIn,
                          child: const Text(
                            'Check your email',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 40,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _fadeSlideIn(
                          animation: _headerIn,
                          yOffset: 12,
                          child: Text.rich(
                            TextSpan(
                              text: 'We sent a verification code to\n',
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.75,
                                ),
                                fontSize: 16,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: email,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _fadeSlideIn(
                          animation: _slotIn,
                          child: _buildOtpSlots(),
                        ),
                        const SizedBox(height: 14),
                        _fadeSlideIn(
                          animation: _resendIn,
                          yOffset: 10,
                          child: AnimatedOpacity(
                            opacity: _isLoading ? 1 : 0,
                            duration: const Duration(milliseconds: 160),
                            child: const Text(
                              'Verifying code...',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _fadeSlideIn(
                          animation: _resendIn,
                          yOffset: 10,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              Text(
                                "Didn't receive code? ",
                                style: TextStyle(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.72,
                                  ),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton(
                                onPressed: (_canResend && !_isResending)
                                    ? _resendOtp
                                    : null,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 0,
                                  ),
                                ),
                                child: Text(
                                  'Resend',
                                  style: TextStyle(
                                    color: _canResend
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (!_canResend)
                                Text(
                                  _cooldownText,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _fadeSlideIn(
                          animation: _keyboardIn,
                          yOffset: 18,
                          child: IgnorePointer(
                            ignoring: _isLoading,
                            child: _buildCustomKeyboard(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OtpKeyboardKey extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const _OtpKeyboardKey({
    required this.child,
    required this.onTap,
    required this.enabled,
  });

  @override
  State<_OtpKeyboardKey> createState() => _OtpKeyboardKeyState();
}

class _OtpKeyboardKeyState extends State<_OtpKeyboardKey> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onTap != null;
    final border = enabled
        ? (_pressed
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.glassBorderSubtle)
        : Colors.transparent;

    return AnimatedScale(
      scale: _pressed ? 0.965 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.1),
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _pressed
                      ? [
                          AppColors.primary.withValues(alpha: 0.12),
                          const Color(0xFF172742),
                        ]
                      : [const Color(0xFF22314C), const Color(0xFF17233A)],
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
