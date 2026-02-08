import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/error_handler.dart';
import '../../../../core/widgets/email_verified_bottom_sheet.dart';

/// "Let's verify your email" screen.
///
/// - Shown after first-time sign-up when email confirmation is required.
/// - Polls Supabase for `emailConfirmedAt` and shows a bottom popup when verified.
class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  final _supabase = Supabase.instance.client;

  StreamSubscription<AuthState>? _authSub;
  Timer? _pollTimer;

  bool _isResending = false;
  DateTime? _nextResendAllowedAt;
  bool _showedVerifiedPopup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authSub = _supabase.auth.onAuthStateChange.listen((_) {
      // If a verification link completes and sets a session, this will fire.
      _checkEmailVerified();
    });

    // Polling is a fallback for cases where the user verifies and returns later.
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkEmailVerified();
    });

    // Initial check in case we landed here from a verification deep link.
    unawaited(_checkEmailVerified());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkEmailVerified();
    }
  }

  bool get _canResend {
    final next = _nextResendAllowedAt;
    if (next == null) return true;
    return DateTime.now().isAfter(next);
  }

  Future<void> _checkEmailVerified() async {
    if (!mounted || _showedVerifiedPopup) return;

    try {
      // `getUser()` refreshes user data for the current session (if any).
      final res = await _supabase.auth.getUser();
      final user = res.user;
      if (user == null) return;

      if (user.emailConfirmedAt != null) {
        _showedVerifiedPopup = true;
        if (!mounted) return;
        await _showEmailVerifiedPopup();
      }
    } catch (_) {
      // No session (common right after sign-up with email confirmation),
      // or network issues. We'll keep polling.
    }
  }

  Future<void> _resendEmail() async {
    if (_isResending || !_canResend) return;

    setState(() {
      _isResending = true;
      _nextResendAllowedAt = DateTime.now().add(const Duration(seconds: 30));
    });

    try {
      await _supabase.auth.resend(type: OtpType.signup, email: widget.email);

      if (!mounted) return;
      ErrorHandler.showSuccessDialog(
        context,
        title: 'Email Resent',
        message: 'Verification email has been resent. Please check your inbox.',
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.handleException(context, e, title: 'Resend Failed');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _showEmailVerifiedPopup() async {
    // If the user is not authenticated, we can’t auto-enter the app yet.
    // We'll take them to sign-in after closing the popup.
    final hasSession = _supabase.auth.currentSession != null;

    await showEmailVerifiedBottomSheet(context);

    // Persist a "shown" flag so we don't show it again on next sign-in.
    final me = _supabase.auth.currentUser;
    if (me != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('email_verified_popup_shown_${me.id}', true);
    }

    if (!mounted) return;
    if (hasSession) {
      context.go('/');
    } else {
      context.go('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabledResend = !_canResend || _isResending;
    final next = _nextResendAllowedAt;
    final secondsLeft = next == null
        ? 0
        : next.difference(DateTime.now()).inSeconds.clamp(0, 9999);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  const Expanded(
                    child: Text(
                      'EZRUN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // balance for the back button
                ],
              ),

              const SizedBox(height: AppSizes.xl),

              const Text(
                "Let's Verify Your email",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSizes.sm),

              const Text(
                "Please check your inbox and tap the link in the email we've just sent to:",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),

              const SizedBox(height: AppSizes.lg),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  TextButton(
                    onPressed: disabledResend ? null : _resendEmail,
                    child: Text(
                      disabledResend
                          ? 'Resend in ${secondsLeft}s'
                          : 'Resend it',
                      style: TextStyle(
                        color: disabledResend
                            ? AppColors.textMuted
                            : AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.glassDark,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.glassBorderSubtle),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textSecondary),
                    SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        'Tip: after you verify, come back here — we’ll detect it and confirm inside the app.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
