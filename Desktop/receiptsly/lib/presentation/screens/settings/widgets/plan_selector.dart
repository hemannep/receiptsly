// lib/presentation/screens/settings/widgets/plan_selector.dart
import 'package:flutter/material.dart';

class PlanSelector extends StatelessWidget {
  final String planId;
  final String name;
  final double monthlyPrice;
  final double annualPrice;
  final List<String> features;
  final List<String> limitations;
  final bool isCurrentPlan;
  final bool isRecommended;
  final bool isAnnualBilling;
  final bool isLoading;
  final VoidCallback onSelectPlan;

  const PlanSelector({
    super.key,
    required this.planId,
    required this.name,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.features,
    required this.limitations,
    required this.isCurrentPlan,
    required this.isRecommended,
    required this.isAnnualBilling,
    required this.isLoading,
    required this.onSelectPlan,
  });

  String get _displayPrice {
    if (monthlyPrice == 0) return 'Free';

    final price = isAnnualBilling ? annualPrice : monthlyPrice;
    final period = isAnnualBilling ? 'year' : 'month';

    return '\$${price.toStringAsFixed(2)} / $period';
  }

  String? get _savingsText {
    if (monthlyPrice == 0 || !isAnnualBilling) return null;

    final monthlyCost = monthlyPrice * 12;
    final savings = monthlyCost - annualPrice;
    final savingsPercent = (savings / monthlyCost * 100).round();

    return 'Save $savingsPercent% (\$${savings.toStringAsFixed(2)}/year)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isRecommended ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentPlan
              ? theme.primaryColor
              : isRecommended
              ? theme.primaryColor.withOpacity(0.5)
              : Colors.transparent,
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isRecommended)
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
                                'POPULAR',
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
                      Row(
                        children: [
                          Text(
                            _displayPrice,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          if (_savingsText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _savingsText!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'CURRENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Features
            if (features.isNotEmpty) ...[
              Text(
                'Included:',
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
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(feature, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Limitations
            if (limitations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Limitations:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...limitations.map(
                (limitation) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.remove_circle, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          limitation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: isCurrentPlan
                  ? OutlinedButton(
                      onPressed: null,
                      child: const Text('Current Plan'),
                    )
                  : ElevatedButton(
                      onPressed: isLoading ? null : onSelectPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRecommended
                            ? theme.primaryColor
                            : null,
                        foregroundColor: isRecommended ? Colors.white : null,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              planId == 'free'
                                  ? 'Downgrade to Free'
                                  : 'Upgrade to $name',
                            ),
                    ),
            ),

            // Popular plan additional info
            if (isRecommended) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: theme.primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Most popular choice for small businesses',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
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
}
