import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart' as fa;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/error_handler.dart';
import 'email_otp_screen.dart';
import '../widgets/auth_components.dart';

/// "Welcome / Sign In" screen (matches screenshot #1).
///
/// Tapping "Sign in" opens an email/password bottom sheet so we keep full
/// sign-in functionality while preserving the 3 visible screens requested.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;

      // Navigate immediately on success (router refresh is a fallback).
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
      backgroundColor: context.semanticColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTopBar(
                  title: '',
                  onBack: null,
                  trailingText: 'Skip',
                  onTrailing: _openEmailSignInSheet,
                  foreground: colors.textPrimary,
                ),
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.surfaceGlass, colors.surfaceRaised],
                      ),
                      border: Border.all(color: colors.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadowSoft,
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          'assets/images/auth_image.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            size: 72,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Hi !',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please sign in to continue',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                AuthPillButton(
                  text: 'Sign in',
                  onPressed: _openEmailSignInSheet,
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 12),
                AuthOutlinePillButton(
                  text: 'Sign up',
                  onPressed: () => context.push('/sign-up'),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'Or sign in with',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AuthOutlinePillButton(
                  text: 'Continue with Google',
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  leading: fa.FaIcon(
                    fa.FontAwesomeIcons.google,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    ' ',
                    style: TextStyle(color: Colors.black.withOpacity(0.0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        bottom: bottomInset + 18,
        top: 10,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: colors.borderStrong,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Text(
              'Sign In',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AuthField(
              label: 'Email Address',
              hint: 'Enter your email address / Phone num',
              controller: _email,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
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
            ),
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
                    decorationColor: colors.accentPrimary.withOpacity(0.45),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            AuthPillButton(
              text: 'Sign in',
              onPressed: _signIn,
              isLoading: _isLoading,
              backgroundColor: colors.accentPrimary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
