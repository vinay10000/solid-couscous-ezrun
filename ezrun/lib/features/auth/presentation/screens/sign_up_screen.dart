import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart' as fa;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/error_handler.dart';
import 'email_otp_screen.dart';
import '../widgets/auth_components.dart';

/// Sign Up Screen - Create new account with email
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _obscure = true;

  @override
  void dispose() {
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
    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight
                ? [colors.surfaceRaised, colors.surfaceBase, colors.surfaceBase]
                : [
                    AppColors.backgroundSecondary,
                    AppColors.background,
                    Colors.black,
                  ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTopBar(
                    title: 'Sign Up',
                    onBack: () => context.pop(),
                    trailingText: 'Skip',
                    onTrailing: () => context.go('/sign-in'),
                    foreground: colors.textPrimary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please fill in the details to create your account',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  AuthField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _fullNameController,
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    label: 'Email Address',
                    hint: 'Enter your email address',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signUp(),
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
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
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: const Offset(-6, -6),
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: colors.accentPrimary,
                          checkColor: Theme.of(context).colorScheme.onPrimary,
                          side: BorderSide(color: colors.borderStrong),
                          onChanged: (v) =>
                              setState(() => _agreedToTerms = v ?? false),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text.rich(
                            TextSpan(
                              text: 'By signing up you agree to our ',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms and\nConditions of Use',
                                  style: TextStyle(
                                    color: colors.textPrimary.withOpacity(0.85),
                                    decoration: TextDecoration.underline,
                                    decorationColor: colors.textPrimary
                                        .withOpacity(0.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AuthPillButton(
                    text: 'Create An Account',
                    onPressed: _isLoading ? null : _signUp,
                    isLoading: _isLoading,
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'Or sign up with',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AuthOutlinePillButton(
                    text: 'Continue with Google',
                    onPressed: _isLoading
                        ? null
                        : () async {
                            // Optional: keep screen aligned with screenshot; Google sign-up uses same flow.
                            try {
                              setState(() => _isLoading = true);
                              await _authService.signInWithGoogle();
                              if (!mounted) return;
                              context.go('/');
                            } catch (e) {
                              if (!mounted) return;
                              ErrorHandler.handleException(
                                context,
                                e,
                                title: 'Google Sign In Failed',
                              );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                    leading: fa.FaIcon(
                      fa.FontAwesomeIcons.google,
                      size: 18,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/sign-in'),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
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
