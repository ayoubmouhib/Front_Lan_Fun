import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../controllers/auth_controller.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final String _email;
  late final AuthController _auth;

  final _isChecking   = false.obs;
  final _isResending  = false.obs;
  final _resendCooldown = 0.obs;

  Timer? _cooldownTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _auth  = Get.find<AuthController>();
    _email = (Get.arguments as Map<String, dynamic>?)?['email'] as String? ?? '';
    _startPolling();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  // Poll every 5 s so the user doesn't have to tap "Done"
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        final verified = await _auth.checkVerificationStatus(_email);
        if (verified) _goHome();
      } catch (_) {}
    });
  }

  Future<void> _checkAndContinue() async {
    _isChecking.value = true;
    try {
      final verified = await _auth.checkVerificationStatus(_email);
      if (verified) {
        _goHome();
      } else {
        Get.snackbar(
          'Not Verified Yet',
          'Please click the link in your email first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not check status. Try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      _isChecking.value = false;
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown.value > 0) return;
    _isResending.value = true;
    try {
      await _auth.resendVerificationEmail(_email);
      Get.snackbar(
        'Email Sent',
        'A new verification link has been sent to $_email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      // 60-second cooldown
      _resendCooldown.value = 60;
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_resendCooldown.value <= 1) {
          _resendCooldown.value = 0;
          t.cancel();
        } else {
          _resendCooldown.value--;
        }
      });
    } catch (e) {
      Get.snackbar(
        'Failed',
        'Could not resend email. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      _isResending.value = false;
    }
  }

  void _goHome() {
    _pollTimer?.cancel();
    Get.offAllNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Body
              Text(
                'We sent a verification link to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              Text(
                _email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Click the link in the email to activate your account. '
                'This page will update automatically.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // "I've verified" button
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _isChecking.value ? null : _checkAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isChecking.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "I've Verified My Email",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  )),

              const SizedBox(height: 12),

              // Resend button
              Obx(() {
                final cooldown = _resendCooldown.value;
                final sending  = _isResending.value;
                return TextButton(
                  onPressed: (cooldown > 0 || sending) ? null : _resend,
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : Text(
                          cooldown > 0
                              ? 'Resend in ${cooldown}s'
                              : 'Resend verification email',
                          style: TextStyle(
                            color: cooldown > 0
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4)
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              }),

              const SizedBox(height: 8),

              // Sign in with different account
              TextButton(
                onPressed: () => Get.offAllNamed(Routes.login),
                child: Text(
                  'Sign in with a different account',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
