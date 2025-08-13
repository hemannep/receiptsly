// lib/presentation/screens/client/client_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/client_entity.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../../providers/client_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/charts/line_chart.dart';
import '../invoice/widgets/invoice_card.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load client details and related data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientProvider.notifier).loadClientById(widget.clientId);
      ref.read(invoiceProvider.notifier).loadInvoicesByClient(widget.clientId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final client = clientState.clients.firstWhere(
      (c) => c.id == widget.clientId,
      orElse: () => throw StateError('Client not found'),
    );

    if (clientState.isLoading) {
      return const Scaffold(body: Center(child: AppLoader()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value, client),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share Contact'),
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Data'),
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(Icons.archive),
                  title: Text('Archive'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Client Header Card
          _buildClientHeader(context, client),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Invoices'),
              Tab(text: 'Analytics'),
              Tab(text: 'Notes'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, client),
                _buildInvoicesTab(context, client),
                _buildAnalyticsTab(context, client),
                _buildNotesTab(context, client),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createInvoice(context, client),
        icon: const Icon(Icons.receipt_long),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildClientHeader(BuildContext context, ClientEntity client) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      client.company,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(client.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        client.status.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(client.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${client.totalInvoiced.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Invoiced',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Contact Information
          Row(
            children: [
              Expanded(
                child: _buildContactInfo(
                  context,
                  Icons.email,
                  'Email',
                  client.email,
                  () => _launchEmail(client.email),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildContactInfo(
                  context,
                  Icons.phone,
                  'Phone',
                  client.phone,
                  () => _launchPhone(client.phone),
                ),
              ),
            ],
          ),

          if (client.address.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildContactInfo(
              context,
              Icons.location_on,
              'Address',
              client.address,
              () => _launchMaps(client.address),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfo(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, ClientEntity client) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          _buildQuickStats(context, client),

          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(context, client),

          const SizedBox(height: 24),

          // Client Information
          _buildClientInformation(context, client),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, ClientEntity client) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Invoices',
                    client.totalInvoices.toString(),
                    Icons.receipt_long,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Paid Amount',
                    '\$${client.paidAmount.toStringAsFixed(2)}',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Outstanding',
                    '\$${client.outstandingAmount.toStringAsFixed(2)}',
                    Icons.pending,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Last Invoice',
                    client.lastInvoiceDate != null
                        ? _formatDate(client.lastInvoiceDate!)
                        : 'Never',
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, ClientEntity client) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Activity items would be populated from invoices
            Consumer(
              builder: (context, ref, child) {
                final invoiceState = ref.watch(invoiceProvider);
                final clientInvoices = invoiceState.invoices
                    .where((invoice) => invoice.clientId == client.id)
                    .take(3)
                    .toList();

                if (clientInvoices.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: clientInvoices.map((invoice) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildActivityItem(
                        context,
                        _getInvoiceActivityIcon(invoice.status),
                        'Invoice ${invoice.number}',
                        '\${invoice.total.toStringAsFixed(2)} • ${invoice.status.displayName}',
                        _formatDate(invoice.createdAt),
                        _getInvoiceStatusColor(invoice.status),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String date,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInformation(BuildContext context, ClientEntity client) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoRow('Client Since', _formatDate(client.createdAt)),
            _buildInfoRow('Payment Terms', '${client.paymentTerms} days'),
            _buildInfoRow('Default Currency', client.currency),
            _buildInfoRow(
              'Tax ID',
              client.taxId.isNotEmpty ? client.taxId : 'Not provided',
            ),

            if (client.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Notes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(client.notes, style: theme.textTheme.bodyMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab(BuildContext context, ClientEntity client) {
    return Consumer(
      builder: (context, ref, child) {
        final invoiceState = ref.watch(invoiceProvider);
        final clientInvoices = invoiceState.invoices
            .where((invoice) => invoice.clientId == client.id)
            .toList();

        if (invoiceState.isLoading) {
          return const Center(child: AppLoader());
        }

        if (clientInvoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No invoices yet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first invoice for ${client.name}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _createInvoice(context, client),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Invoice'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clientInvoices.length,
          itemBuilder: (context, index) {
            final invoice = clientInvoices[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InvoiceCard(
                invoice: invoice,
                onTap: () => _navigateToInvoice(context, invoice.id),
                onEdit: () => _editInvoice(context, invoice.id),
                onDelete: () => _deleteInvoice(context, invoice),
                onDuplicate: () => _duplicateInvoice(context, invoice),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab(BuildContext context, ClientEntity client) {
    return Consumer(
      builder: (context, ref, child) {
        final invoiceState = ref.watch(invoiceProvider);
        final clientInvoices = invoiceState.invoices
            .where((invoice) => invoice.clientId == client.id)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue Chart
              _buildRevenueChart(context, clientInvoices),

              const SizedBox(height: 24),

              // Payment Statistics
              _buildPaymentStatistics(context, clientInvoices),

              const SizedBox(height: 24),

              // Invoice Status Breakdown
              _buildInvoiceStatusBreakdown(context, clientInvoices),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueChart(
    BuildContext context,
    List<InvoiceEntity> invoices,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Trend',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 200,
              child: invoices.isNotEmpty
                  ? AppLineChart(
                      data: _generateChartData(invoices),
                      xAxisLabel: 'Month',
                      yAxisLabel: 'Revenue (\$)',
                    )
                  : Center(
                      child: Text(
                        'No data available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatistics(
    BuildContext context,
    List<InvoiceEntity> invoices,
  ) {
    final theme = Theme.of(context);

    // Calculate payment statistics
    final totalInvoices = invoices.length;
    final paidInvoices = invoices
        .where((inv) => inv.status == InvoiceStatus.paid)
        .length;
    final overdueInvoices = invoices
        .where((inv) => inv.status == InvoiceStatus.overdue)
        .length;
    final avgPaymentTime = _calculateAveragePaymentTime(invoices);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Statistics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Payment Rate',
                    totalInvoices > 0
                        ? '${((paidInvoices / totalInvoices) * 100).toStringAsFixed(1)}%'
                        : '0%',
                    Icons.payment,
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Overdue Rate',
                    totalInvoices > 0
                        ? '${((overdueInvoices / totalInvoices) * 100).toStringAsFixed(1)}%'
                        : '0%',
                    Icons.warning,
                    theme.colorScheme.error,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Avg Payment Time',
                    '${avgPaymentTime.toStringAsFixed(1)} days',
                    Icons.schedule,
                    theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Invoices',
                    totalInvoices.toString(),
                    Icons.receipt_long,
                    theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceStatusBreakdown(
    BuildContext context,
    List<InvoiceEntity> invoices,
  ) {
    final theme = Theme.of(context);

    // Calculate status breakdown
    final statusCounts = <InvoiceStatus, int>{};
    for (final status in InvoiceStatus.values) {
      statusCounts[status] = invoices
          .where((inv) => inv.status == status)
          .length;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Status Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...statusCounts.entries.map((entry) {
              final status = entry.key;
              final count = entry.value;
              final percentage = invoices.isNotEmpty
                  ? (count / invoices.length) * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getInvoiceStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status.displayName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '$count (${percentage.toStringAsFixed(1)}%)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context, ClientEntity client) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Client Notes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => _editNotes(context, client),
                icon: const Icon(Icons.edit),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: client.notes.isNotEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        client.notes,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_add,
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notes yet',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add notes about ${client.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _editNotes(context, client),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Notes'),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(ClientStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case ClientStatus.active:
        return theme.colorScheme.primary;
      case ClientStatus.inactive:
        return theme.colorScheme.secondary;
      case ClientStatus.archived:
        return theme.colorScheme.error;
    }
  }

  IconData _getInvoiceActivityIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Icons.edit;
      case InvoiceStatus.sent:
        return Icons.send;
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.overdue:
        return Icons.warning;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getInvoiceStatusColor(InvoiceStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case InvoiceStatus.draft:
        return theme.colorScheme.secondary;
      case InvoiceStatus.sent:
        return theme.colorScheme.primary;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return theme.colorScheme.error;
      case InvoiceStatus.cancelled:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  List<ChartData> _generateChartData(List<InvoiceEntity> invoices) {
    // Group invoices by month and sum totals
    final Map<String, double> monthlyRevenue = {};

    for (final invoice in invoices) {
      if (invoice.status == InvoiceStatus.paid) {
        final monthKey =
            '${invoice.createdAt.year}-${invoice.createdAt.month.toString().padLeft(2, '0')}';
        monthlyRevenue[monthKey] =
            (monthlyRevenue[monthKey] ?? 0) + invoice.total;
      }
    }

    return monthlyRevenue.entries
        .map((entry) => ChartData(entry.key, entry.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  double _calculateAveragePaymentTime(List<InvoiceEntity> invoices) {
    final paidInvoices = invoices
        .where((inv) => inv.status == InvoiceStatus.paid && inv.paidAt != null)
        .toList();

    if (paidInvoices.isEmpty) return 0;

    final totalDays = paidInvoices.fold<int>(0, (sum, invoice) {
      final daysDiff = invoice.paidAt!.difference(invoice.createdAt).inDays;
      return sum + daysDiff;
    });

    return totalDays / paidInvoices.length;
  }

  // Action handlers
  void _handleMenuAction(
    BuildContext context,
    String action,
    ClientEntity client,
  ) {
    switch (action) {
      case 'share':
        _shareClient(client);
        break;
      case 'export':
        _exportClientData(client);
        break;
      case 'archive':
        _archiveClient(context, client);
        break;
      case 'delete':
        _deleteClient(context, client);
        break;
    }
  }

  void _shareClient(ClientEntity client) {
    // Implement share functionality
  }

  void _exportClientData(ClientEntity client) {
    // Implement export functionality
  }

  void _archiveClient(BuildContext context, ClientEntity client) {
    // Implement archive functionality
  }

  void _deleteClient(BuildContext context, ClientEntity client) {
    // Implement delete functionality
  }

  void _createInvoice(BuildContext context, ClientEntity client) {
    context.push('/invoices/create?clientId=${client.id}');
  }

  void _navigateToEdit(BuildContext context) {
    context.push('/clients/${widget.clientId}/edit');
  }

  void _navigateToInvoice(BuildContext context, String invoiceId) {
    context.push('/invoices/$invoiceId');
  }

  void _editInvoice(BuildContext context, String invoiceId) {
    context.push('/invoices/$invoiceId/edit');
  }

  void _deleteInvoice(BuildContext context, InvoiceEntity invoice) {
    // Implement delete invoice functionality
  }

  void _duplicateInvoice(BuildContext context, InvoiceEntity invoice) {
    // Implement duplicate invoice functionality
  }

  void _editNotes(BuildContext context, ClientEntity client) {
    // Implement edit notes functionality
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchMaps(String address) async {
    final uri = Uri.parse(
      'https://maps.google.com/?q=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

// Supporting models
class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}
