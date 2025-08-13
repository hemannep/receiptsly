// lib/presentation/screens/dashboard/widgets/revenue_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/core/utils/currency_utils.dart';
import 'package:receiptsly/core/utils/date_utils.dart';
import 'package:receiptsly/data/models/analytics/chart_data.dart';

class RevenueChart extends StatefulWidget {
  final List<ChartDataPoint> revenueData;
  final List<ChartDataPoint> expenseData;
  final ChartPeriod period;
  final bool isLoading;
  final VoidCallback? onPeriodChanged;

  const RevenueChart({
    super.key,
    required this.revenueData,
    required this.expenseData,
    required this.period,
    this.isLoading = false,
    this.onPeriodChanged,
  });

  @override
  State<RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedIndex;
  ChartType _chartType = ChartType.line;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildLegend(),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: widget.isLoading ? _buildLoadingChart() : _buildChart(),
          ),
          const SizedBox(height: 16),
          _buildSummary(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue & Expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getPeriodText(),
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        const Spacer(),
        _buildChartTypeToggle(),
        const SizedBox(width: 8),
        _buildPeriodSelector(),
      ],
    );
  }

  Widget _buildChartTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.show_chart,
            isSelected: _chartType == ChartType.line,
            onTap: () => setState(() => _chartType = ChartType.line),
          ),
          _buildToggleButton(
            icon: Icons.bar_chart,
            isSelected: _chartType == ChartType.bar,
            onTap: () => setState(() => _chartType = ChartType.bar),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return PopupMenuButton<ChartPeriod>(
      icon: Icon(Icons.date_range, color: AppColors.primary),
      onSelected: (period) {
        widget.onPeriodChanged?.call();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: ChartPeriod.week, child: Text('This Week')),
        const PopupMenuItem(
          value: ChartPeriod.month,
          child: Text('This Month'),
        ),
        const PopupMenuItem(
          value: ChartPeriod.quarter,
          child: Text('This Quarter'),
        ),
        const PopupMenuItem(value: ChartPeriod.year, child: Text('This Year')),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem('Revenue', AppColors.primary),
        const SizedBox(width: 20),
        _buildLegendItem('Expenses', AppColors.warning),
        const Spacer(),
        if (_getTotalRevenue() > 0 || _getTotalExpenses() > 0)
          Text(
            'Net: ${CurrencyUtils.format(_getTotalRevenue() - _getTotalExpenses())}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getTotalRevenue() - _getTotalExpenses() >= 0
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _chartType == ChartType.line
            ? _buildLineChart()
            : _buildBarChart();
      },
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.border.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.border.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: _bottomTitleWidgets,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: null,
              getTitlesWidget: _leftTitleWidgets,
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: widget.revenueData.length.toDouble() - 1,
        minY: 0,
        maxY: _getMaxY(),
        lineBarsData: [
          // Revenue line
          LineChartBarData(
            spots: _getRevenueSpots(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.8), AppColors.primary],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Expense line
          LineChartBarData(
            spots: _getExpenseSpots(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [AppColors.warning.withOpacity(0.8), AppColors.warning],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.warning,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withOpacity(0.1),
                  AppColors.warning.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.surface,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final textStyle = TextStyle(
                  color: touchedSpot.barIndex == 0
                      ? AppColors.primary
                      : AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                );
                return LineTooltipItem(
                  '${touchedSpot.barIndex == 0 ? 'Revenue' : 'Expenses'}\n${CurrencyUtils.format(touchedSpot.y)}',
                  textStyle,
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppColors.surface,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rodIndex == 0 ? 'Revenue' : 'Expenses'}\n${CurrencyUtils.format(rod.toY)}',
                TextStyle(
                  color: rodIndex == 0 ? AppColors.primary : AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _bottomTitleWidgets,
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: _leftTitleWidgets,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border.withOpacity(0.3)),
        ),
        barGroups: _getBarGroups(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.border.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingChart() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSummary() {
    final totalRevenue = _getTotalRevenue();
    final totalExpenses = _getTotalExpenses();
    final netProfit = totalRevenue - totalExpenses;
    final profitMargin = totalRevenue > 0
        ? (netProfit / totalRevenue) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Total Revenue',
              CurrencyUtils.format(totalRevenue),
              AppColors.primary,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Total Expenses',
              CurrencyUtils.format(totalExpenses),
              AppColors.warning,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Net Profit',
              CurrencyUtils.format(netProfit),
              netProfit >= 0 ? AppColors.success : AppColors.error,
              subtitle: '${profitMargin.toStringAsFixed(1)}% margin',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  List<FlSpot> _getRevenueSpots() {
    return widget.revenueData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value * _animation.value);
    }).toList();
  }

  List<FlSpot> _getExpenseSpots() {
    return widget.expenseData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value * _animation.value);
    }).toList();
  }

  List<BarChartGroupData> _getBarGroups() {
    return widget.revenueData.asMap().entries.map((entry) {
      final index = entry.key;
      final revenueValue = entry.value.value * _animation.value;
      final expenseValue = index < widget.expenseData.length
          ? widget.expenseData[index].value * _animation.value
          : 0.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: revenueValue,
            color: AppColors.primary,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: expenseValue,
            color: AppColors.warning,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

    if (value.toInt() >= widget.revenueData.length) {
      return const SizedBox.shrink();
    }

    final dataPoint = widget.revenueData[value.toInt()];
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(_formatAxisLabel(dataPoint.label), style: style),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(CurrencyUtils.formatCompact(value), style: style),
    );
  }

  double _getMaxY() {
    final maxRevenue = widget.revenueData.isEmpty
        ? 0.0
        : widget.revenueData
              .map((e) => e.value)
              .reduce((a, b) => a > b ? a : b);
    final maxExpense = widget.expenseData.isEmpty
        ? 0.0
        : widget.expenseData
              .map((e) => e.value)
              .reduce((a, b) => a > b ? a : b);

    final max = maxRevenue > maxExpense ? maxRevenue : maxExpense;
    return (max * 1.2).ceilToDouble();
  }

  double _getTotalRevenue() {
    return widget.revenueData.fold(0.0, (sum, item) => sum + item.value);
  }

  double _getTotalExpenses() {
    return widget.expenseData.fold(0.0, (sum, item) => sum + item.value);
  }

  String _getPeriodText() {
    switch (widget.period) {
      case ChartPeriod.week:
        return 'This Week';
      case ChartPeriod.month:
        return 'This Month';
      case ChartPeriod.quarter:
        return 'This Quarter';
      case ChartPeriod.year:
        return 'This Year';
    }
  }

  String _formatAxisLabel(String label) {
    switch (widget.period) {
      case ChartPeriod.week:
        return DateUtils.formatWeekday(label);
      case ChartPeriod.month:
        return DateUtils.formatDay(label);
      case ChartPeriod.quarter:
        return DateUtils.formatMonth(label);
      case ChartPeriod.year:
        return DateUtils.formatMonthShort(label);
    }
  }
}

enum ChartType { line, bar }

enum ChartPeriod { week, month, quarter, year }
