// lib/presentation/screens/onboarding/business_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/onboarding_provider.dart';
import '../../../presentation/widgets/common/app_button.dart';
import '../../../presentation/widgets/common/app_text_field.dart';
import '../../../presentation/widgets/common/app_dropdown.dart';
import '../../../presentation/widgets/common/app_loader.dart';
import '../../../presentation/widgets/common/app_snackbar.dart';
import 'widgets/progress_indicator.dart';

class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();

  bool _isLoading = false;
  String _selectedBusinessType = 'freelancer';
  String _selectedIndustry = 'technology';
  String _selectedCountry = 'US';
  String _selectedCurrency = 'USD';
  String _selectedTimezone = 'America/New_York';

  final Map<String, String> _businessTypes = {
    'freelancer': 'Freelancer / Solopreneur',
    'consultant': 'Consultant',
    'small_business': 'Small Business (1-10 employees)',
    'medium_business': 'Medium Business (11-50 employees)',
    'contractor': 'Contractor',
    'agency': 'Agency / Studio',
    'nonprofit': 'Non-profit Organization',
    'other': 'Other',
  };

  final Map<String, String> _industries = {
    'technology': 'Technology & Software',
    'design': 'Design & Creative',
    'marketing': 'Marketing & Advertising',
    'consulting': 'Business Consulting',
    'finance': 'Finance & Accounting',
    'healthcare': 'Healthcare',
    'education': 'Education & Training',
    'real_estate': 'Real Estate',
    'construction': 'Construction',
    'retail': 'Retail & E-commerce',
    'food_service': 'Food & Beverage',
    'professional_services': 'Professional Services',
    'manufacturing': 'Manufacturing',
    'other': 'Other',
  };

  final Map<String, String> _countries = {
    'US': 'United States',
    'CA': 'Canada',
    'GB': 'United Kingdom',
    'AU': 'Australia',
    'DE': 'Germany',
    'FR': 'France',
    'IN': 'India',
    'SG': 'Singapore',
    'JP': 'Japan',
    'BR': 'Brazil',
  };

  final Map<String, String> _currencies = {
    'USD': 'US Dollar (\$)',
    'EUR': 'Euro (€)',
    'GBP': 'British Pound (£)',
    'CAD': 'Canadian Dollar (C\$)',
    'AUD': 'Australian Dollar (A\$)',
    'INR': 'Indian Rupee (₹)',
    'SGD': 'Singapore Dollar (S\$)',
    'JPY': 'Japanese Yen (¥)',
    'BRL': 'Brazilian Real (R\$)',
  };

  final Map<String, String> _timezones = {
    'America/New_York': 'Eastern Time (ET)',
    'America/Chicago': 'Central Time (CT)',
    'America/Denver': 'Mountain Time (MT)',
    'America/Los_Angeles': 'Pacific Time (PT)',
    'America/Toronto': 'Eastern Time (Canada)',
    'Europe/London': 'Greenwich Mean Time (GMT)',
    'Europe/Paris': 'Central European Time (CET)',
    'Asia/Tokyo': 'Japan Standard Time (JST)',
    'Asia/Singapore': 'Singapore Standard Time (SGT)',
    'Asia/Kolkata': 'India Standard Time (IST)',
    'Australia/Sydney': 'Australian Eastern Time (AET)',
  };

  @override
  void dispose() {
    _businessNameController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _saveBusinessInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final businessInfo = {
        'businessName': _businessNameController.text.trim(),
        'businessType': _selectedBusinessType,
        'industry': _selectedIndustry,
        'website': _websiteController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'zipCode': _zipController.text.trim(),
        'country': _selectedCountry,
        'currency': _selectedCurrency,
        'timezone': _selectedTimezone,
      };

      final onboardingNotifier = ref.read(onboardingProvider.notifier);
      await onboardingNotifier.saveBusinessInfo(businessInfo);

      if (mounted) {
        _showSuccessMessage('Business information saved successfully');
        context.push('/onboarding/tax-settings');
      }
    } catch (e) {
      _showErrorMessage('Failed to save business information');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        title: Text(
          'Business Setup',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OnboardingProgressIndicator(
                currentPage: 1,
                totalPages: 3,
                showLabels: true,
                labels: const ['Welcome', 'Business', 'Settings'],
              ),
            ),

            const SizedBox(height: 32),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Tell us about your business',
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This helps us customize your experience and provide relevant features.',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Business Basic Info
                      _buildSectionTitle('Basic Information'),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _businessNameController,
                        label: 'Business Name',
                        hint: 'Enter your business or professional name',
                        prefixIcon: Icons.business_outlined,
                        validator: Validators.required,
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: AppDropdown<String>(
                              label: 'Business Type',
                              value: _selectedBusinessType,
                              items: _businessTypes.entries.map((entry) {
                                return DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              }).toList(),
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedBusinessType =
                                            value ?? 'freelancer';
                                      });
                                    },
                              prefixIcon: Icons.work_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppDropdown<String>(
                              label: 'Industry',
                              value: _selectedIndustry,
                              items: _industries.entries.map((entry) {
                                return DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              }).toList(),
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedIndustry =
                                            value ?? 'technology';
                                      });
                                    },
                              prefixIcon: Icons.category_outlined,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _websiteController,
                        label: 'Website (Optional)',
                        hint: 'https://yourwebsite.com',
                        prefixIcon: Icons.language_outlined,
                        keyboardType: TextInputType.url,
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 32),

                      // Location & Currency
                      _buildSectionTitle('Location & Currency'),
                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _addressController,
                        label: 'Address (Optional)',
                        hint: 'Street address',
                        prefixIcon: Icons.location_on_outlined,
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              controller: _cityController,
                              label: 'City',
                              hint: 'City',
                              enabled: !_isLoading,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _zipController,
                              label: 'ZIP Code',
                              hint: 'ZIP',
                              keyboardType: TextInputType.text,
                              enabled: !_isLoading,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      AppDropdown<String>(
                        label: 'Country',
                        value: _selectedCountry,
                        items: _countries.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedCountry = value ?? 'US';
                                });
                              },
                        prefixIcon: Icons.flag_outlined,
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: AppDropdown<String>(
                              label: 'Currency',
                              value: _selectedCurrency,
                              items: _currencies.entries.map((entry) {
                                return DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              }).toList(),
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedCurrency = value ?? 'USD';
                                      });
                                    },
                              prefixIcon: Icons.attach_money_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppDropdown<String>(
                              label: 'Timezone',
                              value: _selectedTimezone,
                              items: _timezones.entries.map((entry) {
                                return DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              }).toList(),
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedTimezone =
                                            value ?? 'America/New_York';
                                      });
                                    },
                              prefixIcon: Icons.schedule_outlined,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Help Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: AppColors.info,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Why do we need this?',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This information helps us provide accurate tax calculations, proper invoice formatting, and region-specific features.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      variant: ButtonVariant.outlined,
                      onPressed: _isLoading
                          ? null
                          : () {
                              context.push('/onboarding/tax-settings');
                            },
                      child: const Text('Skip for Now'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      onPressed: _isLoading ? null : _saveBusinessInfo,
                      child: _isLoading
                          ? const AppLoader(color: Colors.white)
                          : const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
