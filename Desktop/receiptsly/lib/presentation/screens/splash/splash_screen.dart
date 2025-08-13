import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_state_provider.dart';
import 'widgets/animated_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeApp();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _initializeApp() async {
    // Wait for minimum splash duration
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Check authentication state
    final authState = ref.read(authStateProvider);
    final preferences = ref.read(appPreferencesProvider);

    await authState.when(
      data: (user) async {
        if (user != null) {
          // User is authenticated
          if (user.emailVerified) {
            context.go('/dashboard');
          } else {
            context.go('/verify-email');
          }
        } else {
          // User is not authenticated
          if (preferences.showOnboarding) {
            context.go('/onboarding');
          } else {
            context.go('/login');
          }
        }
      },
      loading: () async {
        // Still loading auth state, wait a bit more
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          context.go('/login');
        }
      },
      error: (error, _) async {
        // Error in auth state, go to login
        context.go('/login');
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: const AnimatedLogo(),
                  ),
                ),

                const SizedBox(height: 32),

                // App Name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Receiptsly',
                    style: AppTypography.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Smart Receipt Management',
                    style: AppTypography.body1.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Loading Animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Lottie.asset(
                      AssetPaths.loadingAnimation,
                      repeat: true,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Loading Text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Initializing...',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
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
