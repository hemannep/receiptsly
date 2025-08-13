// lib/presentation/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receiptsly/core/constants/app_constants.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/core/utils/currency_utils.dart';
import 'package:receiptsly/presentation/providers/dashboard_provider.dart';
import 'package:receiptsly/presentation/providers/auth_provider.dart';
import 'package:receiptsly/presentation/widgets/common/app_loader.dart';
import 'package:receiptsly/presentation/widgets/common/app_snackbar.dart';
import 'package:receiptsly/presentation/widgets/layouts/app_scaffold.dart';
import 'widgets/metrics_card.dart';
import 'widgets/revenue_chart.dart';
import 'widgets/expense_breakdown.dart';
import 'widgets/recent_transactions.dart';
import 'widgets/quick_actions_grid.dart';
import 'tabs/overview_tab.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/notifications_tab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });

    // Load dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboardData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider);

    return AppScaffold(
      title: 'Dashboard',
      showBackButton: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotifications(context),
        ),
        IconButton(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              (user?.displayName?.isNotEmpty == true)
                  ? user!.displayName![0].toUpperCase()
                  : 'U',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          onPressed: () => _showProfileMenu(context),
        ),
      ],
      floatingActionButton: _buildFloatingActionButton(),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).refreshData();
        },
        child: dashboardState.when(
          data: (data) => _buildDashboardContent(data),
          loading: () => const Center(child: AppLoader()),
          error: (error, stackTrace) => _buildErrorState(error.toString()),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(DashboardData data) {
    return Column(
      children: [
        // Quick metrics summary
        Container(
          padding: const EdgeInsets.all(16),
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
                Text(
                  'Good ${_getGreeting()}, ${_getFirstName()}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getSubtitle(data),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickMetric(
                        'This Month',
                        CurrencyUtils.format(data.monthlyIncome),
                        Icons.trending_up,
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickMetric(
                        'Expenses',
                        CurrencyUtils.format(data.monthlyExpenses),
                        Icons.trending_down,
                        Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Analytics'),
              Tab(text: 'Activity'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              OverviewTab(data: data),
              AnalyticsTab(data: data),
              const NotificationsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickMetric(
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
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickActions(context),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Quick Add'),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(dashboardProvider.notifier).loadDashboardData();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  String _getFirstName() {
    final user = ref.read(currentUserProvider);
    final name = user?.displayName ?? 'User';
    return name.split(' ').first;
  }

  String _getSubtitle(DashboardData data) {
    if (data.pendingInvoices > 0) {
      return 'You have ${data.pendingInvoices} pending invoices';
    }
    if (data.recentReceipts > 0) {
      return 'You\'ve added ${data.recentReceipts} receipts this week';
    }
    return 'Keep up the great work!';
  }

  void _showNotifications(BuildContext context) {
    _tabController.animateTo(2);
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('App Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Capture Receipt',
                    Icons.camera_alt,
                    AppColors.primary,
                    () {
                      Navigator.pop(context);
                      // Navigate to camera
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'Create Invoice',
                    Icons.receipt_long,
                    AppColors.secondary,
                    () {
                      Navigator.pop(context);
                      // Navigate to invoice creation
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Add Client',
                    Icons.person_add,
                    AppColors.accent,
                    () {
                      Navigator.pop(context);
                      // Navigate to client creation
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'View Reports',
                    Icons.analytics,
                    AppColors.warning,
                    () {
                      Navigator.pop(context);
                      // Navigate to reports
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
