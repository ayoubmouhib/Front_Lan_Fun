import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../data/datasources/local/storage_service.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;
}

const _pages = [
  _OnboardingPage(
    icon: Icons.public_rounded,
    title: 'Learn languages\nby connecting',
    description:
        'LinguaConnect pairs you with real people around the world so you can '
        'practice speaking and writing in a language you\'re learning — not just memorize flashcards.',
    gradient: AppColors.primaryGradient,
  ),
  _OnboardingPage(
    icon: Icons.flag_rounded,
    title: 'Practice with\na purpose',
    description:
        'Find a partner in seconds, join voice and video calls, take quizzes, '
        'play games and track your streaks — every feature is built to keep you moving toward fluency.',
    gradient: LinearGradient(
      colors: [AppColors.secondary, AppColors.secondaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  _OnboardingPage(
    icon: Icons.rocket_launch_rounded,
    title: 'Stay motivated,\ntogether',
    description:
        'Earn XP, climb the leaderboard, build your own vocabulary and grow a network '
        'of language partners who keep you accountable. Your fluency journey starts now.',
    gradient: LinearGradient(
      colors: [AppColors.purple, AppColors.primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];

/// First-run intro carousel — explains what LinguaConnect is, what you can do
/// with it and why it exists, before sending the user to login/signup.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _pages.length - 1;

  Future<void> _finish() async {
    await StorageService.instance.setOnboardingDone();
    Get.offAllNamed(Routes.login);
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(gradient: page.gradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                  child: TextButton(
                    onPressed: _isLast ? null : _finish,
                    child: Text(
                      _isLast ? '' : 'Skip',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _OnboardingPageView(page: _pages[i]),
                ),
              ),

              // Dots indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: active ? 1 : 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _next,
                    child: Text(
                      _isLast ? 'Get Started' : 'Next',
                      style: TextStyle(
                        color: page.gradient.colors.first,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, color: Colors.white, size: 56),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
