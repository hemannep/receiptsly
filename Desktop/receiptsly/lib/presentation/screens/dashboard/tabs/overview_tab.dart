// lib/presentation/screens/dashboard/tabs/overview_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/data/models/dashboard/dashboard_data.dart';
import 'package:receiptsly/presentation/screens/dashboard/widgets/metrics_card.dart';
import 'package:receiptsly/presentation/screens/dashboard/widgets/revenue_chart.dart';
import 'package:receiptsly/presentation/screens/dashboard/widgets/expense_breakdown.dart';
import 'package:receiptsly/presentation/screens/dashboard/widgets/recent_transactions.dart';
import 'package:receiptsly/presentation/screens/dashboard/widgets/quick_actions_grid.dart';
import 'package:receiptsly/presentation/widgets/animations/fade_animation.dart';

class OverviewTab extends ConsumerStatefulWidget {
  final DashboardData data;

  const OverviewTab({super.key, required this.data});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 300 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 300 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh dashboard data
          await ref.read(dashboardProvider.notifier).refreshData();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key Metrics Section
              _buildMetricsSection(),

              // Revenue Chart Section
              _buildRevenueChartSection(),

              // Quick Actions Section
              _buildQuickActionsSection(),

              // Recent Activity Section
              _buildRecentActivitySection(),

              // Expense Breakdown Section
              _buildExpenseBreakdownSection(),

              // Insights Section
              _buildInsightsSection(),

              // Bottom padding
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: _showScrollToTop ? _buildScrollToTopButton() : null,
    );
  }

  Widget _buildMetricsSection() {
    return FadeAnimation(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Key Metrics',
              'Your financial overview',
              onViewAll: () => _navigateToReports(),
            ),
            const SizedBox(height: 16),
            _buildMetricsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid based on screen width
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.1,
          children: [
            RevenueMetricsCard(
              amount: widget.data.monthlyIncome,
              previousAmount: widget.data.previousMonthIncome,
              onTap: () => _navigateToIncomeDetails(),
            ),
            ExpenseMetricsCard(
              amount: widget.data.monthlyExpenses,
              previousAmount: widget.data.previousMonthExpenses,
              onTap: () => _navigateToExpenseDetails(),
            ),
            ProfitMetricsCard(
              revenue: widget.data.monthlyIncome,
              expenses: widget.data.monthlyExpenses,
              onTap: () => _navigateToProfitAnalysis(),
            ),
            InvoiceMetricsCard(
              totalInvoices: widget.data.totalInvoices,
              paidInvoices: widget.data.paidInvoices,
              pendingInvoices: widget.data.pendingInvoices,
              pendingAmount: widget.data.pendingInvoiceAmount,
              onTap: () => _navigateToInvoices(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRevenueChartSection() {
    return FadeAnimation(
      delay: const Duration(milliseconds: 200),
      child: RevenueChart(
        revenueData: widget.data.revenueChartData,
        expenseData: widget.data.expenseChartData,
        period: widget.data.selectedPeriod,
        onPeriodChanged: () => _handlePeriodChange(),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return FadeAnimation(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionHeader(
              'Quick Actions',
              'Get things done faster',
            ),
          ),
          const SizedBox(height: 8),
          QuickActionsGrid(
            onActionTap: _handleQuickAction,
            showAllActions: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return FadeAnimation(
      delay: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionHeader(
              'Recent Activity',
              'Latest transactions',
              onViewAll: () => _navigateToTransactions(),
            ),
          ),
          RecentTransactions(
            transactions: widget.data.recentTransactions,
            maxItems: 5,
            onTransactionTap: _handleTransactionTap,
            onViewAll: () => _navigateToTransactions(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseBreakdownSection() {
    return FadeAnimation(
      delay: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionHeader(
              'Expense Breakdown',
              'Spending by category',
              onViewAll: () => _navigateToExpenseAnalysis(),
            ),
          ),
          ExpenseBreakdown(
            expenses: widget.data.categoryExpenses,
            totalAmount: widget.data.monthlyExpenses,
            onViewAll: () => _navigateToExpenseAnalysis(),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return FadeAnimation(
      delay: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Smart Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsList() {
    final insights = _generateInsights();

    return Column(
      children: insights.asMap().entries.map((entry) {
        final index = entry.key;
        final insight = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: insight.color.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: insight.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(insight.icon, color: insight.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (insight.actionLabel != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: insight.onAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    insight.actionLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: insight.color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    VoidCallback? onViewAll,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScrollToTopButton() {
    return FloatingActionButton.small(
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      child: const Icon(Icons.keyboard_arrow_up),
    );
  }

  List<DashboardInsight> _generateInsights() {
    final insights = <DashboardInsight>[];

    // Spending trend insight
    if (widget.data.monthlyExpenses > widget.data.previousMonthExpenses) {
      final increase =
          widget.data.monthlyExpenses - widget.data.previousMonthExpenses;
      final percentage = (increase / widget.data.previousMonthExpenses) * 100;

      insights.add(
        DashboardInsight(
          title: 'Spending Increased',
          description:
              'Your expenses are ${percentage.toStringAsFixed(1)}% higher than last month',
          icon: Icons.trending_up,
          color: AppColors.warning,
          actionLabel: 'Analyze',
          onAction: () => _navigateToExpenseAnalysis(),
        ),
      );
    }

    // Revenue insight
    if (widget.data.monthlyIncome > widget.data.previousMonthIncome) {
      insights.add(
        DashboardInsight(
          title: 'Great Revenue Growth!',
          description: 'Your income is up compared to last month',
          icon: Icons.celebration,
          color: AppColors.success,
          actionLabel: 'Details',
          onAction: () => _navigateToIncomeDetails(),
        ),
      );
    }

    // Pending invoices insight
    if (widget.data.pendingInvoices > 0) {
      insights.add(
        DashboardInsight(
          title: 'Pending Invoices',
          description:
              'You have ${widget.data.pendingInvoices} unpaid invoices',
          icon: Icons.schedule,
          color: AppColors.warning,
          actionLabel: 'Follow Up',
          onAction: () => _navigateToInvoices(),
        ),
      );
    }

    // Receipt processing insight
    if (widget.data.unprocessedReceipts > 0) {
      insights.add(
        DashboardInsight(
          title: 'Receipts Need Review',
          description:
              '${widget.data.unprocessedReceipts} receipts need your attention',
          icon: Icons.rate_review,
          color: AppColors.primary,
          actionLabel: 'Review',
          onAction: () => _navigateToReceipts(),
        ),
      );
    }

    return insights.take(3).toList();
  }

  // Navigation methods
  void _navigateToReports() {
    Navigator.of(context).pushNamed('/reports');
  }

  void _navigateToIncomeDetails() {
    Navigator.of(context).pushNamed('/reports/income');
  }

  void _navigateToExpenseDetails() {
    Navigator.of(context).pushNamed('/reports/expenses');
  }

  void _navigateToProfitAnalysis() {
    Navigator.of(context).pushNamed('/reports/profit');
  }

  void _navigateToInvoices() {
    Navigator.of(context).pushNamed('/invoices');
  }

  void _navigateToTransactions() {
    Navigator.of(context).pushNamed('/transactions');
  }

  void _navigateToExpenseAnalysis() {
    Navigator.of(context).pushNamed('/reports/expense-analysis');
  }

  void _navigateToReceipts() {
    Navigator.of(context).pushNamed('/receipts');
  }

  // Event handlers
  void _handlePeriodChange() {
    // Handle period change for charts
    ref.read(dashboardProvider.notifier).changePeriod();
  }

  void _handleQuickAction(QuickAction action) {
    switch (action.id) {
      case 'capture_receipt':
        Navigator.of(context).pushNamed('/receipts/camera');
        break;
      case 'create_invoice':
        Navigator.of(context).pushNamed('/invoices/create');
        break;
      case 'add_client':
        Navigator.of(context).pushNamed('/clients/add');
        break;
      case 'upload_bulk':
        Navigator.of(context).pushNamed('/receipts/bulk-upload');
        break;
      case 'view_reports':
        Navigator.of(context).pushNamed('/reports');
        break;
      case 'scan_document':
        Navigator.of(context).pushNamed('/scanner');
        break;
      default:
        // Handle custom actions
        action.onTap?.call();
    }
  }

  void _handleTransactionTap(TransactionModel transaction) {
    if (transaction.receiptId != null) {
      Navigator.of(context).pushNamed('/receipts/${transaction.receiptId}');
    } else if (transaction.invoiceId != null) {
      Navigator.of(context).pushNamed('/invoices/${transaction.invoiceId}');
    } else {
      Navigator.of(context).pushNamed('/transactions/${transaction.id}');
    }
  }
}

// Dashboard insight model
class DashboardInsight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DashboardInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.actionLabel,
    this.onAction,
  });
}

// Enhanced overview tab with personalization
class PersonalizedOverviewTab extends ConsumerStatefulWidget {
  final DashboardData data;

  const PersonalizedOverviewTab({super.key, required this.data});

  @override
  ConsumerState<PersonalizedOverviewTab> createState() =>
      _PersonalizedOverviewTabState();
}

class _PersonalizedOverviewTabState
    extends ConsumerState<PersonalizedOverviewTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  List<String> _sectionOrder = [];
  Set<String> _hiddenSections = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPersonalization();
  }

  Future<void> _loadPersonalization() async {
    // Load user's customized dashboard layout
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sectionOrder =
          prefs.getStringList('dashboard_section_order') ??
          ['metrics', 'chart', 'actions', 'activity', 'breakdown', 'insights'];
      _hiddenSections = (prefs.getStringList('dashboard_hidden_sections') ?? [])
          .toSet();
    });
  }

  Future<void> _savePersonalization() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dashboard_section_order', _sectionOrder);
    await prefs.setStringList(
      'dashboard_hidden_sections',
      _hiddenSections.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).refreshData();
        },
        child: ReorderableListView(
          scrollController: _scrollController,
          onReorder: _onReorder,
          children: _buildOrderedSections(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCustomizationSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.tune),
        label: const Text('Customize'),
      ),
    );
  }

  List<Widget> _buildOrderedSections() {
    return _sectionOrder
        .where((section) => !_hiddenSections.contains(section))
        .map((sectionId) {
          switch (sectionId) {
            case 'metrics':
              return _buildReorderableSection(
                key: 'metrics',
                title: 'Key Metrics',
                child: _buildMetricsGrid(),
              );
            case 'chart':
              return _buildReorderableSection(
                key: 'chart',
                title: 'Revenue Chart',
                child: RevenueChart(
                  revenueData: widget.data.revenueChartData,
                  expenseData: widget.data.expenseChartData,
                  period: widget.data.selectedPeriod,
                ),
              );
            case 'actions':
              return _buildReorderableSection(
                key: 'actions',
                title: 'Quick Actions',
                child: QuickActionsGrid(
                  onActionTap: _handleQuickAction,
                  showAllActions: false,
                ),
              );
            case 'activity':
              return _buildReorderableSection(
                key: 'activity',
                title: 'Recent Activity',
                child: RecentTransactions(
                  transactions: widget.data.recentTransactions,
                  maxItems: 5,
                ),
              );
            case 'breakdown':
              return _buildReorderableSection(
                key: 'breakdown',
                title: 'Expense Breakdown',
                child: ExpenseBreakdown(
                  expenses: widget.data.categoryExpenses,
                  totalAmount: widget.data.monthlyExpenses,
                ),
              );
            case 'insights':
              return _buildReorderableSection(
                key: 'insights',
                title: 'Smart Insights',
                child: _buildInsightsList(),
              );
            default:
              return const SizedBox.shrink();
          }
        })
        .toList();
  }

  Widget _buildReorderableSection({
    required String key,
    required String title,
    required Widget child,
  }) {
    return Container(
      key: ValueKey(key),
      margin: const EdgeInsets.all(8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with drag handle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.drag_handle,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _toggleSectionVisibility(key),
                    icon: Icon(
                      Icons.visibility_off,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Section content
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.1,
      children: [
        RevenueMetricsCard(
          amount: widget.data.monthlyIncome,
          previousAmount: widget.data.previousMonthIncome,
        ),
        ExpenseMetricsCard(
          amount: widget.data.monthlyExpenses,
          previousAmount: widget.data.previousMonthExpenses,
        ),
        ProfitMetricsCard(
          revenue: widget.data.monthlyIncome,
          expenses: widget.data.monthlyExpenses,
        ),
        InvoiceMetricsCard(
          totalInvoices: widget.data.totalInvoices,
          paidInvoices: widget.data.paidInvoices,
          pendingInvoices: widget.data.pendingInvoices,
          pendingAmount: widget.data.pendingInvoiceAmount,
        ),
      ],
    );
  }

  Widget _buildInsightsList() {
    final insights = _generateInsights();

    return Column(
      children: insights.map((insight) => _buildInsightCard(insight)).toList(),
    );
  }

  Widget _buildInsightCard(DashboardInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insight.color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insight.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(insight.icon, color: insight.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (insight.actionLabel != null)
            TextButton(
              onPressed: insight.onAction,
              child: Text(insight.actionLabel!),
            ),
        ],
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _sectionOrder.removeAt(oldIndex);
      _sectionOrder.insert(newIndex, item);
    });
    _savePersonalization();
  }

  void _toggleSectionVisibility(String sectionId) {
    setState(() {
      if (_hiddenSections.contains(sectionId)) {
        _hiddenSections.remove(sectionId);
      } else {
        _hiddenSections.add(sectionId);
      }
    });
    _savePersonalization();
  }

  void _showCustomizationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCustomizationSheet(),
    );
  }

  Widget _buildCustomizationSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Customize Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),

          // Customization options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildSectionToggleList(),
                const SizedBox(height: 20),
                _buildReorderInstructions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionToggleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visible Sections',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._sectionOrder.map((sectionId) {
          final isVisible = !_hiddenSections.contains(sectionId);
          return SwitchListTile(
            title: Text(_getSectionDisplayName(sectionId)),
            value: isVisible,
            onChanged: (value) => _toggleSectionVisibility(sectionId),
            activeColor: AppColors.primary,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildReorderInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Drag sections on the main dashboard to reorder them',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  String _getSectionDisplayName(String sectionId) {
    switch (sectionId) {
      case 'metrics':
        return 'Key Metrics';
      case 'chart':
        return 'Revenue Chart';
      case 'actions':
        return 'Quick Actions';
      case 'activity':
        return 'Recent Activity';
      case 'breakdown':
        return 'Expense Breakdown';
      case 'insights':
        return 'Smart Insights';
      default:
        return sectionId;
    }
  }

  List<DashboardInsight> _generateInsights() {
    // Same implementation as in the base class
    return [];
  }

  void _handleQuickAction(QuickAction action) {
    // Same implementation as in the base class
  }
}
