import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../utils/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/input/password_input_field.dart';
import '../../widgets/input/text_input_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl    = TextEditingController();
  final _codeCtrl     = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  late final AuthController _auth;

  // 0 = enter email, 1 = enter code + new password, 2 = success
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await _auth.forgotPassword(_emailCtrl.text.trim());
    if (ok && mounted) setState(() => _step = 1);
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await _auth.resetPassword(
      newPassword: _newPassCtrl.text,
      code: _codeCtrl.text.trim(),
    );
    if (ok && mounted) setState(() => _step = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 28),

                if (_step == 2) ...[
                  _SuccessView(onLogin: () => Get.offAllNamed(Routes.login)),
                ] else ...[
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  if (_step == 0) _buildEmailStep(context),
                  if (_step == 1) _buildResetStep(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock_reset_rounded,
              color: Colors.white, size: 32),
        ),
        const SizedBox(height: 20),
        Text(
          _step == 0 ? 'Forgot Password?' : 'Reset Password',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          _step == 0
              ? 'Enter your email address and we\'ll send\nyou a reset code.'
              : 'Enter the code sent to ${_emailCtrl.text} and your new password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildEmailStep(BuildContext context) {
    return Column(
      children: [
        TextInputField(
          label: 'Email Address',
          hint: 'Enter your registered email',
          controller: _emailCtrl,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: Validators.email,
        ),
        const SizedBox(height: 28),
        Obx(() => PrimaryButton(
              label: 'Send Reset Code',
              onPressed: _sendCode,
              isLoading: _auth.isLoading.value,
              icon: Icons.send_rounded,
            )),
        const SizedBox(height: 20),
        Obx(() {
          final err = _auth.errorMessage.value;
          if (err == null) return const SizedBox.shrink();
          return _ErrorBanner(message: err);
        }),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Get.back(),
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }

  Widget _buildResetStep(BuildContext context) {
    return Column(
      children: [
        TextInputField(
          label: 'Reset Code',
          hint: 'Enter the code from your email',
          controller: _codeCtrl,
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Please enter the reset code' : null,
        ),
        const SizedBox(height: 16),
        PasswordInputField(
          label: 'New Password',
          controller: _newPassCtrl,
          showStrengthIndicator: true,
          validator: Validators.password,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _resetPassword(),
        ),
        const SizedBox(height: 28),
        Obx(() => PrimaryButton(
              label: 'Reset Password',
              onPressed: _resetPassword,
              isLoading: _auth.isLoading.value,
              icon: Icons.lock_open_rounded,
            )),
        const SizedBox(height: 16),
        Obx(() {
          final err = _auth.errorMessage.value;
          if (err == null) return const SizedBox.shrink();
          return _ErrorBanner(message: err);
        }),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = 0),
            child: const Text("Didn't receive the code? Resend"),
          ),
        ),
      ],
    );
  }
}

// ─── Success state ────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                gradient: AppColors.emeraldGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 52),
            ),
            const SizedBox(height: 28),
            Text(
              'Password Reset!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Your password has been updated.\nYou can now sign in with your new password.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Back to Sign In',
              onPressed: onLogin,
              icon: Icons.login_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
