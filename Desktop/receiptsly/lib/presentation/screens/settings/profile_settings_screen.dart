// lib/presentation/screens/settings/profile_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();

  File? _profileImage;
  bool _isLoading = false;
  bool _emailVerificationSent = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      setState(() {
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
        // Load additional profile data from Firestore
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _profileImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmailVerification() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        setState(() {
          _emailVerificationSent = true;
        });
        _showSuccessSnackBar('Verification email sent!');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to send verification email: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update Firebase Auth profile
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());

        // Update profile image if changed
        if (_profileImage != null) {
          // Upload image to Firebase Storage
          // String imageUrl = await _uploadProfileImage();
          // await user.updatePhotoURL(imageUrl);
        }

        // Update additional profile data in Firestore
        // await _updateFirestoreProfile();

        _showSuccessSnackBar('Profile updated successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Profile Settings',
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _updateProfile,
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
              // Profile Image Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: theme.colorScheme.primary,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: _profileImage == null && user?.photoURL == null
                              ? Text(
                                  user?.displayName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      user?.email
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              onPressed: _showImagePickerOptions,
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to change profile picture',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Personal Information
              Text(
                'Personal Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: Validators.required,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              AppTextField(
                controller: _emailController,
                label: 'Email Address',
                prefixIcon: Icons.email_outlined,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                readOnly: true, // Email changes require re-authentication
                suffixIcon: user?.emailVerified == false
                    ? TextButton(
                        onPressed: _emailVerificationSent
                            ? null
                            : _sendEmailVerification,
                        child: Text(
                          _emailVerificationSent ? 'Sent' : 'Verify',
                          style: TextStyle(
                            fontSize: 12,
                            color: _emailVerificationSent
                                ? Colors.green
                                : theme.primaryColor,
                          ),
                        ),
                      )
                    : user?.emailVerified == true
                    ? const Icon(Icons.verified, color: Colors.green)
                    : null,
              ),

              if (user?.emailVerified == false) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please verify your email address to access all features',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: Icons.phone_outlined,
                validator: Validators.phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[+\-0-9\s\(\)]')),
                ],
              ),

              const SizedBox(height: 32),

              // Address Information
              Text(
                'Address Information',
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
                      label: 'State',
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
                      label: 'ZIP Code',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      controller: _countryController,
                      label: 'Country',
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Security Section
              Text(
                'Security',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Change Password'),
                      subtitle: const Text('Update your account password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to change password screen
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.security_outlined),
                      title: const Text('Two-Factor Authentication'),
                      subtitle: const Text('Add an extra layer of security'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to 2FA setup
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.devices_outlined),
                      title: const Text('Manage Sessions'),
                      subtitle: const Text('View and manage active sessions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to sessions management
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              AppButton(
                onPressed: _isLoading ? null : _updateProfile,
                isLoading: _isLoading,
                child: const Text('Save Changes'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
