// lib/presentation/screens/reports/tax_estimate_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/tax_estimate_entity.dart';
import '../../providers/tax_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/charts/pie_chart.dart';
import '../../widgets/charts/bar_chart.dart';

class TaxEstimateScreen extends ConsumerStatefulWidget {
  const TaxEstimateScreen({super.key});

  @override
  ConsumerState<TaxEstimateScreen> createState() => _TaxEstimateScreenState();
}

class _TaxEstimateScreenState extends ConsumerState<TaxEstimateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tax year selection
  int _selectedTaxYear = DateTime.now().year;
  
  // Income settings
  double _estimatedIncome = 0;
  double _actualIncome = 0;
  FilingStatus _filingStatus = FilingStatus.single;
  
  // Deduction settings
  bool _useStandardDeduction = true;
  double _customDeductions = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load tax estimates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTaxEstimate();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTaxEstimate() {
    ref.read(taxProvider.notifier).calculateTaxEstimate(
      taxYear: _selectedTaxYear,
      filingStatus: _filingStatus,
      useStandardDeduction: _useStandardDeduction,
      customDeductions: _customDeductions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taxState = ref.watch(taxProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Tax Estimate'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showTaxSettings,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Report'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'schedule_payment',
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('Schedule Payment'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'tax_tips',
                child: ListTile(
                  leading: Icon(Icons.lightbulb),
                  title: Text('Tax Tips'),
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
            Tab(text: 'Deductions'),
            Tab(text: 'Quarterly'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tax Year Selector & Quick Stats
          _buildHeaderSection(taxState, theme),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(taxState, theme),
                _buildDeductionsTab(taxState, theme),
                _buildQuarterlyTab(taxState, theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaxCalculator(),
        icon: const Icon(Icons.calculate),
        label: const Text('Tax Calculator'),
      ),
    );
  }

  Widget _buildHeaderSection(TaxState taxState, ThemeData theme) {
    if (taxState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: AppLoader(),
      );
    }

    final estimate = taxState.estimate;
    if (estimate == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tax Year Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax Year $_selectedTaxYear',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton(
                onPressed: _selectTaxYear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('Change Year'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Estimated Tax',
                  '\$${estimate.totalTax.toStringAsFixed(2)}',
                  Icons.account_balance,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Effective Rate',
                  '${estimate.effectiveRate.toStringAsFixed(1)}%',
                  Icons.percent,
                  Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress to next bracket
          if (estimate.nextBracketAmount != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                     'Next tax bracket at \${estimate.nextBracketAmount!.toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '\${(estimate.nextBracketAmount! - estimate.taxableIncome).toStringAsFixed(0)} away',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(TaxState taxState, ThemeData theme) {
    final estimate = taxState.estimate;
    if (estimate == null) {
      return const Center(child: Text('No tax estimate available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tax Breakdown Card
          _buildTaxBreakdownCard(estimate, theme),
          
          const SizedBox(height: 24),
          
          // Income Summary Card
          _buildIncomeSummaryCard(estimate, theme),
          
          const SizedBox(height: 24),
          
          // Tax Brackets Chart
          _buildTaxBracketsCard(estimate, theme),
          
          const SizedBox(height: 24),
          
          // Comparison Card
          _buildComparisonCard(estimate, theme),
          
          const SizedBox(height: 24),
          
          // Action Items Card
          _buildActionItemsCard(estimate, theme),
        ],
      ),
    );
  }

  Widget _buildTaxBreakdownCard(TaxEstimateEntity estimate, ThemeData theme) {
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
              'Tax Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: AppPieChart(
                data: [
                  ChartData('Federal Tax', estimate.federalTax),
                  ChartData('State Tax', estimate.stateTax),
                  ChartData('Self-Employment Tax', estimate.selfEmploymentTax),
                  ChartData('After Tax', estimate.afterTaxIncome),
                ],
                showLegend: true,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildBreakdownRow(theme, 'Gross Income', estimate.grossIncome, isHeader: true),
            _buildBreakdownRow(theme, 'Total Deductions', -estimate.totalDeductions),
            _buildBreakdownRow(theme, 'Taxable Income', estimate.taxableIncome, isSubtotal: true),
            
            const Divider(),
            
            _buildBreakdownRow(theme, 'Federal Tax', -estimate.federalTax),
            _buildBreakdownRow(theme, 'State Tax', -estimate.stateTax),
            _buildBreakdownRow(theme, 'Self-Employment Tax', -estimate.selfEmploymentTax),
            
            const Divider(),
            
            _buildBreakdownRow(theme, 'Total Tax', -estimate.totalTax, isTotal: true),
            _buildBreakdownRow(theme, 'After-Tax Income', estimate.afterTaxIncome, isTotal: true, isPositive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    ThemeData theme,
    String label,
    double amount, {
    bool isHeader = false,
    bool isSubtotal = false,
    bool isTotal = false,
    bool isPositive = false,
  }) {
    Color textColor = theme.colorScheme.onSurface;
    FontWeight fontWeight = FontWeight.normal;
    
    if (isHeader || isTotal) {
      fontWeight = FontWeight.bold;
    }
    
    if (isTotal) {
      textColor = isPositive ? Colors.green : theme.colorScheme.error;
    } else if (amount < 0) {
      textColor = theme.colorScheme.error;
    } else if (amount > 0 && !isHeader && !isSubtotal) {
      textColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: fontWeight,
            ),
          ),
          Text(
            amount >= 0 
              ? '\${amount.toStringAsFixed(2)}'
              : '-\${amount.abs().toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSummaryCard(TaxEstimateEntity estimate, ThemeData theme) {
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
              'Income Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildIncomeStatCard(
                    theme,
                    'Business Income',
                    estimate.businessIncome,
                    Icons.business,
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildIncomeStatCard(
                    theme,
                    '1099 Income',
                    estimate.contractIncome,
                    Icons.receipt_long,
                    theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildIncomeStatCard(
                    theme,
                    'Investment Income',
                    estimate.investmentIncome,
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildIncomeStatCard(
                    theme,
                    'Other Income',
                    estimate.otherIncome,
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeStatCard(
    ThemeData theme,
    String title,
    double amount,
    IconData icon,
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '\${amount.toStringAsFixed(2)}',
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

  Widget _buildTaxBracketsCard(TaxEstimateEntity estimate, ThemeData theme) {
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
              'Tax Brackets',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 250,
              child: AppBarChart(
                data: estimate.taxBrackets.map((bracket) {
                  return ChartData(
                    '${(bracket.rate * 100).toStringAsFixed(0)}%',
                    bracket.taxOwed,
                  );
                }).toList(),
                xAxisLabel: 'Tax Rate',
                yAxisLabel: 'Tax Owed (\$)',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current bracket highlight
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your income falls in the ${(estimate.marginalRate * 100).toStringAsFixed(0)}% tax bracket',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(TaxEstimateEntity estimate, ThemeData theme) {
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
              'Year-over-Year Comparison',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (estimate.previousYearData != null) ...[
              _buildComparisonRow(
                theme,
                'Total Tax',
                estimate.totalTax,
                estimate.previousYearData!.totalTax,
              ),
              _buildComparisonRow(
                theme,
                'Effective Rate',
                estimate.effectiveRate,
                estimate.previousYearData!.effectiveRate,
                isPercentage: true,
              ),
              _buildComparisonRow(
                theme,
                'After-Tax Income',
                estimate.afterTaxIncome,
                estimate.previousYearData!.afterTaxIncome,
              ),
            ] else
              Center(
                child: Text(
                  'No previous year data available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    ThemeData theme,
    String label,
    double currentValue,
    double previousValue, {
    bool isPercentage = false,
  }) {
    final difference = currentValue - previousValue;
    final percentChange = previousValue != 0 ? (difference / previousValue) * 100 : 0;
    final isIncrease = difference > 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isPercentage 
                  ? '${currentValue.toStringAsFixed(1)}%'
                  : '\${currentValue.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: isIncrease ? Colors.red : Colors.green,
                  ),
                  Text(
                    '${percentChange.abs().toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isIncrease ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItemsCard(TaxEstimateEntity estimate, ThemeData theme) {
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
              'Recommended Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...estimate.recommendations.map((recommendation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: recommendation.priority.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        recommendation.priority.icon,
                        color: recommendation.priority.color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            recommendation.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          if (recommendation.potentialSavings > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Potential savings: \${recommendation.potentialSavings.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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

  Widget _buildDeductionsTab(TaxState taxState, ThemeData theme) {
    final estimate = taxState.estimate;
    if (estimate == null) {
      return const Center(child: Text('No deduction data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deduction Strategy Card
          _buildDeductionStrategyCard(estimate, theme),
          
          const SizedBox(height: 24),
          
          // Business Deductions Card
          _buildBusinessDeductionsCard(estimate, theme),
          
          const SizedBox(height: 24),
          
          // Itemized vs Standard Card
          _buildItemizedVsStandardCard(estimate, theme),
          
          const SizedBox(height: 24),
          
          // Missed Deductions Card
          _buildMissedDeductionsCard(estimate, theme),
        ],
      ),
    );
  }

  Widget _buildDeductionStrategyCard(TaxEstimateEntity estimate, ThemeData theme) {
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
              'Deduction Strategy',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _useStandardDeduction 
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surface,
                      border: Border.all(
                        color: _useStandardDeduction 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.description,
                          color: _useStandardDeduction 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Standard',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\${estimate.standardDeduction.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: !_useStandardDeduction 
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surface,
                      border: Border.all(
                        color: !_useStandardDeduction 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: !_useStandardDeduction 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Itemized',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\${estimate.itemizedDeductions.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: estimate.itemizedDeductions > estimate.standardDeduction
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    estimate.itemizedDeductions > estimate.standardDeduction
                      ? Icons.lightbulb
                      : Icons.info,
                    color: estimate.itemizedDeductions > estimate.standardDeduction
                      ? Colors.green
                      : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      estimate.itemizedDeductions > estimate.standardDeduction
                        ? 'Itemizing deductions could save you \${((estimate.itemizedDeductions - estimate.standardDeduction) * estimate.marginalRate).toStringAsFixed(2)}'
                        : 'Standard deduction is better for you',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessDeductionsCard(TaxEstimateEntity estimate, ThemeData theme) {
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
              'Business Deductions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: AppPieChart(
                data: estimate.businessDeductions.map((deduction) {
                  return ChartData(deduction.category, deduction.amount);
                }).toList(),
                showLegend: true,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...estimate.businessDeductions.map((deduction) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      deduction.category,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '\${deduction.amount.toStringAsFixed(2)}',
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

  Widget _buildItemizedVsStandardCard(TaxEstimateEntity estimate, ThemeData theme) {
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
              'Itemized Deductions Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDeductionRow(theme, 'State & Local Taxes', estimate.saltDeduction),
            _buildDeductionRow(theme, 'Mortgage Interest', estimate.mortgageInterest),
            _buildDeductionRow(theme, 'Charitable Contributions', estimate.charitableContributions),
            _buildDeductionRow(theme, 'Medical Expenses', estimate.medicalExpenses),
            _buildDeductionRow(theme, 'Other Itemized', estimate.otherItemized),
            
            const Divider(),
            
            _buildDeductionRow(
              theme, 
              'Total Itemized', 
              estimate.itemizedDeductions,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionRow(
    ThemeData theme,
    String label,
    double amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\${amount.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissedDeductionsCard(TaxEstimateEntity estimate, ThemeData theme) {
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
                  'Potential Missed Deductions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (estimate.missedDeductions.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Great! No obvious missed deductions found.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...estimate.missedDeductions.map((deduction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deduction.category,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                deduction.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\${deduction.potentialAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuarterlyTab(TaxState taxState, ThemeData theme) {
    final estimate = taxState.estimate;
    if (estimate == null) {
      return const Center(child: Text('No quarterly data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quarterly Payments Overview
          _buildQuarterlyOverviewCard(estimate, theme),
          
          const SizedBox(height: 24),
          
          // Payment Schedule
          _buildPaymentScheduleCard(estimate, theme),
          
          const SizedBox(height: 24),
          
          // Safe Harbor Rules
          _buildSafeHarborCard(estimate, theme),
          
          const SizedBox(height: 24),
          
          // Payment History
          _buildPaymentHistoryCard(estimate, theme),
        ],
      ),
    );
  }

  Widget _buildQuarterlyOverviewCard(TaxEstimateEntity estimate, ThemeData theme) {
    final quarterlyPayment = estimate.totalTax / 4;
    
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
              'Quarterly Estimated Payments',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommended Quarterly Payment',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '\${quarterlyPayment.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _schedulePayment(quarterlyPayment),
                    child: const Text('Schedule'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentScheduleCard(TaxEstimateEntity estimate, ThemeData theme) {
    final quarters = [
      {'name': 'Q1 $_selectedTaxYear', 'due': 'April 15, $_selectedTaxYear', 'amount': estimate.totalTax / 4},
      {'name': 'Q2 $_selectedTaxYear', 'due': 'June 15, $_selectedTaxYear', 'amount': estimate.totalTax / 4},
      {'name': 'Q3 $_selectedTaxYear', 'due': 'September 15, $_selectedTaxYear', 'amount': estimate.totalTax / 4},
      {'name': 'Q4 $_selectedTaxYear', 'due': 'January 15, ${_selectedTaxYear + 1}', 'amount': estimate.totalTax / 4},
    ];

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
              'Payment Schedule',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...quarters.asMap().entries.map((entry) {
              final index = entry.key;
              final quarter = entry.value;
              final isPaid = estimate.quarterlyPayments.length > index && 
                            estimate.quarterlyPayments[index].isPaid;
              final dueDate = DateTime.parse('${_selectedTaxYear}-${_getMonthFromQuarter(index + 1)}-15');
              final isOverdue = DateTime.now().isAfter(dueDate) && !isPaid;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isPaid 
                      ? Colors.green.withOpacity(0.1)
                      : isOverdue 
                        ? Colors.red.withOpacity(0.1)
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: isPaid 
                        ? Colors.green
                        : isOverdue 
                          ? Colors.red
                          : theme.colorScheme.outline.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPaid 
                            ? Colors.green
                            : isOverdue 
                              ? Colors.red
                              : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPaid 
                            ? Icons.check
                            : isOverdue 
                              ? Icons.warning
                              : Icons.schedule,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quarter['name'] as String,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Due: ${quarter['due']}',
                              style: theme.textTheme.bodyMedium?.copyWith(
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
                            '\${(quarter['amount'] as double).toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isPaid)
                            Text(
                              'Paid',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else if (isOverdue)
                            Text(
                              'Overdue',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeHarborCard(TaxEstimateEntity estimate, ThemeData theme) {
    final safeHarborAmount = estimate.previousYearTax * 1.1; // 110% of previous year
    final minimumRequired = estimate.totalTax * 0.9; // 90% of current year
    
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
              children: [
                Icon(
                  Icons.shield,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Safe Harbor Rules',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To avoid penalties, pay the smaller of:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSafeHarborOption(
                    theme,
                    '90% of current year tax',
                    minimumRequired,
                    minimumRequired <= safeHarborAmount,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildSafeHarborOption(
                    theme,
                    '110% of last year tax',
                    safeHarborAmount,
                    safeHarborAmount < minimumRequired,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommended safe harbor payment: \${(safeHarborAmount < minimumRequired ? safeHarborAmount : minimumRequired).toStringAsFixed(2)} quarterly',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeHarborOption(
    ThemeData theme,
    String description,
    double amount,
    bool isRecommended,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecommended 
          ? Colors.green.withOpacity(0.2)
          : Colors.transparent,
        border: Border.all(
          color: isRecommended 
            ? Colors.green
            : theme.colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (isRecommended)
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          if (isRecommended) const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '\${amount.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isRecommended ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryCard(TaxEstimateEntity estimate, ThemeData theme) {
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
              'Payment History',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (estimate.paymentHistory.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.payment,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No payments recorded yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...estimate.paymentHistory.map((payment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDate(payment.date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\${payment.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
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
  String _getMonthFromQuarter(int quarter) {
    switch (quarter) {
      case 1: return '04'; // April
      case 2: return '06'; // June
      case 3: return '09'; // September
      case 4: return '01'; // January (next year)
      default: return '01';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _selectTaxYear() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Tax Year'),
        content: SizedBox(
          height: 200,
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
              final year = DateTime.now().year - index;
              return ListTile(
                title: Text(year.toString()),
                selected: year == _selectedTaxYear,
                onTap: () {
                  setState(() {
                    _selectedTaxYear = year;
                  });
                  Navigator.pop(context);
                  _loadTaxEstimate();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTaxSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Settings'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<FilingStatus>(
                decoration: const InputDecoration(
                  labelText: 'Filing Status',
                ),
                value: _filingStatus,
                items: FilingStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    _filingStatus = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Use Standard Deduction'),
                value: _useStandardDeduction,
                onChanged: (value) {
                  setDialogState(() {
                    _useStandardDeduction = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              if (!_useStandardDeduction) ...[
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Custom Deductions',
                    prefixText: '\
      // lib/presentation/screens/reports/tax_estimate_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/tax_estimate_entity.dart';
import '../../providers/tax_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/charts/pie_chart.dart';
import '../../widgets/charts/bar_chart.dart';

class TaxEstimateScreen extends ConsumerStatefulWidget {
  const TaxEstimateScreen({super.key});

  @override
  ConsumerState<TaxEstimateScreen> createState() => _TaxEstimateScreenState();
}

class _TaxEstimateScreenState extends ConsumerState<TaxEstimateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tax year selection
  int _selectedTaxYear = DateTime.now().year;
  
  // Income settings
  double _estimatedIncome = 0;
  double _actualIncome = 0;
  FilingStatus _filingStatus = FilingStatus.single;
  
  // Deduction settings
  bool _useStandardDeduction = true;
  double _customDeductions = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load tax estimates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTaxEstimate();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTaxEstimate() {
    ref.read(taxProvider.notifier).calculateTaxEstimate(
      taxYear: _selectedTaxYear,
      filingStatus: _filingStatus,
      useStandardDeduction: _useStandardDeduction,
      customDeductions: _customDeductions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taxState = ref.watch(taxProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Tax Estimate'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showTaxSettings,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Report'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'schedule_payment',
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('Schedule Payment'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'tax_tips',
                child: ListTile(
                  leading: Icon(Icons.lightbulb),
                  title: Text('Tax Tips'),
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
            Tab(text: 'Deductions'),
            Tab(text: 'Quarterly'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tax Year Selector & Quick Stats
          _buildHeaderSection(taxState, theme),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(taxState, theme),
                _buildDeductionsTab(taxState, theme),
                _buildQuarterlyTab(taxState, theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaxCalculator(),
        icon: const Icon(Icons.calculate),
        label: const Text('Tax Calculator'),
      ),
    );
  }

  Widget _buildHeaderSection(TaxState taxState, ThemeData theme) {
    if (taxState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: AppLoader(),
      );
    }

    final estimate = taxState.estimate;
    if (estimate == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tax Year Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax Year $_selectedTaxYear',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton(
                onPressed: _selectTaxYear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('Change Year'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Estimated Tax',
                  '\$${estimate.totalTax.toStringAsFixed(2)}',
                  Icons.account_balance,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Effective Rate',
                  '${estimate.effectiveRate.toStringAsFixed(1)}%',
                  Icons.percent,
                  Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress to next bracket
          if (estimate.nextBracketAmount != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next tax bracket at \$${estimate.nextBracketAmount!.toStringAsFixed(0)}',
                      style: theme.textTheme.body,
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _customDeductions.toString(),
                  onChanged: (value) {
                    _customDeductions = double.tryParse(value) ?? 0;
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
              _loadTaxEstimate();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showTaxCalculator() {
    context.push('/tax-calculator');
  }

  void _schedulePayment(double amount) {
    // Navigate to payment scheduling
    context.push('/payments/schedule?amount=${amount.toStringAsFixed(2)}');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportTaxReport();
        break;
      case 'schedule_payment':
        _schedulePayment(0);
        break;
      case 'tax_tips':
        _showTaxTips();
        break;
    }
  }

  void _exportTaxReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting tax report...')),
    );
  }

  void _showTaxTips() {
    context.push('/tax-tips');
  }
}

// Supporting models
enum FilingStatus {
  single('Single'),
  marriedJointly('Married Filing Jointly'),
  marriedSeparately('Married Filing Separately'),
  headOfHousehold('Head of Household');

  const FilingStatus(this.displayName);
  final String displayName;
}

class ChartData {
  final String label;
  final double value;

  ChartData(this.label, this.value);
}
      // lib/presentation/screens/reports/tax_estimate_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/tax_estimate_entity.dart';
import '../../providers/tax_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/charts/pie_chart.dart';
import '../../widgets/charts/bar_chart.dart';

class TaxEstimateScreen extends ConsumerStatefulWidget {
  const TaxEstimateScreen({super.key});

  @override
  ConsumerState<TaxEstimateScreen> createState() => _TaxEstimateScreenState();
}

class _TaxEstimateScreenState extends ConsumerState<TaxEstimateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tax year selection
  int _selectedTaxYear = DateTime.now().year;
  
  // Income settings
  double _estimatedIncome = 0;
  double _actualIncome = 0;
  FilingStatus _filingStatus = FilingStatus.single;
  
  // Deduction settings
  bool _useStandardDeduction = true;
  double _customDeductions = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load tax estimates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTaxEstimate();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTaxEstimate() {
    ref.read(taxProvider.notifier).calculateTaxEstimate(
      taxYear: _selectedTaxYear,
      filingStatus: _filingStatus,
      useStandardDeduction: _useStandardDeduction,
      customDeductions: _customDeductions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taxState = ref.watch(taxProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Tax Estimate'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showTaxSettings,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Report'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'schedule_payment',
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('Schedule Payment'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'tax_tips',
                child: ListTile(
                  leading: Icon(Icons.lightbulb),
                  title: Text('Tax Tips'),
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
            Tab(text: 'Deductions'),
            Tab(text: 'Quarterly'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tax Year Selector & Quick Stats
          _buildHeaderSection(taxState, theme),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(taxState, theme),
                _buildDeductionsTab(taxState, theme),
                _buildQuarterlyTab(taxState, theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaxCalculator(),
        icon: const Icon(Icons.calculate),
        label: const Text('Tax Calculator'),
      ),
    );
  }

  Widget _buildHeaderSection(TaxState taxState, ThemeData theme) {
    if (taxState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: AppLoader(),
      );
    }

    final estimate = taxState.estimate;
    if (estimate == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tax Year Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax Year $_selectedTaxYear',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton(
                onPressed: _selectTaxYear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('Change Year'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Estimated Tax',
                  '\$${estimate.totalTax.toStringAsFixed(2)}',
                  Icons.account_balance,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Effective Rate',
                  '${estimate.effectiveRate.toStringAsFixed(1)}%',
                  Icons.percent,
                  Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress to next bracket
          if (estimate.nextBracketAmount != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next tax bracket at \$${estimate.nextBracketAmount!.toStringAsFixed(0)}',
                      style: theme.textTheme.body