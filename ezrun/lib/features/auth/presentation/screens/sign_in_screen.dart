import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart' as fa;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/error_handler.dart';
import 'email_otp_screen.dart';
import '../widgets/auth_components.dart';

/// Auth screen with "Continue with email" and "Continue with Google".
///
/// Tapping "Continue with email" opens an email-only bottom sheet.
/// After entering email, the user is redirected to the OTP screen.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _isLoading = false;
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
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
      if (mounted) {
        ErrorHandler.handleException(
          context,
          e,
          title: 'Google Sign In Failed',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          context.go(
            '/email-otp',
            extra: EmailOtpArgs(email: email),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: Stack(
        children: [
          // ── Animated gradient background ──
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              final t = _bgController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      -0.5 + t * 1.0,
                      -0.8 + t * 0.4,
                    ),
                    radius: 1.4,
                    colors: isLight
                        ? [
                            colors.accentPrimary.withOpacity(0.08),
                            colors.surfaceBase,
                          ]
                        : [
                            AppColors.primary.withOpacity(0.12),
                            AppColors.background,
                          ],
                  ),
                ),
              );
            },
          ),

          // ── Decorative glow orbs ──
          if (!isLight) ...[
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.3, 1.3),
                  duration: 4.seconds,
                  curve: Curves.easeInOut,
                ),
            Positioned(
              bottom: size.height * 0.15,
              left: -60,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.2, 1.2),
                  duration: 5.seconds,
                  curve: Curves.easeInOut,
                ),
          ],

          // ── Main content ──
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top bar
                  AuthTopBar(
                    title: '',
                    onBack: null,
                    foreground: colors.textPrimary,
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // ── Hero logo with glow ring ──
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isLight
                              ? [
                                  colors.accentPrimary.withOpacity(0.15),
                                  colors.surfaceRaised,
                                ]
                              : [
                                  AppColors.primary.withOpacity(0.20),
                                  AppColors.backgroundSecondary,
                                ],
                        ),
                        border: Border.all(
                          color: colors.accentPrimary.withOpacity(0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accentPrimary.withOpacity(
                              isLight ? 0.12 : 0.25,
                            ),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: colors.shadowSoft,
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            'assets/images/auth_image.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.directions_run_rounded,
                              size: 64,
                              color: colors.accentPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1.0, 1.0),
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 32),

                  // ── Greeting text ──
                  Text(
                    'Welcome to EZRUN',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: -0.8,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideX(
                        begin: -0.1,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in or create an account to continue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 500.ms)
                      .slideX(
                        begin: -0.1,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),

                  const Spacer(),

                  // ── Continue with email ──
                  _GlowButton(
                    text: 'Continue with Email',
                    icon: Icons.email_outlined,
                    onPressed: _openEmailSheet,
                    glowColor: colors.accentPrimary,
                    backgroundColor: colors.accentPrimary,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimary,
                  )
                      .animate()
                      .fadeIn(delay: 450.ms, duration: 500.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: 14),

                  // ── Continue with Google ──
                  AuthOutlinePillButton(
                    text: 'Continue with Google',
                    onPressed:
                        _isLoading ? null : _signInWithGoogle,
                    leading: fa.FaIcon(
                      fa.FontAwesomeIcons.google,
                      size: 18,
                      color: colors.textPrimary,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 550.ms, duration: 500.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: 32),

                  // ── Footer ──
                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms & Privacy Policy',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 650.ms, duration: 500.ms),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill button wrapped with a subtle glow and an optional leading icon.
class _GlowButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color glowColor;
  final Color backgroundColor;
  final Color foregroundColor;

  const _GlowButton({
    required this.text,
    this.icon,
    required this.onPressed,
    required this.glowColor,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.30),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Email Bottom Sheet (email-only, sends OTP)
// ─────────────────────────────────────────────────────────

class _EmailSheet extends StatefulWidget {
  final AuthService authService;
  final void Function(String email) onOtpSent;

  const _EmailSheet({
    required this.authService,
    required this.onOtpSent,
  });

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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isLight
            ? colors.surfaceRaised
            : AppColors.backgroundSecondary.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: colors.accentPrimary.withOpacity(0.15),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.accentPrimary.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          bottom: bottomInset + 22,
          top: 10,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.accentPrimary.withOpacity(0.4),
                        colors.borderStrong,
                        colors.accentPrimary.withOpacity(0.4),
                      ],
                    ),
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
              )
                  .animate()
                  .fadeIn(delay: 50.ms, duration: 300.ms),
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
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: 20),
              _GlowButton(
                text: _isLoading ? '' : 'Continue',
                onPressed: _isLoading ? null : _continue,
                glowColor: colors.accentPrimary,
                backgroundColor: colors.accentPrimary,
                foregroundColor:
                    Theme.of(context).colorScheme.onPrimary,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
