import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart' as fa;
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/error_handler.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import 'email_otp_screen.dart';
import '../widgets/auth_components.dart';

/// Auth landing screen based on the provided reference design.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _isLoading = false;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.handleException(context, e, title: 'Google Sign In Failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEmailSheet() async {
    if (_isLoading) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EmailSheet(
        authService: _authService,
        onOtpSent: (email) {
          if (!mounted) return;
          Navigator.of(ctx).pop();
          context.go('/email-otp', extra: EmailOtpArgs(email: email));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(child: Container(color: Colors.black)),
                Positioned(
                  top: constraints.maxHeight * 0.18,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 140,
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, _) => CustomPaint(
                        painter: _WaveLinesPainter(
                          progress: _waveController.value,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                    child: Column(
                      children: [
                        const Spacer(flex: 9),
                        const Text(
                              'Welcome',
                              style: TextStyle(
                                color: Color(0xFFEDEDEF),
                                fontSize: 48,
                                letterSpacing: -0.8,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate()
                            .fadeIn(duration: 420.ms)
                            .slideY(begin: 0.18, end: 0, curve: Curves.easeOut),
                        const SizedBox(height: 8),
                        const Text(
                              'Your journey starts from here',
                              style: TextStyle(
                                color: Color(0xFF7F808A),
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate()
                            .fadeIn(delay: 110.ms, duration: 420.ms)
                            .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
                        const SizedBox(height: 34),
                        _LandingButton(
                              text: 'Continue with Email',
                              onPressed: _openEmailSheet,
                              backgroundColor: const Color(0xFFE8E8EA),
                              foregroundColor: const Color(0xFF161616),
                              borderColor: const Color(0xFFE8E8EA),
                            )
                            .animate()
                            .fadeIn(delay: 220.ms, duration: 420.ms)
                            .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                        const SizedBox(height: 14),
                        _LandingButton(
                              text: 'Continue with Google',
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              backgroundColor: const Color(0xFF2A2B33),
                              foregroundColor: const Color(0xFFEDEDEF),
                              borderColor: const Color(0xFF30313A),
                              leading: const fa.FaIcon(
                                fa.FontAwesomeIcons.google,
                                color: Color(0xFFEA4335),
                                size: 19,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 290.ms, duration: 420.ms)
                            .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                        const SizedBox(height: 24),
                        Text.rich(
                          TextSpan(
                            text:
                                'By pressing on "Continue with..." you agree\n',
                            style: const TextStyle(
                              color: Color(0xFF696A73),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                            children: const [
                              TextSpan(
                                text: 'to our ',
                                style: TextStyle(color: Color(0xFF696A73)),
                              ),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: Color(0xFF7C7D87),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(
                                text: ' and ',
                                style: TextStyle(color: Color(0xFF696A73)),
                              ),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Color(0xFF7C7D87),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 350.ms, duration: 380.ms),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LandingButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  const _LandingButton({
    required this.text,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    this.leading,
  });

  @override
  State<_LandingButton> createState() => _LandingButtonState();
}

class _LandingButtonState extends State<_LandingButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: Material(
          color: enabled
              ? widget.backgroundColor
              : widget.backgroundColor.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: widget.borderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: widget.onPressed,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: enabled
                ? () => setState(() => _pressed = false)
                : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: widget.foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveLinesPainter extends CustomPainter {
  final double progress;

  _WaveLinesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = const Color(0x1DFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..isAntiAlias = true;
    final p2 = Paint()
      ..color = const Color(0x14FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    final phase = progress * math.pi * 2;

    final wave1 = Path();
    final wave2 = Path();

    for (double x = 0; x <= size.width; x += 1) {
      final y1 = size.height * 0.56 + math.sin((x * 0.018) + phase) * 8;
      final y2 = size.height * 0.60 + math.sin((x * 0.0175) + phase + 0.55) * 7;

      if (x == 0) {
        wave1.moveTo(x, y1);
        wave2.moveTo(x, y2);
      } else {
        wave1.lineTo(x, y1);
        wave2.lineTo(x, y2);
      }
    }

    canvas.drawPath(wave1, p1);
    canvas.drawPath(wave2, p2);
  }

  @override
  bool shouldRepaint(covariant _WaveLinesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ─────────────────────────────────────────────────────────
// Email Bottom Sheet (email-only, sends OTP)
// ─────────────────────────────────────────────────────────

class _EmailSheet extends StatefulWidget {
  final AuthService authService;
  final void Function(String email) onOtpSent;

  const _EmailSheet({required this.authService, required this.onOtpSent});

  @override
  State<_EmailSheet> createState() => _EmailSheetState();
}

class _EmailSheetState extends State<_EmailSheet> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _email.text.trim();

    try {
      await widget.authService.initiateEmailAuth(email: email);
      widget.onOtpSent(email);
    } catch (e) {
      if (mounted) {
        ErrorHandler.handleException(context, e, title: 'Failed');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12131A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.borderSubtle, width: 1)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          bottom: bottomInset + 22,
          top: 12,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3B45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Text(
                    'Enter your email',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: -0.1, end: 0, duration: 300.ms),
              const SizedBox(height: 6),
              Text(
                "We'll send you a verification code",
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 60.ms, duration: 280.ms),
              const SizedBox(height: 20),
              AuthField(
                label: 'Email Address',
                hint: 'Enter your email address',
                controller: _email,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _continue(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ).animate().fadeIn(delay: 110.ms, duration: 280.ms),
              const SizedBox(height: 20),
              AuthPillButton(
                text: 'Continue',
                onPressed: _isLoading ? null : _continue,
                isLoading: _isLoading,
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF0A1318),
              ).animate().fadeIn(delay: 170.ms, duration: 320.ms),
            ],
          ),
        ),
      ),
    );
  }
}
