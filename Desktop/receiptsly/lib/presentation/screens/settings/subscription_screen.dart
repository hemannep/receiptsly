// lib/presentation/screens/settings/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_button.dart';
import 'widgets/plan_selector.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String _currentPlan = 'free';
  bool _isAnnual = false;
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _plans = {
    'free': {
      'name': 'Free',
      'monthlyPrice': 0,
      'annualPrice': 0,
      'receiptLimit': 50,
      'features': [
        '50 receipts per month',
        'Basic OCR processing',
        'Simple invoicing',
        'Email support',
        'Mobile app access',
      ],
      'limitations': [
        'Limited reporting',
        'No chat integrations',
        'Basic templates only',
      ],
    },
    'starter': {
      'name': 'Starter',
      'monthlyPrice': 9.99,
      'annualPrice': 99.99,
      'receiptLimit': 500,
      'features': [
        '500 receipts per month',
        'Advanced OCR processing',
        'Custom invoice templates',
        'WhatsApp integration',
        'Basic reporting',
        'Priority email support',
        'Data export (CSV)',
      ],
      'limitations': ['Limited integrations', 'Basic analytics'],
    },
    'professional': {
      'name': 'Professional',
      'monthlyPrice': 19.99,
      'annualPrice': 199.99,
      'receiptLimit': -1, // Unlimited
      'features': [
        'Unlimited receipts',
        'All integrations (WhatsApp, Telegram)',
        'Advanced reporting & analytics',
        'Custom categories',
        'Multi-currency support',
        'Automated expense categorization',
        'Data export (PDF, Excel)',
        'Phone support',
        'Team collaboration (up to 3 users)',
      ],
      'limitations': [],
    },
    'business': {
      'name': 'Business',
      'monthlyPrice': 39.99,
      'annualPrice': 399.99,
      'receiptLimit': -1, // Unlimited
      'features': [
        'Everything in Professional',
        'Unlimited team members',
        'Advanced approval workflows',
        'Custom integrations',
        'White-label options',
        'Dedicated account manager',
        'API access',
        'Priority phone support',
        'Advanced security features',
        'Custom training sessions',
      ],
      'limitations': [],
    },
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    // Load current subscription details from backend
    setState(() {
      // Load actual subscription data
      _currentPlan = 'free'; // Default for demo
    });
  }

  Future<void> _upgradePlan(String planId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Handle subscription upgrade through Stripe or other payment processor
      await _processPayment(planId);

      setState(() {
        _currentPlan = planId;
      });

      _showSuccessSnackBar(
        'Successfully upgraded to ${_plans[planId]!['name']} plan!',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to upgrade plan: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processPayment(String planId) async {
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, this would integrate with Stripe, RevenueCat, or other payment processor
    // Example Stripe integration:
    // final paymentIntent = await Stripe.instance.createPaymentMethod(...)
    // await Stripe.instance.confirmPayment(...)
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await _showCancelConfirmation();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Cancel subscription through payment processor
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _currentPlan = 'free';
      });

      _showSuccessSnackBar('Subscription cancelled successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to cancel subscription: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showCancelConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel your subscription?'),
            SizedBox(height: 16),
            Text('You will lose access to:'),
            Text('• Premium features'),
            Text('• Increased receipt limits'),
            Text('• Advanced reporting'),
            Text('• Priority support'),
            SizedBox(height: 16),
            Text(
              'Your subscription will remain active until the end of the current billing period.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatPrice(double price) {
    if (price == 0) return 'Free';
    return '\$${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPlanData = _plans[_currentPlan]!;

    return AppScaffold(
      title: 'Subscription',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Plan Status
            Card(
              color: theme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Current Plan',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentPlanData['name'],
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentPlan != 'free') ...[
                              Text(
                                _isAnnual
                                    ? '${_formatPrice(currentPlanData['annualPrice'])} / year'
                                    : '${_formatPrice(currentPlanData['monthlyPrice'])} / month',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Next billing: March 15, 2024',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (_currentPlan != 'free')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Usage Stats
                    if (currentPlanData['receiptLimit'] > 0) ...[
                      LinearProgressIndicator(
                        value: 0.3, // 30% used - replace with actual usage
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '15 / ${currentPlanData['receiptLimit']} receipts used this month',
                        style: theme.textTheme.bodySmall,
                      ),
                    ] else if (currentPlanData['receiptLimit'] == -1) ...[
                      Text(
                        '147 receipts processed this month',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Billing Period Toggle
            if (_currentPlan == 'free') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Monthly',
                    style: TextStyle(
                      fontWeight: _isAnnual
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color: _isAnnual ? Colors.grey : theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: _isAnnual,
                    onChanged: (value) {
                      setState(() {
                        _isAnnual = value;
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Text(
                        'Annual',
                        style: TextStyle(
                          fontWeight: _isAnnual
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _isAnnual ? theme.primaryColor : Colors.grey,
                        ),
                      ),
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
                        child: const Text(
                          'Save 20%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],

            // Plan Selection
            Text(
              'Choose Your Plan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the plan that best fits your needs. You can change or cancel anytime.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Plans Grid
            ...(_plans.entries.map((entry) {
              final planId = entry.key;
              final planData = entry.value;
              final isCurrentPlan = planId == _currentPlan;
              final isRecommended = planId == 'professional';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PlanSelector(
                  planId: planId,
                  name: planData['name'],
                  monthlyPrice: planData['monthlyPrice'],
                  annualPrice: planData['annualPrice'],
                  features: List<String>.from(planData['features']),
                  limitations: List<String>.from(planData['limitations']),
                  isCurrentPlan: isCurrentPlan,
                  isRecommended: isRecommended,
                  isAnnualBilling: _isAnnual,
                  isLoading: _isLoading,
                  onSelectPlan: () => _upgradePlan(planId),
                ),
              );
            })),

            const SizedBox(height: 24),

            // Payment Methods & Billing
            if (_currentPlan != 'free') ...[
              Text(
                'Billing & Payment',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.credit_card),
                      title: const Text('Payment Methods'),
                      subtitle: const Text('•••• •••• •••• 1234'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to payment methods
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: const Text('Billing History'),
                      subtitle: const Text('View past invoices'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to billing history
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Billing Cycle'),
                      subtitle: Text(_isAnnual ? 'Annual' : 'Monthly'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Change billing cycle
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Cancel Subscription
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Cancel Subscription',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your subscription will remain active until the end of the current billing period.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        onPressed: _isLoading ? null : _cancelSubscription,
                        backgroundColor: Colors.red,
                        child: const Text(
                          'Cancel Subscription',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Support
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Need Help?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Have questions about our plans or need assistance with your subscription?',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Open help center
                            },
                            icon: const Icon(Icons.article),
                            label: const Text('Help Center'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Contact support
                            },
                            icon: const Icon(Icons.support_agent),
                            label: const Text('Contact Support'),
                          ),
                        ),
                      ],
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
