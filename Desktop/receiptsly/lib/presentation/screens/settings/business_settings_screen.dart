// lib/presentation/screens/settings/business_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/business_provider.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/app_dropdown.dart';

class BusinessSettingsScreen extends ConsumerStatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  ConsumerState<BusinessSettingsScreen> createState() =>
      _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState
    extends ConsumerState<BusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedCurrency = 'USD';
  String _selectedTimeZone = 'UTC';
  String _selectedBusinessType = 'freelancer';
  String _selectedTaxSystem = 'percentage';
  double _defaultTaxRate = 0.0;
  bool _isLoading = false;

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'JPY',
    'CHF',
    'CNY',
    'INR',
    'BRL',
  ];

  final List<String> _businessTypes = [
    'freelancer',
    'consultant',
    'contractor',
    'agency',
    'retail',
    'restaurant',
    'service',
    'manufacturing',
    'non_profit',
    'other',
  ];

  final List<String> _taxSystems = [
    'percentage',
    'fixed_amount',
    'tax_inclusive',
    'tax_exempt',
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessSettings();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _taxIdController.dispose();
    _registrationNumberController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessSettings() async {
    // Load business settings from provider/Firestore
    // This is a placeholder - implement actual loading logic
    setState(() {
      // Load saved values
      _businessNameController.text = 'My Business';
      _selectedCurrency = 'USD';
      _selectedBusinessType = 'freelancer';
      _defaultTaxRate = 8.5;
    });
  }

  Future<void> _saveBusinessSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final businessData = {
        'businessName': _businessNameController.text.trim(),
        'businessType': _selectedBusinessType,
        'taxId': _taxIdController.text.trim(),
        'registrationNumber': _registrationNumberController.text.trim(),
        'website': _websiteController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zipCode': _zipCodeController.text.trim(),
        'country': _countryController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'currency': _selectedCurrency,
        'timeZone': _selectedTimeZone,
        'taxSystem': _selectedTaxSystem,
        'defaultTaxRate': _defaultTaxRate,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Save to Firestore through provider
      // await ref.read(businessProvider.notifier).updateBusinessSettings(businessData);

      _showSuccessSnackBar('Business settings saved successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Failed to save business settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _getBusinessTypeLabel(String type) {
    switch (type) {
      case 'freelancer':
        return 'Freelancer';
      case 'consultant':
        return 'Consultant';
      case 'contractor':
        return 'Contractor';
      case 'agency':
        return 'Agency';
      case 'retail':
        return 'Retail';
      case 'restaurant':
        return 'Restaurant';
      case 'service':
        return 'Service Business';
      case 'manufacturing':
        return 'Manufacturing';
      case 'non_profit':
        return 'Non-Profit';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  String _getTaxSystemLabel(String system) {
    switch (system) {
      case 'percentage':
        return 'Percentage Based';
      case 'fixed_amount':
        return 'Fixed Amount';
      case 'tax_inclusive':
        return 'Tax Inclusive';
      case 'tax_exempt':
        return 'Tax Exempt';
      default:
        return system;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Business Settings',
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _saveBusinessSettings,
          child: const Text('SAVE'),
        ),
      ],
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Information
              Text(
                'Business Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _businessNameController,
                label: 'Business Name *',
                prefixIcon: Icons.business_outlined,
                validator: Validators.required,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              AppDropdown<String>(
                value: _selectedBusinessType,
                label: 'Business Type',
                prefixIcon: Icons.category_outlined,
                items: _businessTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_getBusinessTypeLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedBusinessType = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _taxIdController,
                      label: 'Tax ID / EIN',
                      prefixIcon: Icons.account_balance_outlined,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9\-]'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _registrationNumberController,
                      label: 'Registration Number',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: _websiteController,
                label: 'Website URL',
                prefixIcon: Icons.language_outlined,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    return Validators.url(value);
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Business Address
              Text(
                'Business Address',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _addressController,
                label: 'Street Address',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      controller: _cityController,
                      label: 'City',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _stateController,
                      label: 'State/Province',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _zipCodeController,
                      label: 'ZIP/Postal Code',
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      controller: _countryController,
                      label: 'Country',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Contact Information
              Text(
                'Contact Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _phoneController,
                label: 'Business Phone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[+\-0-9\s\(\)]')),
                ],
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: _emailController,
                label: 'Business Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    return Validators.email(value);
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Financial Settings
              Text(
                'Financial Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              AppDropdown<String>(
                value: _selectedCurrency,
                label: 'Default Currency',
                prefixIcon: Icons.attach_money_outlined,
                items: _currencies
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCurrency = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              AppDropdown<String>(
                value: _selectedTaxSystem,
                label: 'Tax System',
                prefixIcon: Icons.calculate_outlined,
                items: _taxSystems
                    .map(
                      (system) => DropdownMenuItem(
                        value: system,
                        child: Text(_getTaxSystemLabel(system)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTaxSystem = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              if (_selectedTaxSystem == 'percentage') ...[
                AppTextField(
                  label: 'Default Tax Rate (%)',
                  prefixIcon: Icons.percent_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  initialValue: _defaultTaxRate.toString(),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final rate = double.tryParse(value);
                    if (rate == null || rate < 0 || rate > 100) {
                      return 'Enter a valid tax rate between 0 and 100';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final rate = double.tryParse(value);
                    if (rate != null) {
                      _defaultTaxRate = rate;
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'This rate will be applied to new invoices by default',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Invoice Settings
              Text(
                'Invoice Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Auto-generate Invoice Numbers'),
                      subtitle: const Text(
                        'Automatically create sequential invoice numbers',
                      ),
                      value: true,
                      onChanged: (value) {
                        // Handle toggle
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Send Payment Reminders'),
                      subtitle: const Text(
                        'Automatically remind clients of overdue payments',
                      ),
                      value: true,
                      onChanged: (value) {
                        // Handle toggle
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Payment Terms'),
                      subtitle: const Text('Net 30 days'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Open payment terms settings
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Invoice Template'),
                      subtitle: const Text('Customize your invoice appearance'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Open template customization
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Expense Categories
              Text(
                'Expense Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Manage Categories'),
                      subtitle: const Text(
                        'Add, edit, or remove expense categories',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to category management
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Default Category'),
                      subtitle: const Text('General'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Select default category
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              AppButton(
                onPressed: _isLoading ? null : _saveBusinessSettings,
                isLoading: _isLoading,
                child: const Text('Save Business Settings'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
