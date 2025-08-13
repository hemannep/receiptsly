// lib/core/utils/validators.dart
import 'dart:io';

/// Comprehensive validation utilities for Receiptsly app
/// Provides validation for emails, phones, business data, receipts, etc.
class Validators {
  // Email validation
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );

    return emailRegex.hasMatch(email.trim()) &&
        email.length <= 254 &&
        !email.contains('..') &&
        !email.startsWith('.') &&
        !email.endsWith('.');
  }

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    email = email.trim();

    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;

    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;

    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) return false;

    // Check for at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) return false;

    // Check for at least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;

    return true;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (password.length > 128) {
      return 'Password must be less than 128 characters';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    // Check for common weak patterns
    if (_hasWeakPatterns(password)) {
      return 'Password contains weak patterns. Please choose a stronger password';
    }

    return null;
  }

  static bool _hasWeakPatterns(String password) {
    final weakPatterns = [
      'password',
      '12345678',
      'qwerty',
      'abc123',
      'password123',
      '123456789',
      'admin123',
    ];

    final lowerPassword = password.toLowerCase();
    return weakPatterns.any((pattern) => lowerPassword.contains(pattern));
  }

  // Phone number validation
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;

    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check length (7-15 digits for international numbers)
    if (digitsOnly.length < 7 || digitsOnly.length > 15) return false;

    // Basic format validation with country codes
    final phoneRegex = RegExp(r'^\+?[1-9]\d{6,14}$');
    return phoneRegex.hasMatch(digitsOnly);
  }

  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }

    phone = phone.trim();

    if (!isValidPhoneNumber(phone)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? name, {String fieldName = 'Name'}) {
    if (name == null || name.isEmpty) {
      return '$fieldName is required';
    }

    name = name.trim();

    if (name.length < 2) {
      return '$fieldName must be at least 2 characters long';
    }

    if (name.length > 50) {
      return '$fieldName must be less than 50 characters';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  // Business name validation
  static String? validateBusinessName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Business name is required';
    }

    name = name.trim();

    if (name.length < 2) {
      return 'Business name must be at least 2 characters long';
    }

    if (name.length > 100) {
      return 'Business name must be less than 100 characters';
    }

    // Allow alphanumeric, spaces, and common business characters
    if (!RegExp(r"^[a-zA-Z0-9\s\-'&.,()]+$").hasMatch(name)) {
      return 'Business name contains invalid characters';
    }

    return null;
  }

  // Amount/Currency validation
  static bool isValidAmount(String amount) {
    if (amount.isEmpty) return false;

    // Remove currency symbols and whitespace
    final cleanAmount = amount.replaceAll(RegExp(r'[\$,\s]'), '');

    // Check if it's a valid decimal number
    final amountRegex = RegExp(r'^\d+(\.\d{1,2})?$');

    if (!amountRegex.hasMatch(cleanAmount)) return false;

    final numericValue = double.tryParse(cleanAmount);
    return numericValue != null &&
        numericValue >= 0 &&
        numericValue <= 999999.99;
  }

  static String? validateAmount(String? amount, {String fieldName = 'Amount'}) {
    if (amount == null || amount.isEmpty) {
      return '$fieldName is required';
    }

    if (!isValidAmount(amount)) {
      return 'Please enter a valid $fieldName (e.g., 10.99)';
    }

    final cleanAmount = amount.replaceAll(RegExp(r'[\$,\s]'), '');
    final numericValue = double.tryParse(cleanAmount);

    if (numericValue == null) {
      return 'Please enter a valid numeric $fieldName';
    }

    if (numericValue < 0) {
      return '$fieldName cannot be negative';
    }

    if (numericValue > 999999.99) {
      return '$fieldName cannot exceed \$999,999.99';
    }

    return null;
  }

  // Receipt vendor validation
  static String? validateVendor(String? vendor) {
    if (vendor == null || vendor.isEmpty) {
      return 'Vendor name is required';
    }

    vendor = vendor.trim();

    if (vendor.length < 2) {
      return 'Vendor name must be at least 2 characters long';
    }

    if (vendor.length > 100) {
      return 'Vendor name must be less than 100 characters';
    }

    return null;
  }

  // Category validation
  static String? validateCategory(String? category) {
    if (category == null || category.isEmpty) {
      return 'Category is required';
    }

    final validCategories = [
      'Food & Dining',
      'Transportation',
      'Office Supplies',
      'Software & Technology',
      'Marketing & Advertising',
      'Travel & Accommodation',
      'Professional Services',
      'Equipment & Tools',
      'Utilities',
      'Insurance',
      'Training & Education',
      'Health & Medical',
      'General',
      'Other',
    ];

    if (!validCategories.contains(category)) {
      return 'Please select a valid category';
    }

    return null;
  }

  // Date validation
  static String? validateDate(DateTime? date, {String fieldName = 'Date'}) {
    if (date == null) {
      return '$fieldName is required';
    }

    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    final oneYearFromNow = DateTime(now.year + 1, now.month, now.day);

    if (date.isBefore(oneYearAgo)) {
      return '$fieldName cannot be more than one year in the past';
    }

    if (date.isAfter(oneYearFromNow)) {
      return '$fieldName cannot be more than one year in the future';
    }

    return null;
  }

  // Invoice number validation
  static String? validateInvoiceNumber(String? invoiceNumber) {
    if (invoiceNumber == null || invoiceNumber.isEmpty) {
      return 'Invoice number is required';
    }

    invoiceNumber = invoiceNumber.trim();

    if (invoiceNumber.length < 3) {
      return 'Invoice number must be at least 3 characters long';
    }

    if (invoiceNumber.length > 20) {
      return 'Invoice number must be less than 20 characters';
    }

    // Allow alphanumeric and common separators
    if (!RegExp(r'^[a-zA-Z0-9\-_#]+$').hasMatch(invoiceNumber)) {
      return 'Invoice number can only contain letters, numbers, hyphens, underscores, and #';
    }

    return null;
  }

  // File validation
  static String? validateImageFile(File? file) {
    if (file == null) {
      return 'Please select an image file';
    }

    if (!file.existsSync()) {
      return 'Selected file does not exist';
    }

    final fileSize = file.lengthSync();
    const maxSizeInBytes = 10 * 1024 * 1024; // 10MB

    if (fileSize > maxSizeInBytes) {
      return 'Image file size cannot exceed 10MB';
    }

    final fileName = file.path.toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];

    if (!validExtensions.any((ext) => fileName.endsWith(ext))) {
      return 'Please select a valid image file (JPG, PNG, GIF, BMP, WebP)';
    }

    return null;
  }

  // URL validation
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  static String? validateUrl(String? url, {String fieldName = 'URL'}) {
    if (url == null || url.isEmpty) {
      return '$fieldName is required';
    }

    if (!isValidUrl(url)) {
      return 'Please enter a valid $fieldName';
    }

    return null;
  }

  // Tax rate validation
  static String? validateTaxRate(String? taxRate) {
    if (taxRate == null || taxRate.isEmpty) {
      return null; // Tax rate is optional
    }

    final rate = double.tryParse(taxRate);

    if (rate == null) {
      return 'Please enter a valid tax rate';
    }

    if (rate < 0) {
      return 'Tax rate cannot be negative';
    }

    if (rate > 100) {
      return 'Tax rate cannot exceed 100%';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Generic text validation with length constraints
  static String? validateText(
    String? text,
    String fieldName, {
    int minLength = 1,
    int maxLength = 255,
    bool required = true,
    String? pattern,
  }) {
    if (text == null || text.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    text = text.trim();

    if (text.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }

    if (text.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }

    if (pattern != null && !RegExp(pattern).hasMatch(text)) {
      return '$fieldName contains invalid characters';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Client contact validation
  static String? validateClientEmail(String? email) {
    if (email == null || email.isEmpty) {
      return null; // Client email is optional
    }

    return validateEmail(email);
  }

  // Notes validation
  static String? validateNotes(String? notes) {
    if (notes == null || notes.isEmpty) {
      return null; // Notes are optional
    }

    if (notes.length > 1000) {
      return 'Notes must be less than 1000 characters';
    }

    return null;
  }

  // Receipt description validation
  static String? validateReceiptDescription(String? description) {
    if (description == null || description.isEmpty) {
      return null; // Description is optional
    }

    description = description.trim();

    if (description.length > 200) {
      return 'Description must be less than 200 characters';
    }

    return null;
  }

  // Discount validation
  static String? validateDiscount(String? discount, double subtotal) {
    if (discount == null || discount.isEmpty) {
      return null; // Discount is optional
    }

    final discountValue = double.tryParse(discount);

    if (discountValue == null) {
      return 'Please enter a valid discount amount';
    }

    if (discountValue < 0) {
      return 'Discount cannot be negative';
    }

    if (discountValue > subtotal) {
      return 'Discount cannot exceed subtotal amount';
    }

    return null;
  }

  // Batch validation for multiple fields
  static Map<String, String> validateReceiptData(Map<String, dynamic> data) {
    final errors = <String, String>{};

    final vendorError = validateVendor(data['vendor']);
    if (vendorError != null) errors['vendor'] = vendorError;

    final amountError = validateAmount(data['amount']?.toString());
    if (amountError != null) errors['amount'] = amountError;

    final categoryError = validateCategory(data['category']);
    if (categoryError != null) errors['category'] = categoryError;

    final dateError = validateDate(data['date']);
    if (dateError != null) errors['date'] = dateError;

    final descriptionError = validateReceiptDescription(data['description']);
    if (descriptionError != null) errors['description'] = descriptionError;

    return errors;
  }

  // Business registration validation
  static Map<String, String> validateBusinessRegistration(
    Map<String, dynamic> data,
  ) {
    final errors = <String, String>{};

    final nameError = validateName(data['name'], fieldName: 'Full name');
    if (nameError != null) errors['name'] = nameError;

    final emailError = validateEmail(data['email']);
    if (emailError != null) errors['email'] = emailError;

    final passwordError = validatePassword(data['password']);
    if (passwordError != null) errors['password'] = passwordError;

    final confirmPasswordError = validateConfirmPassword(
      data['password'],
      data['confirmPassword'],
    );
    if (confirmPasswordError != null)
      errors['confirmPassword'] = confirmPasswordError;

    final businessNameError = validateBusinessName(data['businessName']);
    if (businessNameError != null) errors['businessName'] = businessNameError;

    return errors;
  }
}
