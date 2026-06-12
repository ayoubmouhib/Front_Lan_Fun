import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../utils/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/input/password_input_field.dart';
import '../../widgets/input/text_input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = false;

  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _auth.login(
      identifier: _identifierCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // ── Header ───────────────────────────────────────────
              _GradientHeader(),

              const SizedBox(height: 36),

              // ── Form ─────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextInputField(
                      label: 'Email or Username',
                      hint: 'Enter your email or username',
                      controller: _identifierCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 16),
                    PasswordInputField(
                      controller: _passwordCtrl,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 12),

                    // Remember me + Forgot
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v ?? false),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('Remember me',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              Get.toNamed(Routes.forgotPassword),
                          child: const Text('Forgot Password?'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Error message
                    Obx(() {
                      final err = _auth.errorMessage.value;
                      if (err == null) return const SizedBox.shrink();
                      return _ErrorBanner(message: err);
                    }),

                    const SizedBox(height: 8),

                    // Login button
                    Obx(() => PrimaryButton(
                          label: 'Sign In',
                          onPressed: _submit,
                          isLoading: _auth.isLoading.value,
                          icon: Icons.login_rounded,
                        )),

                    const SizedBox(height: 28),

                    // Divider
                    _DividerWithText(text: 'or continue with'),

                    const SizedBox(height: 24),

                    // Social buttons row
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() => _SocialButton(
                                label: 'Google',
                                icon: _GoogleIcon(),
                                isLoading: _auth.isGoogleLoading.value,
                                onTap: _auth.loginWithGoogle,
                              )),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SocialButton(
                            label: 'Facebook',
                            icon: _FacebookIcon(),
                            onTap: _showFbComingSoon,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => Get.toNamed(Routes.signup),
                          child: ShaderMask(
                            shaderCallback: (r) =>
                                AppColors.primaryGradient.createShader(r),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFbComingSoon() {
    Get.snackbar(
      'Coming Soon',
      'Facebook login will be available soon.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      backgroundColor: AppColors.primary.withValues(alpha: 0.9),
      colorText: Colors.white,
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (r) => AppColors.primaryGradient.createShader(r),
          child: const Text(
            'Welcome Back! 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your LinguaConnect account',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

class _DividerWithText extends StatelessWidget {
  const _DividerWithText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).dividerColor;
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: color),
          ),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.isLoading = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: 1.5,
          ),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // simplified colorful circle to represent Google
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    for (var i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        (i * 3.14159 / 2) - 3.14159 / 4,
        3.14159 / 2,
        true,
        paint,
      );
    }
    canvas.drawCircle(center, r * 0.55,
        Paint()..color = Theme.of(Get.context!).colorScheme.surface);
    canvas.drawCircle(
        Offset(center.dx + r * 0.4, center.dy),
        r * 0.25,
        Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FacebookIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
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
      margin: const EdgeInsets.only(bottom: 12),
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
