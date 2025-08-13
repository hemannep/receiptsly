// lib/presentation/screens/auth/widgets/auth_header.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/asset_paths.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showLogo;
  final double spacing;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLogo = true,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLogo) ...[
          Center(
            child: Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                AssetPaths.logoIcon,
                width: 48,
                height: 48,
                color: AppColors.primary,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: AppColors.primary,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: spacing * 2),
        ],

        Text(
          title,
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: spacing),

        Text(
          subtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
