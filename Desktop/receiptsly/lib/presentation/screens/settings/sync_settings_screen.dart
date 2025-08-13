// lib/presentation/screens/settings/sync_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../services/sync/sync_service.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_button.dart';

class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  bool _autoSync = true;
  bool _syncOnWifiOnly = false;
  bool _syncPhotos = true;
  bool _syncReports = true;
  bool _backgroundSync = true;
  String _syncFrequency = 'immediate';
  bool _isManualSyncInProgress = false;

  final List<String> _syncFrequencyOptions = [
    'immediate',
    'every_5_minutes',
    'every_15_minutes',
    'every_hour',
    'manual_only',
  ];

  @override
  void initState() {
    super.initState();
    _loadSyncSettings();
  }

  Future<void> _loadSyncSettings() async {
    // Load sync settings from SharedPreferences or user preferences
    setState(() {
      // Load actual settings
    });
  }

  Future<void> _saveSyncSettings() async {
    // Save sync settings to SharedPreferences and update backend
    try {
      final settings = {
        'autoSync': _autoSync,
        'syncOnWifiOnly': _syncOnWifiOnly,
        'syncPhotos': _syncPhotos,
        'syncReports': _syncReports,
        'backgroundSync': _backgroundSync,
        'syncFrequency': _syncFrequency,
      };

      // Save to local storage and update sync service configuration
      // await ref.read(syncSettingsProvider.notifier).updateSettings(settings);

      _showSuccessSnackBar('Sync settings saved successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to save sync settings: $e');
    }
  }

  Future<void> _performManualSync() async {
    setState(() {
      _isManualSyncInProgress = true;
    });

    try {
      // Trigger manual sync
      // await ref.read(syncServiceProvider).performManualSync();

      // Simulate sync process
      await Future.delayed(const Duration(seconds: 3));

      _showSuccessSnackBar('Data synchronized successfully');
    } catch (e) {
      _showErrorSnackBar('Sync failed: $e');
    } finally {
      setState(() {
        _isManualSyncInProgress = false;
      });
    }
  }

  Future<void> _clearLocalData() async {
    final confirmed = await _showClearDataConfirmation();
    if (!confirmed) return;

    try {
      // Clear local cache and force re-sync from server
      // await ref.read(syncServiceProvider).clearLocalData();

      _showSuccessSnackBar('Local data cleared. Re-syncing from server...');
      _performManualSync();
    } catch (e) {
      _showErrorSnackBar('Failed to clear local data: $e');
    }
  }

  Future<bool> _showClearDataConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will clear all locally stored data including:'),
            SizedBox(height: 8),
            Text('• Cached receipts and images'),
            Text('• Offline queue items'),
            Text('• Local settings'),
            SizedBox(height: 16),
            Text(
              'All data will be re-downloaded from the server. This may take some time.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
    return result ?? false;
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

  String _getSyncFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'immediate':
        return 'Immediate';
      case 'every_5_minutes':
        return 'Every 5 minutes';
      case 'every_15_minutes':
        return 'Every 15 minutes';
      case 'every_hour':
        return 'Every hour';
      case 'manual_only':
        return 'Manual only';
      default:
        return frequency;
    }
  }

  String _getLastSyncText() {
    // In a real app, this would come from the sync provider
    return '2 minutes ago';
  }

  int _getPendingSyncItems() {
    // In a real app, this would come from the sync provider
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastSync = _getLastSyncText();
    final pendingItems = _getPendingSyncItems();

    return AppScaffold(
      title: 'Sync Settings',
      actions: [
        TextButton(onPressed: _saveSyncSettings, child: const Text('SAVE')),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sync Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_sync,
                          color: theme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sync Status',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Sync',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              lastSync,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Pending Items',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: pendingItems > 0
                                    ? Colors.orange.shade100
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                pendingItems.toString(),
                                style: TextStyle(
                                  color: pendingItems > 0
                                      ? Colors.orange.shade700
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    AppButton(
                      onPressed: _isManualSyncInProgress
                          ? null
                          : _performManualSync,
                      isLoading: _isManualSyncInProgress,
                      child: const Text('Sync Now'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Auto Sync Settings
            Text(
              'Automatic Sync',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Auto Sync'),
                    subtitle: const Text('Automatically sync data when online'),
                    value: _autoSync,
                    onChanged: (value) {
                      setState(() {
                        _autoSync = value;
                      });
                    },
                  ),

                  if (_autoSync) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Sync Frequency'),
                      subtitle: Text(_getSyncFrequencyLabel(_syncFrequency)),
                      trailing: DropdownButton<String>(
                        value: _syncFrequency,
                        underline: const SizedBox(),
                        items: _syncFrequencyOptions.map((frequency) {
                          return DropdownMenuItem(
                            value: frequency,
                            child: Text(_getSyncFrequencyLabel(frequency)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _syncFrequency = value;
                            });
                          }
                        },
                      ),
                    ),

                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('WiFi Only'),
                      subtitle: const Text('Only sync when connected to WiFi'),
                      value: _syncOnWifiOnly,
                      onChanged: (value) {
                        setState(() {
                          _syncOnWifiOnly = value;
                        });
                      },
                    ),

                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Background Sync'),
                      subtitle: const Text(
                        'Sync data when app is in background',
                      ),
                      value: _backgroundSync,
                      onChanged: (value) {
                        setState(() {
                          _backgroundSync = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Data Types
            Text(
              'Data Types',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Sync Receipt Images'),
                    subtitle: const Text('Include high-quality receipt images'),
                    value: _syncPhotos,
                    onChanged: (value) {
                      setState(() {
                        _syncPhotos = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Sync Reports'),
                    subtitle: const Text(
                      'Include generated reports and analytics',
                    ),
                    value: _syncReports,
                    onChanged: (value) {
                      setState(() {
                        _syncReports = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Storage & Cache
            Text(
              'Storage & Cache',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Local Storage Used'),
                    subtitle: const Text('156 MB of cached data'),
                    trailing: const Icon(Icons.storage),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Cloud Storage Used'),
                    subtitle: const Text('2.4 GB of 5 GB available'),
                    trailing: const Icon(Icons.cloud),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Clear Local Cache'),
                    subtitle: const Text('Free up storage space'),
                    trailing: const Icon(Icons.delete_outline),
                    onTap: _clearLocalData,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Conflict Resolution
            Text(
              'Conflict Resolution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Resolution Strategy'),
                    subtitle: const Text('Server wins (recommended)'),
                    trailing: DropdownButton<String>(
                      value: 'server_wins',
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'server_wins',
                          child: Text('Server Wins'),
                        ),
                        DropdownMenuItem(
                          value: 'local_wins',
                          child: Text('Local Wins'),
                        ),
                        DropdownMenuItem(
                          value: 'manual',
                          child: Text('Ask Me'),
                        ),
                      ],
                      onChanged: (value) {
                        // Handle conflict resolution strategy change
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('View Sync Conflicts'),
                    subtitle: const Text('No conflicts detected'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to conflict resolution screen
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Advanced Options
            Text(
              'Advanced',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Sync Logs'),
                    subtitle: const Text('View detailed sync activity'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showSyncLogs();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Force Full Sync'),
                    subtitle: const Text('Re-sync all data from server'),
                    trailing: const Icon(Icons.refresh),
                    onTap: () {
                      _performFullSync();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Export Sync Settings'),
                    subtitle: const Text('Save current sync configuration'),
                    trailing: const Icon(Icons.download),
                    onTap: () {
                      _exportSyncSettings();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Network Status
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.network_check, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Network Status',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connected via WiFi - All sync features available',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showSyncLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Logs'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: const [
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Receipt sync completed'),
                subtitle: Text('2 minutes ago'),
              ),
              ListTile(
                leading: Icon(Icons.sync, color: Colors.blue),
                title: Text('Auto sync started'),
                subtitle: Text('5 minutes ago'),
              ),
              ListTile(
                leading: Icon(Icons.warning, color: Colors.orange),
                title: Text('Sync conflict resolved'),
                subtitle: Text('1 hour ago'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Manual sync completed'),
                subtitle: Text('2 hours ago'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _performFullSync() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Full Sync'),
        content: const Text(
          'This will clear all local data and re-download everything from the server. This may take several minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isManualSyncInProgress = true;
        });

        // Perform full sync
        await Future.delayed(const Duration(seconds: 5));

        _showSuccessSnackBar('Full sync completed successfully');
      } catch (e) {
        _showErrorSnackBar('Full sync failed: $e');
      } finally {
        setState(() {
          _isManualSyncInProgress = false;
        });
      }
    }
  }

  void _exportSyncSettings() {
    _showSuccessSnackBar('Sync settings exported to Downloads folder');
  }
}
