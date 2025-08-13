// lib/presentation/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/widgets/common/app_button.dart';
import '../../../presentation/widgets/common/app_text_field.dart';
import '../../../presentation/widgets/common/app_loader.dart';
import '../../../presentation/widgets/common/app_snackbar.dart';
import 'widgets/auth_header.dart';
import 'widgets/social_login_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    // Load saved email if remember me was checked
    // Implementation would use secure storage
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final result = await authNotifier.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result.success) {
        if (_rememberMe) {
          await _saveCredentials();
        }

        // Navigate to dashboard
        if (mounted) {
          context.go('/dashboard');
        }
      } else {
        _showErrorMessage(result.message ?? 'Login failed');
      }
    } catch (e) {
      _showErrorMessage('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final result = await authNotifier.signInWithGoogle();

      if (result.success) {
        if (mounted) {
          context.go('/dashboard');
        }
      } else {
        _showErrorMessage(result.message ?? 'Google login failed');
      }
    } catch (e) {
      _showErrorMessage('Google login failed');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveCredentials() async {
    // Save credentials to secure storage
    // Implementation would use flutter_secure_storage
  }

  void _showErrorMessage(String message) {
    AppSnackbar.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                const AuthHeader(
                  title: 'Welcome Back',
                  subtitle:
                      'Sign in to continue managing your receipts and invoices',
                ),

                const SizedBox(height: 48),

                // Email Field
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 16),

                // Password Field
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: Validators.password,
                  enabled: !_isLoading,
                  onSubmitted: (_) => _handleLogin(),
                ),

                const SizedBox(height: 16),

                // Remember Me & Forgot Password
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        value: _rememberMe,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                        title: Text(
                          'Remember me',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              context.push('/auth/forgot-password');
                            },
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Login Button
                AppButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const AppLoader(color: Colors.white)
                      : const Text('Sign In'),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Social Login Buttons
                SocialLoginButtons(
                  onGooglePressed: _isLoading ? null : _handleGoogleLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 32),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              context.push('/auth/register');
                            },
                      child: Text(
                        'Sign Up',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Terms & Privacy
                Text(
                  'By signing in, you agree to our Terms of Service and Privacy Policy',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
