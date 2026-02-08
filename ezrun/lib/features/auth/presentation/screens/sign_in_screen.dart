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

/// "Welcome / Sign In" screen with stunning animated visuals.
///
/// Tapping "Sign in" opens an email/password bottom sheet so we keep full
/// sign-in functionality while preserving the 3 visible screens requested.
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

  Future<void> _openEmailSignInSheet() async {
    if (_isLoading) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EmailSignInSheet(
        authService: _authService,
        onSignedIn: () {
          if (!mounted) return;
          Navigator.of(ctx).pop();
          context.go('/');
        },
        onNeedsOtp: (email, password) {
          if (!mounted) return;
          Navigator.of(ctx).pop();
          context.go(
            '/email-otp',
            extra: EmailOtpArgs(
              email: email,
              password: password,
              isSignUp: false,
            ),
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
                    trailingText: 'Skip',
                    onTrailing: _openEmailSignInSheet,
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
                    'Welcome Back!',
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
                    'Sign in to continue your run',
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

                  const SizedBox(height: 36),

                  // ── Sign in button with glow ──
                  _GlowButton(
                    text: 'Sign In',
                    onPressed: _openEmailSignInSheet,
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

                  // ── Sign up outline button ──
                  AuthOutlinePillButton(
                    text: 'Create Account',
                    onPressed: () => context.push('/sign-up'),
                  )
                      .animate()
                      .fadeIn(delay: 550.ms, duration: 500.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: 24),

                  // ── Divider with "or" ──
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                colors.borderStrong,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.borderStrong,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 650.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // ── Google button ──
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
                      .fadeIn(delay: 750.ms, duration: 500.ms)
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),

                  const Spacer(),

                  // ── Footer ──
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/sign-up'),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: colors.accentPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 850.ms, duration: 500.ms),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill button wrapped with a subtle glow behind it.
class _GlowButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color glowColor;
  final Color backgroundColor;
  final Color foregroundColor;

  const _GlowButton({
    required this.text,
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
      child: AuthPillButton(
        text: text,
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Email Sign-In Bottom Sheet (glass-morphism styled)
// ─────────────────────────────────────────────────────────

class _EmailSignInSheet extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSignedIn;
  final void Function(String email, String password) onNeedsOtp;

  const _EmailSignInSheet({
    required this.authService,
    required this.onSignedIn,
    required this.onNeedsOtp,
  });

  @override
  State<_EmailSignInSheet> createState() => _EmailSignInSheetState();
}

class _EmailSignInSheetState extends State<_EmailSignInSheet> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _email.text.trim();
    final password = _password.text;

    try {
      await widget.authService.signIn(email: email, password: password);
      widget.onSignedIn();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final needsEmailVerification =
          msg.contains('verify') && msg.contains('email');
      if (needsEmailVerification) {
        try {
          widget.authService.stageSupabaseSyncForOtp(
            email: email,
            password: password,
          );
          await widget.authService.sendEmailOtp(email: email);
        } catch (_) {
          // Ignore — sign-in may have already sent it.
        }
        widget.onNeedsOtp(email, password);
        return;
      }
      if (mounted) {
        ErrorHandler.handleException(context, e, title: 'Sign In Failed');
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
                'Sign In',
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
              const SizedBox(height: 20),
              AuthField(
                label: 'Email Address',
                hint: 'Enter your email address',
                controller: _email,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: 16),
              AuthField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _password,
                icon: Icons.lock_outline,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: colors.textMuted,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  return null;
                },
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.push('/forgot-password'),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor:
                          colors.accentPrimary.withOpacity(0.45),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _GlowButton(
                text: 'Sign In',
                onPressed: _signIn,
                glowColor: colors.accentPrimary,
                backgroundColor: colors.accentPrimary,
                foregroundColor:
                    Theme.of(context).colorScheme.onPrimary,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
