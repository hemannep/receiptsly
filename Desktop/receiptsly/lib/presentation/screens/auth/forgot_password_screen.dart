// lib/presentation/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/widgets/common/app_button.dart';
import '../../../presentation/widgets/common/app_text_field.dart';
import '../../../presentation/widgets/common/app_loader.dart';
import '../../../presentation/widgets/common/app_snackbar.dart';
import 'widgets/auth_header.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final result = await authNotifier.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      if (result.success) {
        setState(() {
          _emailSent = true;
        });
        _showSuccessMessage('Password reset email sent successfully');
      } else {
        _showErrorMessage(result.message ?? 'Failed to send reset email');
      }
    } catch (e) {
      _showErrorMessage('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendEmail() async {
    setState(() {
      _emailSent = false;
      _isLoading = false;
    });
    await _handleSendResetEmail();
  }

  void _showErrorMessage(String message) {
    AppSnackbar.showError(context, message);
  }

  void _showSuccessMessage(String message) {
    AppSnackbar.showSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Header
                AuthHeader(
                  title: _emailSent ? 'Check Your Email' : 'Forgot Password?',
                  subtitle: _emailSent
                      ? 'We\'ve sent a password reset link to your email address'
                      : 'Enter your email address and we\'ll send you a link to reset your password',
                ),

                const SizedBox(height: 48),

                if (!_emailSent) ...[
                  // Email Field
                  AppTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.email_outlined,
                    validator: Validators.email,
                    enabled: !_isLoading,
                    onSubmitted: (_) => _handleSendResetEmail(),
                  ),

                  const SizedBox(height: 32),

                  // Send Reset Email Button
                  AppButton(
                    onPressed: _isLoading ? null : _handleSendResetEmail,
                    child: _isLoading
                        ? const AppLoader(color: Colors.white)
                        : const Text('Send Reset Email'),
                  ),
                ] else ...[
                  // Success Illustration
                  Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.email_outlined,
                            size: 60,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Email Sent Successfully!',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check your inbox and follow the instructions to reset your password.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Resend Email Button
                  AppButton(
                    variant: ButtonVariant.outlined,
                    onPressed: _isLoading ? null : _handleResendEmail,
                    child: _isLoading
                        ? const AppLoader()
                        : const Text('Resend Email'),
                  ),

                  const SizedBox(height: 16),

                  // Back to Login Button
                  AppButton(
                    onPressed: () => context.go('/auth/login'),
                    child: const Text('Back to Login'),
                  ),
                ],

                if (!_emailSent) ...[
                  const SizedBox(height: 48),

                  // Help Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Need Help?',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'If you don\'t receive an email within a few minutes, check your spam folder or contact our support team.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            // Navigate to support or show contact info
                          },
                          child: Text(
                            'Contact Support',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Back to Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remember your password? ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                context.go('/auth/login');
                              },
                        child: Text(
                          'Sign In',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
