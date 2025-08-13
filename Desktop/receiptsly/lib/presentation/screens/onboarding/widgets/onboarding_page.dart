// lib/presentation/screens/onboarding/widgets/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/asset_paths.dart';
import '../onboarding_screen.dart';

class OnboardingPage extends StatefulWidget {
  final OnboardingPageData data;
  final bool isActive;

  const OnboardingPage({super.key, required this.data, this.isActive = false});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _textAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _textAnimationController,
            curve: Curves.easeOut,
          ),
        );

    if (widget.isActive) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _textAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Illustration
          Expanded(
            flex: 3,
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animationController.value,
                    child: _buildIllustration(),
                  );
                },
              ),
            ),
          ),

          // Text Content
          Expanded(
            flex: 2,
            child: AnimatedBuilder(
              animation: _textAnimationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Text(
                          widget.data.title,
                          style: AppTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        Text(
                          widget.data.subtitle,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    // Try Lottie animation first, fall back to static image, then to icon
    if (widget.data.animation != null) {
      return Container(
        width: 280,
        height: 280,
        child: Lottie.asset(
          'assets/animations/${widget.data.animation}.json',
          width: 280,
          height: 280,
          fit: BoxFit.contain,
          repeat: true,
          animate: widget.isActive,
          errorBuilder: (context, error, stackTrace) {
            return _buildStaticImage();
          },
        ),
      );
    } else {
      return _buildStaticImage();
    }
  }

  Widget _buildStaticImage() {
    if (widget.data.imagePath != null) {
      return Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Image.asset(
          widget.data.imagePath!,
          width: 280,
          height: 280,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon();
          },
        ),
      );
    } else {
      return _buildFallbackIcon();
    }
  }

  Widget _buildFallbackIcon() {
    IconData iconData;
    Color iconColor;

    // Determine icon based on page content
    if (widget.data.title.toLowerCase().contains('receipt')) {
      iconData = Icons.receipt_long_outlined;
      iconColor = AppColors.primary;
    } else if (widget.data.title.toLowerCase().contains('expense') ||
        widget.data.title.toLowerCase().contains('track')) {
      iconData = Icons.analytics_outlined;
      iconColor = AppColors.success;
    } else if (widget.data.title.toLowerCase().contains('invoice')) {
      iconData = Icons.description_outlined;
      iconColor = AppColors.info;
    } else if (widget.data.title.toLowerCase().contains('sync') ||
        widget.data.title.toLowerCase().contains('anywhere')) {
      iconData = Icons.cloud_sync_outlined;
      iconColor = AppColors.warning;
    } else {
      iconData = widget.data.icon ?? Icons.star_outline;
      iconColor = AppColors.primary;
    }

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [iconColor.withOpacity(0.1), iconColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 2),
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, size: 60, color: iconColor),
        ),
      ),
    );
  }
}
