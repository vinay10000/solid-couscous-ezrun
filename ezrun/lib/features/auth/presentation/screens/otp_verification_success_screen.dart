import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';

class OtpVerificationSuccessScreen extends StatefulWidget {
  final String email;

  const OtpVerificationSuccessScreen({super.key, this.email = ''});

  @override
  State<OtpVerificationSuccessScreen> createState() =>
      _OtpVerificationSuccessScreenState();
}

class _OtpVerificationSuccessScreenState
    extends State<OtpVerificationSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _ambient;

  late final Animation<double> _badgeIn;
  late final Animation<double> _titleIn;
  late final Animation<double> _buttonIn;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _badgeIn = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );
    _titleIn = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.22, 0.7, curve: Curves.easeOutCubic),
    );
    _buttonIn = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.58, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _entry.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Widget _fadeSlide({
    required Widget child,
    required Animation<double> animation,
    double y = 18,
  }) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (_, builtChild) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * y),
            child: builtChild,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _ambient,
        builder: (context, _) {
          final t = _ambient.value;
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.1 + (t * 0.12)),
                radius: 1.25,
                colors: const [
                  Color(0xFF0D6A34),
                  Color(0xFF07361D),
                  Color(0xFF03130C),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 140 + (t * 12),
                    right: 55,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.28),
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 170 - (t * 12),
                    left: 50,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 190 + (t * 16),
                    right: 66,
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Container(
                        width: 11,
                        height: 11,
                        color: AppColors.success.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        _fadeSlide(
                          animation: _badgeIn,
                          y: 20,
                          child: Transform.scale(
                            scale: 1 + (t * 0.06),
                            child: Container(
                              width: 132,
                              height: 132,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.55),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 60,
                                    spreadRadius: -8,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 62,
                                  height: 62,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 38,
                                    color: Color(0xFF082312),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _fadeSlide(
                          animation: _titleIn,
                          y: 14,
                          child: const Text(
                            'Verification\nSuccessful',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 46,
                              height: 1,
                              letterSpacing: -0.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _fadeSlide(
                          animation: _titleIn,
                          y: 10,
                          child: Text(
                            widget.email.isNotEmpty
                                ? 'Your email ${widget.email} is verified.\nYou can now continue using the app.'
                                : 'Your email has been verified. You can\nnow continue using the app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const Spacer(flex: 3),
                        _fadeSlide(
                          animation: _buttonIn,
                          y: 16,
                          child: SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: () => context.go('/'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: const Color(0xFF052510),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                shadowColor: AppColors.success.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue to Dashboard',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.arrow_forward, size: 22),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _fadeSlide(
                          animation: _buttonIn,
                          y: 8,
                          child: Text(
                            'Securely verified',
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.3,
                              ),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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
