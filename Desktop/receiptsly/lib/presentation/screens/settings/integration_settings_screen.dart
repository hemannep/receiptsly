// lib/presentation/screens/settings/integration_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_button.dart';
import 'widgets/integration_card.dart';

class IntegrationSettingsScreen extends ConsumerStatefulWidget {
  const IntegrationSettingsScreen({super.key});

  @override
  ConsumerState<IntegrationSettingsScreen> createState() => _IntegrationSettingsScreenState();
}

class _IntegrationSettingsScreenState extends ConsumerState<IntegrationSettingsScreen> {
  bool _whatsappConnected = false;
  bool _telegramConnected = false;
  bool _slackConnected = false;
  bool _isLoading = false;
  
  String? _whatsappQrCode;
  String? _telegramBotToken;
  String? _slackWebhookUrl;

  @override
  void initState() {
    super.initState();
    _loadIntegrationStatus();
  }

  Future<void> _loadIntegrationStatus() async {
    // Load integration status from backend
    setState(() {
      // Load actual status from API/Firestore
    });
  }

  Future<void> _connectWhatsApp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate QR code for WhatsApp Web connection
      // This would typically call your backend to initiate the connection
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _WhatsAppConnectionDialog(
          onConnected: () {
            setState(() {
              _whatsappConnected = true;
            });
            Navigator.pop(context);
            _showSuccessSnackBar('WhatsApp connected successfully!');
          },
          onCancelled: () {
            Navigator.pop(context);
          },
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to connect WhatsApp: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disconnectWhatsApp() async {
    final confirmed = await _showDisconnectConfirmation('WhatsApp');
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Call backend to disconnect WhatsApp
      setState(() {
        _whatsappConnected = false;
      });
      _showSuccessSnackBar('WhatsApp disconnected successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to disconnect WhatsApp: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectTelegram() async {
    showDialog(
      context: context,
      builder: (context) => _TelegramConnectionDialog(
        onConnected: (botToken) {
          setState(() {
            _telegramConnected = true;
            _telegramBotToken = botToken;
          });
          Navigator.pop(context);
          _showSuccessSnackBar('Telegram bot connected successfully!');
        },
        onCancelled: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _disconnectTelegram() async {
    final confirmed = await _showDisconnectConfirmation('Telegram');
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      setState(() {
        _telegramConnected = false;
        _telegramBotToken = null;
      });
      _showSuccessSnackBar('Telegram disconnected successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to disconnect Telegram: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectSlack() async {
    showDialog(
      context: context,
      builder: (context) => _SlackConnectionDialog(
        onConnected: (webhookUrl) {
          setState(() {
            _slackConnected = true;
            _slackWebhookUrl = webhookUrl;
          });
          Navigator.pop(context);
          _showSuccessSnackBar('Slack connected successfully!');
        },
        onCancelled: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _disconnectSlack() async {
    final confirmed = await _showDisconnectConfirmation('Slack');
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      setState(() {
        _slackConnected = false;
        _slackWebhookUrl = null;
      });
      _showSuccessSnackBar('Slack disconnected successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to disconnect Slack: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showDisconnectConfirmation(String service) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect $service'),
        content: Text('Are you sure you want to disconnect $service? You will no longer receive receipt processing through this integration.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Chat Integrations',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Connect your favorite messaging apps to easily capture receipts on the go.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 24),

            // WhatsApp Integration
            IntegrationCard(
              title: 'WhatsApp',
              description: 'Send receipt photos directly through WhatsApp',
              icon: Icons.chat,
              iconColor: Colors.green,
              isConnected: _whatsappConnected,
              isLoading: _isLoading,
              onConnect: _connectWhatsApp,
              onDisconnect: _disconnectWhatsApp,
              features: const [
                'Send receipt photos instantly',
                'Get automatic OCR processing',
                'Receive expense summaries',
                'Quick expense categorization',
              ],
            ),

            const SizedBox(height: 16),

            // Telegram Integration
            IntegrationCard(
              title: 'Telegram',
              description: 'Use Telegram bot for receipt processing',
              icon: Icons.telegram,
              iconColor: Colors.blue,
              isConnected: _telegramConnected,
              isLoading: _isLoading,
              onConnect: _connectTelegram,
              onDisconnect: _disconnectTelegram,
              features: const [
                'Bot-based receipt capture',
                'Real-time processing updates',
                'Expense reports via chat',
                'Quick editing commands',
              ],
            ),

            const SizedBox(height: 16),

            // Slack Integration (Future feature)
            IntegrationCard(
              title: 'Slack',
              description: 'Share receipts and reports with your team',
              icon: Icons.business,
              iconColor: Colors.purple,
              isConnected: _slackConnected,
              isLoading: _isLoading,
              onConnect: _connectSlack,
              onDisconnect: _disconnectSlack,
              isComingSoon: true,
              features: const [
                'Team expense sharing',
                'Channel notifications',
                'Report summaries',
                'Approval workflows',
              ],
            ),

            const SizedBox(height: 32),

            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'How it works',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
              const Text(
                'Scan this QR code with WhatsApp Web',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Open WhatsApp on your phone\n2. Tap Menu → Linked Devices\n3. Tap "Link a Device"\n4. Scan this QR code',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancelled,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// Telegram Connection Dialog
class _TelegramConnectionDialog extends StatefulWidget {
  final Function(String) onConnected;
  final VoidCallback onCancelled;

  const _TelegramConnectionDialog({
    required this.onConnected,
    required this.onCancelled,
  });

  @override
  State<_TelegramConnectionDialog> createState() => _TelegramConnectionDialogState();
}

class _TelegramConnectionDialogState extends State<_TelegramConnectionDialog> {
  final _botTokenController = TextEditingController();
  bool _isConnecting = false;

  @override
  void dispose() {
    _botTokenController.dispose();
    super.dispose();
  }

  Future<void> _connectBot() async {
    final botToken = _botTokenController.text.trim();
    if (botToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter bot token'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      // Validate and connect bot
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      widget.onConnected(botToken);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect bot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connect Telegram Bot'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Follow these steps to set up your Telegram bot:'),
            const SizedBox(height: 16),
            const Text('1. Search for @BotFather on Telegram'),
            const Text('2. Send /newbot command'),
            const Text('3. Choose a name and username for your bot'),
            const Text('4. Copy the bot token and paste it below'),
            const SizedBox(height: 16),
            TextField(
              controller: _botTokenController,
              decoration: const InputDecoration(
                labelText: 'Bot Token',
                hintText: '123456789:ABCdefGHIjklMNOpqrsTUVwxyz',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Text(
              'Your bot token should start with a number followed by a colon',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancelled,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isConnecting ? null : _connectBot,
          child: _isConnecting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Connect'),
        ),
      ],
    );
  }
}

// Slack Connection Dialog
class _SlackConnectionDialog extends StatefulWidget {
  final Function(String) onConnected;
  final VoidCallback onCancelled;

  const _SlackConnectionDialog({
    required this.onConnected,
    required this.onCancelled,
  });

  @override
  State<_SlackConnectionDialog> createState() => _SlackConnectionDialogState();
}

class _SlackConnectionDialogState extends State<_SlackConnectionDialog> {
  final _webhookController = TextEditingController();
  bool _isConnecting = false;

  @override
  void dispose() {
    _webhookController.dispose();
    super.dispose();
  }

  Future<void> _connectSlack() async {
    final webhookUrl = _webhookController.text.trim();
    if (webhookUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter webhook URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!webhookUrl.startsWith('https://hooks.slack.com/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Slack webhook URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      // Validate and connect webhook
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      widget.onConnected(webhookUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect Slack: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connect Slack'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set up Slack integration:'),
            const SizedBox(height: 16),
            const Text('1. Go to your Slack workspace settings'),
            const Text('2. Navigate to Apps → Incoming Webhooks'),
            const Text('3. Create a new webhook for your channel'),
            const Text('4. Copy the webhook URL and paste it below'),
            const SizedBox(height: 16),
            TextField(
              controller: _webhookController,
              decoration: const InputDecoration(
                labelText: 'Webhook URL',
                hintText: 'https://hooks.slack.com/services/...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Text(
              'The webhook URL should start with https://hooks.slack.com/',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancelled,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isConnecting ? null : _connectSlack,
          child: _isConnecting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Connect'),
        ),
      ],
    );
  }
}12),
                    const Text('1. Connect your preferred messaging app'),
                    const SizedBox(height: 4),
                    const Text('2. Send a photo of your receipt'),
                    const SizedBox(height: 4),
                    const Text('3. Our AI extracts the details automatically'),
                    const SizedBox(height: 4),
                    const Text('4. Review and confirm in the app'),
                    const SizedBox(height: 12),
                    Text(
                      'All data is processed securely and synced across your devices.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
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
}

// WhatsApp Connection Dialog
class _WhatsAppConnectionDialog extends StatefulWidget {
  final VoidCallback onConnected;
  final VoidCallback onCancelled;

  const _WhatsAppConnectionDialog({
    required this.onConnected,
    required this.onCancelled,
  });

  @override
  State<_WhatsAppConnectionDialog> createState() => _WhatsAppConnectionDialogState();
}

class _WhatsAppConnectionDialogState extends State<_WhatsAppConnectionDialog> {
  bool _isConnecting = true;
  bool _showQrCode = false;
  String _qrCodeData = 'https://receiptsly.app/whatsapp/connect/abc123';

  @override
  void initState() {
    super.initState();
    _initiateConnection();
  }

  Future<void> _initiateConnection() async {
    // Simulate connection process
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isConnecting = false;
        _showQrCode = true;
      });

      // Simulate successful connection after QR scan
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          widget.onConnected();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connect WhatsApp'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isConnecting) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Initializing connection...'),
            ] else if (_showQrCode) ...[
              QrImageView(
                data: _qrCodeData,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: