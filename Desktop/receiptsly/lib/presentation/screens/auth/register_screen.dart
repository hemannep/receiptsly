// lib/presentation/screens/auth/register_screen.dart
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
import '../../../presentation/widgets/common/app_dropdown.dart';
import '../../../presentation/widgets/common/app_loader.dart';
import '../../../presentation/widgets/common/app_snackbar.dart';
import 'widgets/auth_header.dart';
import 'widgets/social_login_buttons.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  bool _isLoading = false;
  int _currentStep = 0;

  String _selectedBusinessType = 'freelancer';
  String _selectedCountry = 'US';
  String _selectedCurrency = 'USD';

  final List<String> _businessTypes = [
    'freelancer',
    'consultant',
    'small_business',
    'contractor',
    'agency',
    'other',
  ];

  final Map<String, String> _businessTypeLabels = {
    'freelancer': 'Freelancer',
    'consultant': 'Consultant',
    'small_business': 'Small Business',
    'contractor': 'Contractor',
    'agency': 'Agency',
    'other': 'Other',
  };

  final Map<String, String> _currencies = {
    'USD': 'US Dollar (\$)',
    'EUR': 'Euro (€)',
    'GBP': 'British Pound (£)',
    'CAD': 'Canadian Dollar (C\$)',
    'AUD': 'Australian Dollar (A\$)',
    'JPY': 'Japanese Yen (¥)',
    'INR': 'Indian Rupee (₹)',
  };

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showErrorMessage('Please accept the terms and conditions');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final result = await authNotifier.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        businessData: {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'name':
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          'businessName': _businessNameController.text.trim(),
          'businessType': _selectedBusinessType,
          'country': _selectedCountry,
          'currency': _selectedCurrency,
          'phone': _phoneController.text.trim(),
        },
      );

      if (result.success) {
        if (mounted) {
          context.go('/auth/phone-verification');
        }
      } else {
        _showErrorMessage(result.message ?? 'Registration failed');
      }
    } catch (e) {
      _showErrorMessage('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final result = await authNotifier.signInWithGoogle();

      if (result.success) {
        if (mounted) {
          context.go('/onboarding');
        }
      } else {
        _showErrorMessage(result.message ?? 'Google sign up failed');
      }
    } catch (e) {
      _showErrorMessage('Google sign up failed');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate first step
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          !Validators.email(_emailController.text.trim()).isValid ||
          _passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty ||
          _passwordController.text != _confirmPasswordController.text) {
        _showErrorMessage('Please fill all fields correctly');
        return;
      }
    }

    if (_currentStep < 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleRegister();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showErrorMessage(String message) {
    AppSnackbar.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: _isLoading ? null : _previousStep,
              )
            : null,
        actions: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    context.push('/auth/login');
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
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 2,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),

              const SizedBox(height: 24),

              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPersonalInfoStep(),
                    _buildBusinessInfoStep(),
                  ],
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (_currentStep == 1) ...[
                      CheckboxListTile(
                        value: _acceptTerms,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _acceptTerms = value ?? false;
                                });
                              },
                        title: RichText(
                          text: TextSpan(
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 16),
                    ],

                    AppButton(
                      onPressed: _isLoading ? null : _nextStep,
                      child: _isLoading
                          ? const AppLoader(color: Colors.white)
                          : Text(
                              _currentStep == 1 ? 'Create Account' : 'Continue',
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Create Account',
            subtitle: 'Let\'s get started with your personal information',
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.person_outlined,
                  validator: Validators.required,
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  textInputAction: TextInputAction.next,
                  validator: Validators.required,
                  enabled: !_isLoading,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

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

          AppTextField(
            controller: _passwordController,
            label: 'Password',
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.next,
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
          ),

          const SizedBox(height: 16),

          AppTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            obscureText: !_isConfirmPasswordVisible,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outlined,
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            enabled: !_isLoading,
          ),

          const SizedBox(height: 32),

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

          SocialLoginButtons(
            onGooglePressed: _isLoading ? null : _handleGoogleSignUp,
            isLoading: _isLoading,
            buttonText: 'Sign up with Google',
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Business Information',
            subtitle:
                'Tell us about your business to personalize your experience',
          ),

          const SizedBox(height: 32),

          AppTextField(
            controller: _businessNameController,
            label: 'Business Name (Optional)',
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.business_outlined,
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          AppDropdown<String>(
            label: 'Business Type',
            value: _selectedBusinessType,
            items: _businessTypes
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(_businessTypeLabels[type] ?? type),
                  ),
                )
                .toList(),
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _selectedBusinessType = value ?? 'freelancer';
                    });
                  },
            prefixIcon: Icons.work_outlined,
          ),

          const SizedBox(height: 16),

          AppTextField(
            controller: _phoneController,
            label: 'Phone Number (Optional)',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.phone_outlined,
            enabled: !_isLoading,
          ),

          const SizedBox(height: 16),

          AppDropdown<String>(
            label: 'Currency',
            value: _selectedCurrency,
            items: _currencies.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _selectedCurrency = value ?? 'USD';
                    });
                  },
            prefixIcon: Icons.attach_money_outlined,
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.security_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your data is secure',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We use industry-standard encryption to protect your information',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
