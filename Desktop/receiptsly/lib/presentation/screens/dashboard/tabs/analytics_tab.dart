import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/core/utils/currency_utils.dart';
import 'package:receiptsly/core/utils/date_utils.dart';
import 'package:receiptsly/data/models/dashboard/dashboard_data.dart';
import 'package:receiptsly/data/models/analytics/chart_data.dart';
import 'package:receiptsly/presentation/widgets/animations/fade_animation.dart';
import 'package:receiptsly/presentation/widgets/animations/scale_animation.dart';

class AnalyticsTab extends ConsumerStatefulWidget {
  final DashboardData data;

  const AnalyticsTab({super.key, required this.data});

  @override
  ConsumerState<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends ConsumerState<AnalyticsTab>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _periodTabController;
  late TabController _chartTabController;

  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.month;
  AnalyticsChartType _selectedChartType = AnalyticsChartType.revenue;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _periodTabController = TabController(length: 4, vsync: this);
    _chartTabController = TabController(length: 3, vsync: this);

    _periodTabController.addListener(() {
      if (!_periodTabController.indexIsChanging) {
        setState(() {
          _selectedPeriod = AnalyticsPeriod.values[_periodTabController.index];
        });
        _loadAnalyticsData();
      }
    });

    _chartTabController.addListener(() {
      if (!_chartTabController.indexIsChanging) {
        setState(() {
          _selectedChartType =
              AnalyticsChartType.values[_chartTabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _periodTabController.dispose();
    _chartTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    await ref
        .read(dashboardProvider.notifier)
        .loadAnalyticsData(_selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAnalyticsData();
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalyticsHeader(),
              _buildPeriodSelector(),
              _buildKeyMetricsCards(),
              _buildChartTypeSelector(),
              _buildMainChart(),
              _buildDetailedAnalytics(),
              _buildTrendAnalysis(),
              _buildCategoryPerformance(),
              _buildPredictiveInsights(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Analytics',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deep insights into your financial performance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showAnalyticsSettings,
                  icon: const Icon(Icons.settings, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildQuickStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    final profit = widget.data.monthlyIncome - widget.data.monthlyExpenses;
    final profitMargin = widget.data.monthlyIncome > 0
        ? (profit / widget.data.monthlyIncome) * 100
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildQuickStat(
            'Profit Margin',
            '${profitMargin.toStringAsFixed(1)}%',
            Icons.trending_up,
            profitMargin > 0 ? Colors.white : Colors.red.shade100,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickStat(
            'Avg Transaction',
            CurrencyUtils.formatCompact(_calculateAverageTransaction()),
            Icons.receipt,
            Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickStat(
            'Growth Rate',
            '${_calculateGrowthRate().toStringAsFixed(1)}%',
            Icons.show_chart,
            Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _periodTabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Week'),
          Tab(text: 'Month'),
          Tab(text: 'Quarter'),
          Tab(text: 'Year'),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsCards() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMetricCard(
            'Total Revenue',
            CurrencyUtils.format(_getTotalRevenue()),
            _getRevenueChange(),
            Icons.attach_money,
            AppColors.success,
          ),
          _buildMetricCard(
            'Total Expenses',
            CurrencyUtils.format(_getTotalExpenses()),
            _getExpenseChange(),
            Icons.shopping_cart,
            AppColors.warning,
          ),
          _buildMetricCard(
            'Net Profit',
            CurrencyUtils.format(_getTotalRevenue() - _getTotalExpenses()),
            _getProfitChange(),
            Icons.account_balance_wallet,
            AppColors.primary,
          ),
          _buildMetricCard(
            'Active Clients',
            '${widget.data.activeClients}',
            _getClientChange(),
            Icons.people,
            AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    double changePercent,
    IconData icon,
    Color color,
  ) {
    final isPositive = changePercent > 0;
    final changeColor = isPositive ? AppColors.success : AppColors.error;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: changeColor,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${changePercent.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _chartTabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Revenue vs Expenses'),
          Tab(text: 'Category Breakdown'),
          Tab(text: 'Trend Analysis'),
        ],
      ),
    );
  }

  Widget _buildMainChart() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TabBarView(
        controller: _chartTabController,
        children: [
          _buildRevenueExpenseChart(),
          _buildCategoryChart(),
          _buildTrendChart(),
        ],
      ),
    );
  }
}
