// lib/presentation/screens/client/widgets/client_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/client_entity.dart';

class ClientCard extends StatelessWidget {
  final ClientEntity client;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;

  const ClientCard({
    super.key,
    required this.client,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onCall,
    this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Avatar
                  _buildAvatar(theme),

                  const SizedBox(width: 12),

                  // Client Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (client.company.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            client.company,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        _buildStatusChip(theme),
                      ],
                    ),
                  ),

                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${client.totalInvoiced.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),

                  // Menu
                  _buildMenuButton(context, theme),
                ],
              ),

              const SizedBox(height: 16),

              // Contact Information
              _buildContactInfo(theme),

              const SizedBox(height: 16),

              // Statistics Row
              _buildStatisticsRow(theme),

              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getStatusColor(theme),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(theme).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(theme).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        client.status.displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: _getStatusColor(theme),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, ThemeData theme) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuAction(context, value),
      icon: Icon(
        Icons.more_vert,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: ListTile(
            leading: Icon(Icons.copy),
            title: Text('Duplicate'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: ListTile(
            leading: Icon(Icons.download),
            title: Text('Export'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          child: ListTile(
            leading: Icon(
              client.status == ClientStatus.archived
                  ? Icons.unarchive
                  : Icons.archive,
            ),
            title: Text(
              client.status == ClientStatus.archived ? 'Unarchive' : 'Archive',
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: theme.colorScheme.error),
            title: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(ThemeData theme) {
    return Row(
      children: [
        if (client.email.isNotEmpty) ...[
          Expanded(
            child: _buildContactItem(
              theme,
              Icons.email,
              client.email,
              onTap: onEmail,
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (client.phone.isNotEmpty) ...[
          Expanded(
            child: _buildContactItem(
              theme,
              Icons.phone,
              client.phone,
              onTap: onCall,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactItem(
    ThemeData theme,
    IconData icon,
    String text, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _copyToClipboard(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            theme,
            'Invoices',
            client.totalInvoices.toString(),
            Icons.receipt_long,
          ),
        ),
        Container(
          width: 1,
          height: 32,
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
        Expanded(
          child: _buildStatItem(
            theme,
            'Paid',
            '\$${client.paidAmount.toStringAsFixed(0)}',
            Icons.check_circle,
          ),
        ),
        Container(
          width: 1,
          height: 32,
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
        Expanded(
          child: _buildStatItem(
            theme,
            'Outstanding',
            '\$${client.outstandingAmount.toStringAsFixed(0)}',
            Icons.pending,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEmail,
            icon: const Icon(Icons.email, size: 16),
            label: const Text('Email'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.phone, size: 16),
            label: const Text('Call'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _createInvoice(),
            icon: const Icon(Icons.receipt_long, size: 16),
            label: const Text('Invoice'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getStatusColor(ThemeData theme) {
    switch (client.status) {
      case ClientStatus.active:
        return theme.colorScheme.primary;
      case ClientStatus.inactive:
        return theme.colorScheme.secondary;
      case ClientStatus.archived:
        return theme.colorScheme.error;
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'duplicate':
        _duplicateClient(context);
        break;
      case 'export':
        _exportClient(context);
        break;
      case 'archive':
        _toggleArchive(context);
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  void _duplicateClient(BuildContext context) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Client'),
        content: Text('Create a copy of ${client.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement duplicate logic
              _showSnackBar(context, '${client.name} duplicated');
            },
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
  }

  void _exportClient(BuildContext context) {
    // Show export options
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export ${client.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(context, 'Exporting as PDF...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(context, 'Exporting as CSV...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Contact'),
              onTap: () {
                Navigator.pop(context);
                _shareContact(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleArchive(BuildContext context) {
    final isArchived = client.status == ClientStatus.archived;
    final action = isArchived ? 'unarchive' : 'archive';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.capitalize()} Client'),
        content: Text('${action.capitalize()} ${client.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(context, '${client.name} ${action}d');
            },
            child: Text(action.capitalize()),
          ),
        ],
      ),
    );
  }

  void _createInvoice() {
    // Navigate to create invoice with client pre-selected
    // This would typically use routing
  }

  void _shareContact(BuildContext context) {
    final contactInfo =
        '''
${client.name}
${client.company}
${client.email}
${client.phone}
${client.address}
''';

    // Implement sharing (using share_plus package)
    _showSnackBar(context, 'Contact shared');
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
