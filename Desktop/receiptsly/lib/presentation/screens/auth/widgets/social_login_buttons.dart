// lib/presentation/screens/auth/widgets/social_login_buttons.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../widgets/common/app_loader.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final VoidCallback? onApplePressed;
  final VoidCallback? onFacebookPressed;
  final bool isLoading;
  final String buttonText;
  final bool showApple;
  final bool showFacebook;

  const SocialLoginButtons({
    super.key,
    this.onGooglePressed,
    this.onApplePressed,
    this.onFacebookPressed,
    this.isLoading = false,
    this.buttonText = 'Sign in with Google',
    this.showApple = false,
    this.showFacebook = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Sign In Button
        _SocialLoginButton(
          onPressed: isLoading ? null : onGooglePressed,
          icon: _buildGoogleIcon(),
          text: buttonText,
          isLoading: isLoading,
          backgroundColor: Colors.white,
          textColor: AppColors.textPrimary,
          borderColor: AppColors.border,
        ),

        if (showApple) ...[
          const SizedBox(height: 12),
          _SocialLoginButton(
            onPressed: isLoading ? null : onApplePressed,
            icon: Icon(Icons.apple, color: Colors.white, size: 20),
            text: 'Sign in with Apple',
            isLoading: false,
            backgroundColor: Colors.black,
            textColor: Colors.white,
          ),
        ],

        if (showFacebook) ...[
          const SizedBox(height: 12),
          _SocialLoginButton(
            onPressed: isLoading ? null : onFacebookPressed,
            icon: Icon(Icons.facebook, color: Colors.white, size: 20),
            text: 'Sign in with Facebook',
            isLoading: false,
            backgroundColor: const Color(0xFF1877F2),
            textColor: Colors.white,
          ),
        ],
      ],
    );
  }

  Widget _buildGoogleIcon() {
    return SvgPicture.asset(
      AssetPaths.googleIcon,
      width: 20,
      height: 20,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.g_mobiledata, color: Colors.white, size: 16),
        );
      },
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String text;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.text,
    this.isLoading = false,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor != null
                ? BorderSide(color: borderColor!, width: 1)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? AppLoader(color: textColor, size: 20)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
