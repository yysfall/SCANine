import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      icon: Icons.pets_rounded,
      title: 'Welcome to SCANine',
      description:
          'An AI-assisted tool designed to help you understand possible skin conditions affecting your pet.',
    ),
    _OnboardingData(
      icon: Icons.camera_alt_rounded,
      title: 'Scan Your Pet',
      description:
          'Take a clear photo of your pet’s affected skin or upload an existing image for AI-assisted analysis.',
    ),
    _OnboardingData(
      icon: Icons.auto_awesome_rounded,
      title: 'Understand the Results',
      description:
          'View possible skin conditions, confidence scores, and visual explanations of the AI prediction. SCANine does not replace professional veterinary diagnosis. Consult your nearest veterinarian.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/login',
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // --------------------------------------------------
            // TOP BAR / SKIP
            // --------------------------------------------------
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _currentPage < _pages.length - 1
                      ? TextButton(
                          onPressed: _skipOnboarding,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.inkSoft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            'Skip',
                            style: AppText.body(
                              size: 14,
                              color: AppColors.inkSoft,
                              w: FontWeight.w500,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),

            // --------------------------------------------------
            // ONBOARDING PAGES
            // --------------------------------------------------
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    data: _pages[index],
                  );
                },
              ),
            ),

            // --------------------------------------------------
            // PAGE INDICATORS
            // --------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) {
                  final bool isActive = _currentPage == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: isActive ? 24 : 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accent
                          : AppColors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // NEXT / GET STARTED BUTTON
            // --------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      key: ValueKey(_currentPage),
                      style: AppText.body(
                        size: 14,
                        color: Colors.white,
                        w: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ONBOARDING PAGE
// ============================================================

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPage({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --------------------------------------------------
          // ICON / ILLUSTRATION
          // --------------------------------------------------
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  data.icon,
                  size: 68,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // --------------------------------------------------
          // TITLE
          // --------------------------------------------------
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppText.display(
              size: 28,
              color: AppColors.ink,
              w: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // DESCRIPTION
          // --------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 15,
                color: AppColors.inkSoft,
                w: FontWeight.w400,
              ).copyWith(
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ONBOARDING DATA
// ============================================================

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}