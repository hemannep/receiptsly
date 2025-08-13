// lib/presentation/screens/settings/widgets/integration_card.dart
import 'package:flutter/material.dart';

class IntegrationCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isConnected;
  final bool isLoading;
  final bool isComingSoon;
  final List<String> features;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const IntegrationCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.isConnected,
    required this.isLoading,
    required this.features,
    required this.onConnect,
    required this.onDisconnect,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isConnected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isConnected
              ? Colors.green.withOpacity(0.3)
              : isComingSoon
              ? Colors.orange.withOpacity(0.3)
              : Colors.transparent,
          width: isConnected || isComingSoon ? 1 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isConnected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'CONNECTED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (isComingSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'COMING SOON',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Features
            Text(
              'Features:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isConnected
                          ? Icons.check_circle
                          : isComingSoon
                          ? Icons.schedule
                          : Icons.radio_button_unchecked,
                      color: isConnected
                          ? Colors.green
                          : isComingSoon
                          ? Colors.orange
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isComingSoon
                              ? theme.colorScheme.onSurfaceVariant.withOpacity(
                                  0.7,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Connection Status & Actions
            if (isConnected) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Successfully Connected',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You can now send receipts through $title',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Test connection
                        _showTestDialog(context);
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Test'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : onDisconnect,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link_off, size: 18),
                      label: const Text('Disconnect'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (isComingSoon) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.orange.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coming Soon',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'We\'re working on this integration. Stay tuned!',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showNotifyDialog(context);
                  },
                  icon: const Icon(Icons.notifications, size: 18),
                  label: const Text('Notify Me When Available'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onConnect,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(Icons.link, color: Colors.white),
                  label: Text(
                    isLoading ? 'Connecting...' : 'Connect $title',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // Instructions for connection
            if (!isConnected && !isComingSoon) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getConnectionInstructions(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getConnectionInstructions() {
    switch (title.toLowerCase()) {
      case 'whatsapp':
        return 'Scan QR code with WhatsApp to connect your account securely.';
      case 'telegram':
        return 'Create a bot token from @BotFather and enter it to connect.';
      case 'slack':
        return 'Create an incoming webhook in your Slack workspace settings.';
      default:
        return 'Follow the setup instructions to connect this integration.';
    }
  }

  void _showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test $title Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Sending test message...'),
          ],
        ),
      ),
    );

    // Simulate test
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title connection test successful!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _showNotifyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Get Notified'),
        content: const Text(
          'We\'ll send you an email when this integration becomes available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'You\'ll be notified when this feature is ready!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Notify Me'),
          ),
        ],
      ),
    );
  }
}
