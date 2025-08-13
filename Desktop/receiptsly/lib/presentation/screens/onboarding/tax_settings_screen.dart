// lib/presentation/screens/onboarding/tax_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../presentation/providers/onboarding_provider.dart';
import '../../../presentation/widgets/common/app_button.dart';
import '../../../presentation/widgets/common/app_text_field.dart';
import '../../../presentation/widgets/common/app_dropdown.dart';
import '../../../presentation/widgets/common/app_loader.dart';
import '../../../presentation/widgets/common/app_snackbar.dart';
import 'widgets/progress_indicator.dart';

class TaxSettingsScreen extends ConsumerStatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  ConsumerState<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends ConsumerState<TaxSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taxIdController = TextEditingController();
  final _businessLicenseController = TextEditingController();

  bool _isLoading = false;
  bool _enableTaxCalculation = true;
  String _taxStructure = 'sole_proprietorship';
  String _fiscalYearEnd = 'december';
  double _defaultTaxRate = 0.0;

  final Map<String, String> _taxStructures = {
    'sole_proprietorship': 'Sole Proprietorship',
    'llc': 'LLC (Limited Liability Company)',
    'corporation': 'Corporation (C-Corp)',
    's_corporation': 'S-Corporation',
    'partnership': 'Partnership',
    'nonprofit': 'Non-profit Organization',
    'other': 'Other',
  };

  final Map<String, String> _fiscalYears = {
    'january': 'January 31',
    'february': 'February 28',
    'march': 'March 31',
    'april': 'April 30',
    'may': 'May 31',
    'june': 'June 30',
    'july': 'July 31',
    'august': 'August 31',
    'september': 'September 30',
    'october': 'October 31',
    'november': 'November 30',
    'december': 'December 31',
  };

  final List<TaxCategory> _taxCategories = [
    TaxCategory(
      id: 'office_supplies',
      name: 'Office Supplies',
      isDeductible: true,
      description: 'Pens, paper, software, etc.',
    ),
    TaxCategory(
      id: 'travel',
      name: 'Business Travel',
      isDeductible: true,
      description: 'Flights, hotels, meals while traveling',
    ),
    TaxCategory(
      id: 'meals',
      name: 'Business Meals',
      isDeductible: true,
      deductionPercentage: 50,
      description: 'Client dinners, business lunches',
    ),
    TaxCategory(
      id: 'equipment',
      name: 'Equipment & Tools',
      isDeductible: true,
      description: 'Computers, cameras, professional tools',
    ),
    TaxCategory(
      id: 'professional_services',
      name: 'Professional Services',
      isDeductible: true,
      description: 'Legal, accounting, consulting fees',
    ),
    TaxCategory(
      id: 'marketing',
      name: 'Marketing & Advertising',
      isDeductible: true,
      description: 'Online ads, business cards, website costs',
    ),
  ];

  @override
  void dispose() {
    _taxIdController.dispose();
    _businessLicenseController.dispose();
    super.dispose();
  }

  Future<void> _saveTaxSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final taxSettings = {
        'enableTaxCalculation': _enableTaxCalculation,
        'taxStructure': _taxStructure,
        'fiscalYearEnd': _fiscalYearEnd,
        'defaultTaxRate': _defaultTaxRate,
        'taxId': _taxIdController.text.trim(),
        'businessLicense': _businessLicenseController.text.trim(),
        'taxCategories': _taxCategories
            .map(
              (category) => {
                'id': category.id,
                'name': category.name,
                'isDeductible': category.isDeductible,
                'deductionPercentage': category.deductionPercentage,
                'description': category.description,
              },
            )
            .toList(),
      };

      final onboardingNotifier = ref.read(onboardingProvider.notifier);
      await onboardingNotifier.saveTaxSettings(taxSettings);

      if (mounted) {
        _showSuccessMessage('Tax settings saved successfully');
        context.push('/onboarding/chat-integration');
      }
    } catch (e) {
      _showErrorMessage('Failed to save tax settings');
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
          'Tax Settings',
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
                currentPage: 2,
                totalPages: 3,
                showLabels: true,
                labels: const ['Welcome', 'Business', 'Tax & Chat'],
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
                        'Tax & Deduction Settings',
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set up tax calculations and expense categorization for better financial management.',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Enable Tax Calculation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Enable Tax Calculations',
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Automatically calculate taxes and track deductible expenses',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _enableTaxCalculation,
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _enableTaxCalculation = value;
                                      });
                                    },
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),

                      if (_enableTaxCalculation) ...[
                        const SizedBox(height: 24),

                        // Business Structure
                        _buildSectionTitle('Business Structure'),
                        const SizedBox(height: 16),

                        AppDropdown<String>(
                          label: 'Tax Structure',
                          value: _taxStructure,
                          items: _taxStructures.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _taxStructure =
                                        value ?? 'sole_proprietorship';
                                  });
                                },
                          prefixIcon: Icons.account_balance_outlined,
                        ),

                        const SizedBox(height: 16),

                        AppDropdown<String>(
                          label: 'Fiscal Year End',
                          value: _fiscalYearEnd,
                          items: _fiscalYears.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _fiscalYearEnd = value ?? 'december';
                                  });
                                },
                          prefixIcon: Icons.calendar_today_outlined,
                        ),

                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _taxIdController,
                          label: 'Tax ID / EIN (Optional)',
                          hint: 'Enter your tax identification number',
                          prefixIcon: Icons.badge_outlined,
                          enabled: !_isLoading,
                        ),

                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _businessLicenseController,
                          label: 'Business License (Optional)',
                          hint: 'Enter your business license number',
                          prefixIcon: Icons.card_membership_outlined,
                          enabled: !_isLoading,
                        ),

                        const SizedBox(height: 24),

                        // Default Tax Rate
                        _buildSectionTitle('Default Tax Rate'),
                        const SizedBox(height: 8),
                        Text(
                          'This will be used for estimated tax calculations',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          label: 'Default Tax Rate (%)',
                          hint: 'e.g., 25',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.percent_outlined,
                          initialValue: _defaultTaxRate.toString(),
                          onChanged: (value) {
                            _defaultTaxRate = double.tryParse(value) ?? 0.0;
                          },
                          enabled: !_isLoading,
                        ),

                        const SizedBox(height: 24),

                        // Tax Categories
                        _buildSectionTitle('Expense Categories'),
                        const SizedBox(height: 8),
                        Text(
                          'Configure which expense types are tax deductible',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        ..._taxCategories.map(
                          (category) => _buildTaxCategoryTile(category),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Disclaimer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_outlined,
                              color: AppColors.warning,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tax Disclaimer',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This tool provides estimates only. Please consult with a qualified tax professional for accurate tax advice and filing.',
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
                              context.push('/onboarding/chat-integration');
                            },
                      child: const Text('Skip for Now'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      onPressed: _isLoading ? null : _saveTaxSettings,
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

  Widget _buildTaxCategoryTile(TaxCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: category.isDeductible
              ? AppColors.success.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      category.name,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (category.deductionPercentage != null &&
                        category.deductionPercentage! < 100) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${category.deductionPercentage}%',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  category.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: category.isDeductible,
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      category.isDeductible = value;
                    });
                  },
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class TaxCategory {
  final String id;
  final String name;
  final String description;
  bool isDeductible;
  final int? deductionPercentage;

  TaxCategory({
    required this.id,
    required this.name,
    required this.description,
    this.isDeductible = false,
    this.deductionPercentage,
  });
}
