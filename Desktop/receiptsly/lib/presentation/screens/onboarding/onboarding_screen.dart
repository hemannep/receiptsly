// lib/presentation/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../presentation/widgets/common/app_button.dart';
import '../../../presentation/providers/onboarding_provider.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/progress_indicator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Capture Receipts Instantly',
      subtitle:
          'Simply take a photo or send it via WhatsApp. Our AI extracts all the details automatically.',
      imagePath: AssetPaths.onboardingReceipt,
      animation: 'receipt_capture',
    ),
    OnboardingPageData(
      title: 'Smart Expense Tracking',
      subtitle:
          'Automatically categorize expenses and track spending patterns with intelligent insights.',
      imagePath: AssetPaths.onboardingAnalytics,
      animation: 'expense_tracking',
    ),
    OnboardingPageData(
      title: 'Professional Invoicing',
      subtitle:
          'Create and send professional invoices in seconds. Track payments and get paid faster.',
      imagePath: AssetPaths.onboardingInvoice,
      animation: 'invoice_creation',
    ),
    OnboardingPageData(
      title: 'Work Anywhere, Anytime',
      subtitle:
          'Sync across all devices and work offline. Your data is always secure and accessible.',
      imagePath: AssetPaths.onboardingSync,
      animation: 'data_sync',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    // Mark onboarding as completed
    ref.read(onboardingProvider.notifier).completeOnboarding();

    // Navigate to business setup
    context.go('/onboarding/business-setup');
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  if (_currentPage > 0)
                    IconButton(
                      onPressed: _previousPage,
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    const SizedBox(width: 48),

                  // Logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      AssetPaths.logoIcon,
                      width: 24,
                      height: 24,
                      color: AppColors.primary,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.receipt_long_outlined,
                          size: 24,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),

                  // Skip Button
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OnboardingProgressIndicator(
                currentPage: _currentPage,
                totalPages: _pages.length,
              ),
            ),

            const SizedBox(height: 20),

            // Page Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    data: _pages[index],
                    isActive: index == _currentPage,
                  );
                },
              ),
            ),

            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      if (_currentPage < _pages.length - 1) ...[
                        Expanded(
                          child: AppButton(
                            variant: ButtonVariant.outlined,
                            onPressed: _skipOnboarding,
                            child: const Text('Skip'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            onPressed: _nextPage,
                            child: const Text('Next'),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: AppButton(
                            onPressed: _completeOnboarding,
                            child: const Text('Get Started'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String subtitle;
  final String? imagePath;
  final String? animation;
  final IconData? icon;

  OnboardingPageData({
    required this.title,
    required this.subtitle,
    this.imagePath,
    this.animation,
    this.icon,
  });
}
