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

/// Sign Up Screen – Create new account with email.
/// Redesigned with stunning visuals: animated background, glass morphism,
/// glowing accents, and entrance animations.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _obscure = true;

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ErrorHandler.showErrorDialog(
        context,
        title: 'Terms Required',
        message: 'Please agree to the Terms & Privacy Policy to continue.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _fullNameController.text.trim(),
      );

      if (!mounted) return;
      context.go(
        '/email-otp',
        extra: EmailOtpArgs(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          isSignUp: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        ErrorHandler.handleException(context, e, title: 'Sign Up Failed');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                      0.5 - t * 1.0,
                      -0.6 + t * 0.3,
                    ),
                    radius: 1.5,
                    colors: isLight
                        ? [
                            colors.accentPrimary.withOpacity(0.06),
                            colors.surfaceBase,
                          ]
                        : [
                            AppColors.secondary.withOpacity(0.08),
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
              top: -40,
              left: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.12),
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
                  end: const Offset(1.25, 1.25),
                  duration: 5.seconds,
                  curve: Curves.easeInOut,
                ),
            Positioned(
              bottom: size.height * 0.25,
              right: -50,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.10),
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
          ],

          // ── Main content ──
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top bar
                    AuthTopBar(
                      title: 'Sign Up',
                      onBack: () => context.pop(),
                      trailingText: 'Skip',
                      onTrailing: () => context.go('/sign-in'),
                      foreground: colors.textPrimary,
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 16),

                    // ── Header with icon accent ──
                    Row(
                      children: [
                        // Glowing accent circle
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                colors.accentPrimary.withOpacity(0.20),
                                AppColors.secondary.withOpacity(
                                    isLight ? 0.08 : 0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color:
                                  colors.accentPrimary.withOpacity(0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.accentPrimary
                                    .withOpacity(isLight ? 0.08 : 0.18),
                                blurRadius: 16,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_add_alt_1_rounded,
                            color: colors.accentPrimary,
                            size: 22,
                          ),
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1.0, 1.0),
                              delay: 100.ms,
                              duration: 500.ms,
                              curve: Curves.easeOutBack,
                            )
                            .fadeIn(delay: 100.ms, duration: 400.ms),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Join the running community',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 500.ms)
                              .slideX(
                                begin: -0.08,
                                end: 0,
                                duration: 500.ms,
                                curve: Curves.easeOut,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Glass card for form fields ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isLight
                            ? colors.surfaceRaised
                            : AppColors.backgroundSecondary
                                .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.borderSubtle,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadowSoft,
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AuthField(
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            controller: _fullNameController,
                            icon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(
                                  delay: 250.ms, duration: 400.ms)
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                duration: 400.ms,
                              ),
                          const SizedBox(height: 16),
                          AuthField(
                            label: 'Email Address',
                            hint: 'Enter your email address',
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            keyboardType:
                                TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(
                                  delay: 350.ms, duration: 400.ms)
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                duration: 400.ms,
                              ),
                          const SizedBox(height: 16),
                          AuthField(
                            label: 'Password',
                            hint: 'Enter your password',
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _signUp(),
                            suffix: IconButton(
                              onPressed: () => setState(
                                  () => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: colors.textMuted,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(
                                  delay: 450.ms, duration: 400.ms)
                              .slideY(
                                begin: 0.1,
                                end: 0,
                                duration: 400.ms,
                              ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms),

                    const SizedBox(height: 16),

                    // ── Terms checkbox ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: const Offset(-6, -6),
                          child: Checkbox(
                            value: _agreedToTerms,
                            activeColor: colors.accentPrimary,
                            checkColor: Theme.of(context)
                                .colorScheme
                                .onPrimary,
                            side: BorderSide(
                                color: colors.borderStrong),
                            onChanged: (v) => setState(
                                () => _agreedToTerms = v ?? false),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: 2),
                            child: Text.rich(
                              TextSpan(
                                text:
                                    'By signing up you agree to our ',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        'Terms and\nConditions of Use',
                                    style: TextStyle(
                                      color: colors.textPrimary
                                          .withOpacity(0.85),
                                      decoration:
                                          TextDecoration.underline,
                                      decorationColor: colors
                                          .textPrimary
                                          .withOpacity(0.35),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 550.ms, duration: 400.ms),

                    const SizedBox(height: 20),

                    // ── Create Account button with glow ──
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accentPrimary
                                .withOpacity(0.30),
                            blurRadius: 24,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AuthPillButton(
                        text: 'Create Account',
                        onPressed: _isLoading ? null : _signUp,
                        isLoading: _isLoading,
                        backgroundColor: colors.accentPrimary,
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimary,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 500.ms)
                        .slideY(
                          begin: 0.15,
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
                        .fadeIn(delay: 700.ms, duration: 400.ms),

                    const SizedBox(height: 20),

                    // ── Google sign up ──
                    AuthOutlinePillButton(
                      text: 'Continue with Google',
                      onPressed: _isLoading
                          ? null
                          : () async {
                              try {
                                setState(
                                    () => _isLoading = true);
                                await _authService
                                    .signInWithGoogle();
                                if (!mounted) return;
                                context.go('/');
                              } catch (e) {
                                if (!mounted) return;
                                ErrorHandler.handleException(
                                  context,
                                  e,
                                  title:
                                      'Google Sign In Failed',
                                );
                              } finally {
                                if (mounted) {
                                  setState(() =>
                                      _isLoading = false);
                                }
                              }
                            },
                      leading: fa.FaIcon(
                        fa.FontAwesomeIcons.google,
                        size: 18,
                        color: colors.textPrimary,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 500.ms)
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 24),

                    // ── Footer link ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go('/sign-in'),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: colors.accentPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 900.ms, duration: 500.ms),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
