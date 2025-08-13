// lib/presentation/screens/reports/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/report_entity.dart';
import '../../providers/report_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/charts/bar_chart.dart';
import '../../widgets/charts/pie_chart.dart';
import '../../widgets/charts/line_chart.dart';
import 'widgets/report_filters.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  
  ReportPeriod _selectedPeriod = ReportPeriod.lastMonth;
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReports() {
    ref.read(reportProvider.notifier).loadReports(
      dateRange: _selectedDateRange,
      categories: _selectedCategories,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportState = ref.watch(reportProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_all',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export All'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'schedule_report',
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('Schedule Report'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
            Tab(text: 'Performance'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick Stats Header
          _buildQuickStatsHeader(reportState, theme),
          
          // Date Range Selector
          _buildDateRangeSelector(theme),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(reportState, theme),
                _buildIncomeTab(reportState, theme),
                _buildExpensesTab(reportState, theme),
                _buildPerformanceTab(reportState, theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reports/custom'),
        icon: const Icon(Icons.analytics),
        label: const Text('Custom Report'),
      ),
    );
  }

  Widget _buildQuickStatsHeader(ReportState reportState, ThemeData theme) {
    if (reportState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: AppLoader(),
      );
    }

    final overview = reportState.overview;
    if (overview == null) return const SizedBox.shrink();

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
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Total Income',
                  '\$${overview.totalIncome.toStringAsFixed(2)}',
                  Icons.trending_up,
                  overview.incomeChange,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Total Expenses',
                  '\$${overview.totalExpenses.toStringAsFixed(2)}',
                  Icons.trending_down,
                  overview.expenseChange,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Growth Analysis
          _buildGrowthAnalysisCard(reportState, theme),
          
          const SizedBox(height: 24),
          
          // Goal Tracking
          _buildGoalTrackingCard(reportState, theme),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    ThemeData theme,
    String title,
    String subtitle,
    Widget chart,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleChartAction(value, title),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'export',
                      child: Text('Export Chart'),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Text('Share'),
                    ),
                    const PopupMenuItem(
                      value: 'fullscreen',
                      child: Text('View Fullscreen'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            chart,
          ],
        ),
      ),
    );
  }

  Widget _buildTopClientsCard(ReportState reportState, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Clients',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/clients'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (reportState.topClients?.isEmpty ?? true)
              const Center(
                child: Text('No client data available'),
              )
            else
              ...reportState.topClients!.take(5).map((client) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          client.name.isNotEmpty ? client.name[0] : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              client.company,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\${client.totalInvoiced.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${client.totalInvoices} invoices',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
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

  Widget _buildTrendsCard(ReportState reportState, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Insights',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (reportState.insights?.isEmpty ?? true)
              const Center(
                child: Text('No insights available'),
              )
            else
              ...reportState.insights!.map((insight) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: insight.type.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          insight.type.icon,
                          color: insight.type.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight.title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              insight.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
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

  Widget _buildInvoiceStatusCard(ReportState reportState, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Status',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (reportState.invoiceStatus == null)
              const Center(child: Text('No invoice data available'))
            else
              Column(
                children: [
                  _buildStatusRow(
                    theme,
                    'Paid',
                    reportState.invoiceStatus!.paid,
                    reportState.invoiceStatus!.total,
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    theme,
                    'Pending',
                    reportState.invoiceStatus!.pending,
                    reportState.invoiceStatus!.total,
                    Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    theme,
                    'Overdue',
                    reportState.invoiceStatus!.overdue,
                    reportState.invoiceStatus!.total,
                    Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    theme,
                    'Draft',
                    reportState.invoiceStatus!.draft,
                    reportState.invoiceStatus!.total,
                    Colors.grey,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    ThemeData theme,
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
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
    );
  }

  Widget _buildPaymentMethodsCard(ReportState reportState, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Methods',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: reportState.paymentMethodsChart != null
                  ? AppPieChart(
                      data: reportState.paymentMethodsChart!,
                      showLegend: true,
                    )
                  : const Center(child: Text('No payment data available')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxDeductibleCard(ReportState reportState, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tax Deductible Expenses',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\${reportState.taxDeductibleAmount?.toStringAsFixed(2) ?? '0.00'}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Potential tax savings',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/reports/tax-estimate'),
                    child: const Text('Details'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopVendorsCard(ReportState reportState, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Vendors',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (reportState.topVendors?.isEmpty ?? true)
              const Center(child: Text('No vendor data available'))
            else
              ...reportState.topVendors!.take(5).map((vendor) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.store,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              vendor.category,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\${vendor.totalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${vendor.transactionCount} receipts',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
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

  Widget _buildKPICards(ReportState reportState, ThemeData theme) {
    final kpis = reportState.kpis;
    if (kpis == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                theme,
                'Revenue Growth',
                '${kpis.revenueGrowth.toStringAsFixed(1)}%',
                Icons.trending_up,
                kpis.revenueGrowth >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                theme,
                'Client Retention',
                '${kpis.clientRetention.toStringAsFixed(1)}%',
                Icons.people,
                theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                theme,
                'Avg. Invoice Value',
                '\${kpis.avgInvoiceValue.toStringAsFixed(2)}',
                Icons.receipt_long,
                theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                theme,
                'Collection Rate',
                '${kpis.collectionRate.toStringAsFixed(1)}%',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.arrow_upward,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthAnalysisCard(ReportState reportState, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Growth Analysis',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: reportState.growthChart != null
                  ? AppLineChart(
                      data: reportState.growthChart!,
                      xAxisLabel: 'Period',
                      yAxisLabel: 'Growth %',
                    )
                  : const Center(child: Text('No growth data available')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTrackingCard(ReportState reportState, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goal Tracking',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showGoalSettings(),
                  child: const Text('Set Goals'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (reportState.goals?.isEmpty ?? true)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No goals set',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...reportState.goals!.map((goal) {
                final progress = goal.current / goal.target;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            goal.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0 ? Colors.green : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\${goal.current.toStringAsFixed(2)} of \${goal.target.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
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

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReportFilters(
        selectedCategories: _selectedCategories,
        selectedDateRange: _selectedDateRange,
        onFiltersChanged: (categories, dateRange) {
          setState(() {
            _selectedCategories = categories;
            _selectedDateRange = dateRange;
          });
          _loadReports();
        },
      ),
    );
  }

  void _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedPeriod = ReportPeriod.custom;
      });
      _loadReports();
    }
  }

  void _showGoalSettings() {
    // Navigate to goal settings screen
    context.push('/settings/goals');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_all':
        _exportAllReports();
        break;
      case 'schedule_report':
        _scheduleReport();
        break;
      case 'share':
        _shareReports();
        break;
    }
  }

  void _handleChartAction(String action, String chartTitle) {
    switch (action) {
      case 'export':
        _exportChart(chartTitle);
        break;
      case 'share':
        _shareChart(chartTitle);
        break;
      case 'fullscreen':
        _viewChartFullscreen(chartTitle);
        break;
    }
  }

  void _exportAllReports() {
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting reports...')),
    );
  }

  void _scheduleReport() {
    // Show schedule report dialog
    context.push('/reports/schedule');
  }

  void _shareReports() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing reports...')),
    );
  }

  void _exportChart(String chartTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting $chartTitle...')),
    );
  }

  void _shareChart(String chartTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing $chartTitle...')),
    );
  }

  void _viewChartFullscreen(String chartTitle) {
    context.push('/reports/chart/$chartTitle');
  }
}

// Supporting enums and models
enum ReportPeriod {
  today('Today'),
  yesterday('Yesterday'),
  lastWeek('Last Week'),
  lastMonth('Last Month'),
  lastQuarter('Last Quarter'),
  lastYear('Last Year'),
  custom('Custom');

  const ReportPeriod(this.displayName);
  final String displayName;

  DateTimeRange get dateRange {
    final now = DateTime.now();
    switch (this) {
      case ReportPeriod.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
      case ReportPeriod.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: DateTime(yesterday.year, yesterday.month, yesterday.day),
          end: DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
        );
      case ReportPeriod.lastWeek:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case ReportPeriod.lastMonth:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case ReportPeriod.lastQuarter:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 90)),
          end: now,
        );
      case ReportPeriod.lastYear:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 365)),
          end: now,
        );
      case ReportPeriod.custom:
        return DateTimeRange(start: now, end: now);
    }
  }
}: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Net Profit',
                  '\$${overview.netProfit.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  overview.profitChange,
                  overview.netProfit >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Profit Margin',
                  '${overview.profitMargin.toStringAsFixed(1)}%',
                  Icons.percent,
                  overview.marginChange,
                  theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    double? change,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: change >= 0 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${change.abs().toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Period',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          // Quick period buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReportPeriod.values.map((period) {
              final isSelected = _selectedPeriod == period;
              return FilterChip(
                label: Text(period.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedPeriod = period;
                      _selectedDateRange = period.dateRange;
                    });
                    _loadReports();
                  }
                },
                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                checkmarkColor: theme.colorScheme.primary,
              );
            }).toList(),
          ),
          
          const SizedBox(height: 12),
          
          // Custom date range
          InkWell(
            onTap: _selectCustomDateRange,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_formatDate(_selectedDateRange.start)} - ${_formatDate(_selectedDateRange.end)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ReportState reportState, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profit/Loss Trend
          _buildChartCard(
            theme,
            'Profit & Loss Trend',
            'Monthly profit and loss overview',
            SizedBox(
              height: 250,
              child: reportState.profitLossChart != null
                  ? AppLineChart(
                      data: reportState.profitLossChart!,
                      xAxisLabel: 'Month',
                      yAxisLabel: 'Amount (\$)',
                    )
                  : const Center(child: Text('No data available')),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Category Breakdown
          _buildChartCard(
            theme,
            'Expense Categories',
            'Breakdown by category',
            SizedBox(
              height: 300,
              child: reportState.categoryBreakdown != null
                  ? AppPieChart(
                      data: reportState.categoryBreakdown!,
                      showLegend: true,
                    )
                  : const Center(child: Text('No data available')),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Top Clients
          _buildTopClientsCard(reportState, theme),
          
          const SizedBox(height: 24),
          
          // Recent Trends
          _buildTrendsCard(reportState, theme),
        ],
      ),
    );
  }

  Widget _buildIncomeTab(ReportState reportState, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Income Trend
          _buildChartCard(
            theme,
            'Income Trend',
            'Monthly income progression',
            SizedBox(
              height: 250,
              child: reportState.incomeChart != null
                  ? AppLineChart(
                      data: reportState.incomeChart!,
                      xAxisLabel: 'Month',
                      yAxisLabel: 'Income (\$)',
                    )
                  : const Center(child: Text('No data available')),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Income by Client
          _buildChartCard(
            theme,
            'Income by Client',
            'Top revenue generating clients',
            SizedBox(
              height: 300,
              child: reportState.clientIncomeChart != null
                  ? AppBarChart(
                      data: reportState.clientIncomeChart!,
                      xAxisLabel: 'Clients',
                      yAxisLabel: 'Income (\$)',
                    )
                  : const Center(child: Text('No data available')),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Invoice Status
          _buildInvoiceStatusCard(reportState, theme),
          
          const SizedBox(height: 24),
          
          // Payment Methods
          _buildPaymentMethodsCard(reportState, theme),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(ReportState reportState, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expense Trend
          _buildChartCard(
            theme,
            'Expense Trend',
            'Monthly expense tracking',
            SizedBox(
              height: 250,
              child: reportState.expenseChart != null
                  ? AppLineChart(
                      data: reportState.expenseChart!,
                      xAxisLabel: 'Month',
                      yAxisLabel: 'Expenses (\$)',
                    )
                  : const Center(child: Text('No data available')),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Expense Categories
          _buildChartCard(
            theme,
            'Expense Categories',
            'Breakdown by category',
            SizedBox(
              height: 300,
              child: reportState.expenseCategoryChart != null
                  ? AppBarChart(
                      data: reportState.expenseCategoryChart!,
                      xAxisLabel: 'Categories',
                      yAxisLabel: 'Amount (\$)',
                    )
                  : const Center(child: Text('No data available')),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Tax Deductible Expenses
          _buildTaxDeductibleCard(reportState, theme),
          
          const SizedBox(height: 24),
          
          // Expense Vendors
          _buildTopVendorsCard(reportState, theme),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(ReportState reportState, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          _buildKPICards(reportState, theme),
          
          const SizedBox(height: 24),
          
          // Performance Metrics
          _buildChartCard(
            theme,
            'Key Performance Indicators',
            'Monthly performance tracking',
            SizedBox(
              height: 250,
              child: reportState.performanceChart != null
                  ? AppLineChart(
                      data: reportState.performanceChart!,
                      xAxisLabel: 'Month',
                      yAxisLabel: 'Score',
                    )
                  : const Center(child: Text('No data available')),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Growth Analysis
          _buildGrowthAnalysisCard(reportState, theme),
          
          const SizedBox(height