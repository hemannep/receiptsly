// lib/presentation/screens/client/widgets/client_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/app_dropdown.dart';

class ClientForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback? onChanged;
  final bool isEditMode;

  const ClientForm({
    super.key,
    this.initialData,
    this.onChanged,
    this.isEditMode = false,
  });

  @override
  State<ClientForm> createState() => ClientFormState();
}

class ClientFormState extends State<ClientForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _companyController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipCodeController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _notesController;
  
  // Dropdown values
  String _selectedCountry = 'United States';
  String _selectedCurrency = 'USD';
  int _paymentTerms = 30;
  
  // Focus nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _companyFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _stateFocus = FocusNode();
  final FocusNode _zipCodeFocus = FocusNode();
  final FocusNode _taxIdFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupListeners();
  }

  void _initializeControllers() {
    final data = widget.initialData ?? <String, dynamic>{};
    
    _nameController = TextEditingController(text: data['name'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _companyController = TextEditingController(text: data['company'] ?? '');
    _addressController = TextEditingController(text: data['address'] ?? '');
    _cityController = TextEditingController(text: data['city'] ?? '');
    _stateController = TextEditingController(text: data['state'] ?? '');
    _zipCodeController = TextEditingController(text: data['zipCode'] ?? '');
    _taxIdController = TextEditingController(text: data['taxId'] ?? '');
    _notesController = TextEditingController(text: data['notes'] ?? '');
    
    _selectedCountry = data['country'] ?? 'United States';
    _selectedCurrency = data['currency'] ?? 'USD';
    _paymentTerms = data['paymentTerms'] ?? 30;
  }

  void _setupListeners() {
    final controllers = [
      _nameController,
      _emailController,
      _phoneController,
      _companyController,
      _addressController,
      _cityController,
      _stateController,
      _zipCodeController,
      _taxIdController,
      _notesController,
    ];

    for (final controller in controllers) {
      controller.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    widget.onChanged?.call();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _taxIdController.dispose();
    _notesController.dispose();
    
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _companyFocus.dispose();
    _addressFocus.dispose();
    _cityFocus.dispose();
    _stateFocus.dispose();
    _zipCodeFocus.dispose();
    _taxIdFocus.dispose();
    _notesFocus.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Section
          _buildSectionHeader(theme, 'Basic Information', Icons.person),
          const SizedBox(height: 16),
          _buildBasicInformationSection(),
          
          const SizedBox(height: 32),
          
          // Contact Information Section
          _buildSectionHeader(theme, 'Contact Information', Icons.contact_mail),
          const SizedBox(height: 16),
          _buildContactInformationSection(),
          
          const SizedBox(height: 32),
          
          // Address Information Section
          _buildSectionHeader(theme, 'Address Information', Icons.location_on),
          const SizedBox(height: 16),
          _buildAddressInformationSection(),
          
          const SizedBox(height: 32),
          
          // Business Information Section
          _buildSectionHeader(theme, 'Business Information', Icons.business),
          const SizedBox(height: 16),
          _buildBusinessInformationSection(),
          
          const SizedBox(height: 32),
          
          // Additional Information Section
          _buildSectionHeader(theme, 'Additional Information', Icons.note),
          const SizedBox(height: 16),
          _buildAdditionalInformationSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInformationSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                controller: _nameController,
                focusNode: _nameFocus,
                labelText: 'Full Name',
                hintText: 'Enter client full name',
                prefixIcon: const Icon(Icons.person),
                validator: Validators.required,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _companyFocus.requestFocus(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                controller: _stateController,
                focusNode: _stateFocus,
                labelText: 'State/Province',
                hintText: 'Enter state',
                prefixIcon: const Icon(Icons.map),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _zipCodeFocus.requestFocus(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                controller: _zipCodeController,
                focusNode: _zipCodeFocus,
                labelText: 'ZIP/Postal Code',
                hintText: 'Enter ZIP code',
                prefixIcon: const Icon(Icons.local_post_office),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _taxIdFocus.requestFocus(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-]')),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        AppDropdown<String>(
          value: _selectedCountry,
          labelText: 'Country',
          hintText: 'Select country',
          prefixIcon: const Icon(Icons.public),
          items: AppConstants.countries.map((country) {
            return DropdownMenuItem<String>(
              value: country,
              child: Text(country),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCountry = value!;
            });
            _onFormChanged();
          },
          validator: (value) => value == null ? 'Please select a country' : null,
        ),
      ],
    );
  }

  Widget _buildBusinessInformationSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _taxIdController,
                focusNode: _taxIdFocus,
                labelText: 'Tax ID/VAT Number',
                hintText: 'Enter tax ID (optional)',
                prefixIcon: const Icon(Icons.receipt_long),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppDropdown<String>(
                value: _selectedCurrency,
                labelText: 'Currency',
                hintText: 'Select currency',
                prefixIcon: const Icon(Icons.monetization_on),
                items: AppConstants.currencies.map((currency) {
                  return DropdownMenuItem<String>(
                    value: currency['code'],
                    child: Row(
                      children: [
                        Text(currency['symbol']),
                        const SizedBox(width: 8),
                        Text('${currency['code']} - ${currency['name']}'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                  _onFormChanged();
                },
                validator: (value) => value == null ? 'Please select a currency' : null,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        AppDropdown<int>(
          value: _paymentTerms,
          labelText: 'Payment Terms',
          hintText: 'Select payment terms',
          prefixIcon: const Icon(Icons.schedule),
          items: AppConstants.paymentTerms.map((terms) {
            return DropdownMenuItem<int>(
              value: terms['value'],
              child: Text(terms['label']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _paymentTerms = value!;
            });
            _onFormChanged();
          },
          validator: (value) => value == null ? 'Please select payment terms' : null,
        ),
      ],
    );
  }

  Widget _buildAdditionalInformationSection() {
    return Column(
      children: [
        AppTextField(
          controller: _notesController,
          focusNode: _notesFocus,
          labelText: 'Notes',
          hintText: 'Add any additional notes about this client (optional)',
          prefixIcon: const Icon(Icons.note),
          maxLines: 4,
          textInputAction: TextInputAction.done,
          maxLength: 500,
        ),
        
        const SizedBox(height: 24),
        
        // Form Tips
        _buildFormTips(),
      ],
    );
  }

  Widget _buildFormTips() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tips',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildTipItem(
            theme,
            'Complete contact information helps with invoice delivery',
          ),
          _buildTipItem(
            theme,
            'Tax ID is required for international clients',
          ),
          _buildTipItem(
            theme,
            'Payment terms affect invoice due dates automatically',
          ),
          _buildTipItem(
            theme,
            'Use notes to remember client preferences or special requirements',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(ThemeData theme, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Public methods for parent widgets
  bool isValid() {
    return _formKey.currentState?.validate() ?? false;
  }

  Map<String, dynamic>? getClientData() {
    if (!isValid()) return null;
    
    return {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'company': _companyController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'zipCode': _zipCodeController.text.trim(),
      'country': _selectedCountry,
      'taxId': _taxIdController.text.trim(),
      'currency': _selectedCurrency,
      'paymentTerms': _paymentTerms,
      'notes': _notesController.text.trim(),
    };
  }

  void reset() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _companyController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _zipCodeController.clear();
    _taxIdController.clear();
    _notesController.clear();
    
    setState(() {
      _selectedCountry = 'United States';
      _selectedCurrency = 'USD';
      _paymentTerms = 30;
    });
  }

  void updateData(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _companyController.text = data['company'] ?? '';
    _addressController.text = data['address'] ?? '';
    _cityController.text = data['city'] ?? '';
    _stateController.text = data['state'] ?? '';
    _zipCodeController.text = data['zipCode'] ?? '';
    _taxIdController.text = data['taxId'] ?? '';
    _notesController.text = data['notes'] ?? '';
    
    setState(() {
      _selectedCountry = data['country'] ?? 'United States';
      _selectedCurrency = data['currency'] ?? 'USD';
      _paymentTerms = data['paymentTerms'] ?? 30;
    });
    
    _onFormChanged();
  }

  // Auto-fill methods for smart form completion
  void autoFillFromContact(Map<String, dynamic> contactData) {
    if (contactData['name'] != null) {
      _nameController.text = contactData['name'];
    }
    if (contactData['email'] != null) {
      _emailController.text = contactData['email'];
    }
    if (contactData['phone'] != null) {
      _phoneController.text = contactData['phone'];
    }
    if (contactData['company'] != null) {
      _companyController.text = contactData['company'];
    }
    
    _onFormChanged();
  }

  void setFieldFocus(String fieldName) {
    switch (fieldName) {
      case 'name':
        _nameFocus.requestFocus();
        break;
      case 'email':
        _emailFocus.requestFocus();
        break;
      case 'phone':
        _phoneFocus.requestFocus();
        break;
      case 'company':
        _companyFocus.requestFocus();
        break;
      case 'address':
        _addressFocus.requestFocus();
        break;
      case 'city':
        _cityFocus.requestFocus();
        break;
      case 'state':
        _stateFocus.requestFocus();
        break;
      case 'zipCode':
        _zipCodeFocus.requestFocus();
        break;
      case 'taxId':
        _taxIdFocus.requestFocus();
        break;
      case 'notes':
        _notesFocus.requestFocus();
        break;
    }
  }

  // Validation helpers
  bool get hasRequiredFields {
    return _nameController.text.trim().isNotEmpty &&
           _emailController.text.trim().isNotEmpty;
  }

  List<String> get incompleteFields {
    final incomplete = <String>[];
    
    if (_nameController.text.trim().isEmpty) incomplete.add('Name');
    if (_emailController.text.trim().isEmpty) incomplete.add('Email');
    if (_phoneController.text.trim().isEmpty) incomplete.add('Phone');
    
    return incomplete;
  }

  double get completionPercentage {
    int filledFields = 0;
    const totalFields = 10;
    
    if (_nameController.text.trim().isNotEmpty) filledFields++;
    if (_emailController.text.trim().isNotEmpty) filledFields++;
    if (_phoneController.text.trim().isNotEmpty) filledFields++;
    if (_companyController.text.trim().isNotEmpty) filledFields++;
    if (_addressController.text.trim().isNotEmpty) filledFields++;
    if (_cityController.text.trim().isNotEmpty) filledFields++;
    if (_stateController.text.trim().isNotEmpty) filledFields++;
    if (_zipCodeController.text.trim().isNotEmpty) filledFields++;
    if (_taxIdController.text.trim().isNotEmpty) filledFields++;
    if (_notesController.text.trim().isNotEmpty) filledFields++;
    
    return filledFields / totalFields;
  }
}width: 16),
            Expanded(
              child: AppTextField(
                controller: _companyController,
                focusNode: _companyFocus,
                labelText: 'Company',
                hintText: 'Company name',
                prefixIcon: const Icon(Icons.business),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _emailFocus.requestFocus(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInformationSection() {
    return Column(
      children: [
        AppTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          labelText: 'Email Address',
          hintText: 'Enter email address',
          prefixIcon: const Icon(Icons.email),
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _phoneFocus.requestFocus(),
        ),
        
        const SizedBox(height: 16),
        
        AppTextField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          labelText: 'Phone Number',
          hintText: 'Enter phone number',
          prefixIcon: const Icon(Icons.phone),
          keyboardType: TextInputType.phone,
          validator: Validators.phone,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _addressFocus.requestFocus(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-\+\(\)]')),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressInformationSection() {
    return Column(
      children: [
        AppTextField(
          controller: _addressController,
          focusNode: _addressFocus,
          labelText: 'Street Address',
          hintText: 'Enter street address',
          prefixIcon: const Icon(Icons.home),
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _cityFocus.requestFocus(),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _cityController,
                focusNode: _cityFocus,
                labelText: 'City',
                hintText: 'Enter city',
                prefixIcon: const Icon(Icons.location_city),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _stateFocus.requestFocus(),
              ),
            ),
            const SizedBox(