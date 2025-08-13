// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/common/app_scaffold.dart';
import 'widgets/settings_tile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _autoSyncEnabled = true;
  String _selectedTheme = 'system';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from SharedPreferences or user profile
    // This is a placeholder - implement actual loading logic
    setState(() {
      // Load actual values here
    });
  }

  Future<void> _showSignOutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(authServiceProvider).signOut();
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone. All your data will be permanently deleted.',
            ),
            SizedBox(height: 16),
            Text(
              'This includes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• All receipts and expenses'),
            Text('• All invoices and clients'),
            Text('• All reports and data'),
            Text('• Account settings and preferences'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Implement account deletion
      // This should be handled by a backend function
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account deletion requested. You will receive a confirmation email.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Settings',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.primaryColor,
                      child: Text(
                        user?.displayName?.substring(0, 1).toUpperCase() ??
                            user?.email?.substring(0, 1).toUpperCase() ??
                            'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'User',
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            user?.email ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (user?.emailVerified == false) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Email not verified',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/settings/profile'),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Account Settings
            Text(
              'Account',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.person_outline,
                    title: 'Profile Settings',
                    subtitle: 'Manage your personal information',
                    onTap: () => context.push('/settings/profile'),
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.business_outline,
                    title: 'Business Settings',
                    subtitle: 'Company details and tax settings',
                    onTap: () => context.push('/settings/business'),
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.credit_card_outlined,
                    title: 'Subscription',
                    subtitle: 'Manage your billing and subscription',
                    onTap: () => context.push('/settings/subscription'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Settings
            Text(
              'App Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Enable push notifications',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        // Save setting
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.fingerprint_outlined,
                    title: 'Biometric Authentication',
                    subtitle: 'Use fingerprint or face ID',
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: (value) {
                        setState(() {
                          _biometricEnabled = value;
                        });
                        // Save setting
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.sync_outlined,
                    title: 'Auto Sync',
                    subtitle: 'Automatically sync data when online',
                    trailing: Switch(
                      value: _autoSyncEnabled,
                      onChanged: (value) {
                        setState(() {
                          _autoSyncEnabled = value;
                        });
                        // Save setting
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Theme',
                    subtitle: 'Choose app appearance',
                    trailing: DropdownButton<String>(
                      value: _selectedTheme,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'light', child: Text('Light')),
                        DropdownMenuItem(value: 'dark', child: Text('Dark')),
                        DropdownMenuItem(
                          value: 'system',
                          child: Text('System'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTheme = value;
                          });
                          // Save setting and apply theme
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.sync_alt_outlined,
                    title: 'Sync Settings',
                    subtitle: 'Manage data synchronization',
                    onTap: () => context.push('/settings/sync'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Integrations
            Text(
              'Integrations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.chat_outlined,
                    title: 'Chat Integrations',
                    subtitle: 'WhatsApp, Telegram bots',
                    onTap: () => context.push('/settings/integrations'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Support & Legal
            Text(
              'Support & Legal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help and contact support',
                    onTap: () {
                      // Open help center or support chat
                    },
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.article_outlined,
                    title: 'Terms of Service',
                    onTap: () {
                      // Open terms of service
                    },
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      // Open privacy policy
                    },
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Version 1.0.0',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Receiptsly',
                        applicationVersion: '1.0.0',
                        applicationIcon: const FlutterLogo(),
                        children: [
                          const Text(
                            'Simplify expense tracking and invoicing for freelancers and small businesses.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Danger Zone
            Text(
              'Danger Zone',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Sign out of your account',
                    iconColor: Colors.red,
                    titleColor: Colors.red,
                    onTap: _showSignOutDialog,
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and data',
                    iconColor: Colors.red,
                    titleColor: Colors.red,
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
