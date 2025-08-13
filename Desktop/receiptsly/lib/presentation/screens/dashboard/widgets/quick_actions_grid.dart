// lib/presentation/screens/dashboard/widgets/quick_actions_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/presentation/widgets/animations/scale_animation.dart';
import 'package:receiptsly/presentation/providers/auth_provider.dart';

class QuickActionsGrid extends ConsumerStatefulWidget {
  final Function(QuickAction)? onActionTap;
  final bool showAllActions;
  final List<QuickAction>? customActions;

  const QuickActionsGrid({
    super.key,
    this.onActionTap,
    this.showAllActions = false,
    this.customActions,
  });

  @override
  ConsumerState<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends ConsumerState<QuickActionsGrid> {
  late List<QuickAction> _actions;

  @override
  void initState() {
    super.initState();
    _initializeActions();
  }

  void _initializeActions() {
    if (widget.customActions != null) {
      _actions = widget.customActions!;
      return;
    }

    _actions = [
      QuickAction(
        id: 'capture_receipt',
        title: 'Capture Receipt',
        subtitle: 'Take a photo',
        icon: Icons.camera_alt,
        color: AppColors.primary,
        route: '/receipts/camera',
        requiresAuth: true,
      ),
      QuickAction(
        id: 'create_invoice',
        title: 'Create Invoice',
        subtitle: 'Bill a client',
        icon: Icons.receipt_long,
        color: AppColors.secondary,
        route: '/invoices/create',
        requiresAuth: true,
      ),
      QuickAction(
        id: 'add_client',
        title: 'Add Client',
        subtitle: 'New contact',
        icon: Icons.person_add,
        color: AppColors.accent,
        route: '/clients/add',
        requiresAuth: true,
      ),
      QuickAction(
        id: 'upload_bulk',
        title: 'Bulk Upload',
        subtitle: 'Multiple receipts',
        icon: Icons.cloud_upload,
        color: AppColors.warning,
        route: '/receipts/bulk-upload',
        requiresAuth: true,
      ),
      QuickAction(
        id: 'view_reports',
        title: 'View Reports',
        subtitle: 'Analytics',
        icon: Icons.analytics,
        color: AppColors.success,
        route: '/reports',
        requiresAuth: true,
      ),
      QuickAction(
        id: 'scan_document',
        title: 'Scan Document',
        subtitle: 'PDF scanner',
        icon: Icons.scanner,
        color: AppColors.error,
        route: '/scanner',
        requiresAuth: true,
      ),
      QuickAction(
        id: 'expense_tracker',
        title: 'Quick Expense',
        subtitle: 'Manual entry',
        icon: Icons.add_circle_outline,
        color: const Color(0xFF8E24AA),
        route: '/expenses/add',
        requiresAuth: true,
      ),
      QuickAction(
        id: 'payment_reminder',
        title: 'Send Reminder',
        subtitle: 'Invoice follow-up',
        icon: Icons.schedule_send,
        color: const Color(0xFF00ACC1),
        route: '/invoices/reminders',
        requiresAuth: true,
      ),
    ];

    if (!widget.showAllActions) {
      _actions = _actions.take(6).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAuthenticated = user != null;

    // Filter actions based on authentication
    final availableActions = _actions.where((action) {
      if (action.requiresAuth && !isAuthenticated) {
        return false;
      }
      return true;
    }).toList();

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
          _buildActionsGrid(availableActions),
          if (!widget.showAllActions && _actions.length > 6) ...[
            const SizedBox(height: 16),
            _buildShowMoreButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flash_on, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Quick',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsGrid(List<QuickAction> actions) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return ScaleAnimation(
          delay: Duration(milliseconds: index * 100),
          child: _buildActionCard(actions[index]),
        );
      },
    );
  }

  Widget _buildActionCard(QuickAction action) {
    return GestureDetector(
      onTap: () => _handleActionTap(action),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              action.color.withOpacity(0.1),
              action.color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: action.color.withOpacity(0.2), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),

              const Spacer(),

              // Text section
              Text(
                action.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              Text(
                action.subtitle,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Badge or indicator if needed
              if (action.badge != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: action.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    action.badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShowMoreButton() {
    return Center(
      child: GestureDetector(
        onTap: () => _showAllActions(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Show More Actions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.expand_more, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _handleActionTap(QuickAction action) {
    // Check authentication if required
    if (action.requiresAuth) {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        _showAuthRequiredDialog(action);
        return;
      }
    }

    // Handle the action
    widget.onActionTap?.call(action);

    // Navigate if route is provided
    if (action.route != null) {
      Navigator.of(context).pushNamed(action.route!);
    }
  }

  void _showAuthRequiredDialog(QuickAction action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: Text(
          'You need to sign in to use "${action.title}". Would you like to sign in now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/auth/login');
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _showAllActions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAllActionsSheet(),
    );
  }

  Widget _buildAllActionsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  'All Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Actions grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: _actions.length,
                itemBuilder: (context, index) {
                  return ScaleAnimation(
                    delay: Duration(milliseconds: index * 50),
                    child: _buildActionCard(_actions[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Specialized quick actions for different contexts
class ContextualQuickActions extends StatelessWidget {
  final QuickActionContext context;
  final Function(QuickAction)? onActionTap;

  const ContextualQuickActions({
    super.key,
    required this.context,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _getContextualActions();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getContextTitle(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildCompactActionCard(actions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionCard(QuickAction action) {
    return GestureDetector(
      onTap: () => onActionTap?.call(action),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: action.color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 28),
            const SizedBox(height: 8),
            Text(
              action.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<QuickAction> _getContextualActions() {
    switch (context) {
      case QuickActionContext.receipts:
        return [
          QuickAction(
            id: 'capture_receipt',
            title: 'Capture Receipt',
            subtitle: 'Take photo',
            icon: Icons.camera_alt,
            color: AppColors.primary,
          ),
          QuickAction(
            id: 'upload_receipt',
            title: 'Upload Receipt',
            subtitle: 'From gallery',
            icon: Icons.upload_file,
            color: AppColors.secondary,
          ),
          QuickAction(
            id: 'bulk_upload',
            title: 'Bulk Upload',
            subtitle: 'Multiple receipts',
            icon: Icons.cloud_upload,
            color: AppColors.warning,
          ),
        ];

      case QuickActionContext.invoices:
        return [
          QuickAction(
            id: 'create_invoice',
            title: 'New Invoice',
            subtitle: 'Create invoice',
            icon: Icons.receipt_long,
            color: AppColors.primary,
          ),
          QuickAction(
            id: 'send_reminder',
            title: 'Send Reminder',
            subtitle: 'Payment reminder',
            icon: Icons.schedule_send,
            color: AppColors.warning,
          ),
          QuickAction(
            id: 'track_payments',
            title: 'Track Payments',
            subtitle: 'Payment status',
            icon: Icons.payment,
            color: AppColors.success,
          ),
        ];

      case QuickActionContext.clients:
        return [
          QuickAction(
            id: 'add_client',
            title: 'Add Client',
            subtitle: 'New contact',
            icon: Icons.person_add,
            color: AppColors.primary,
          ),
          QuickAction(
            id: 'import_contacts',
            title: 'Import Contacts',
            subtitle: 'From phone',
            icon: Icons.contact_phone,
            color: AppColors.secondary,
          ),
          QuickAction(
            id: 'client_projects',
            title: 'View Projects',
            subtitle: 'Client projects',
            icon: Icons.folder_open,
            color: AppColors.accent,
          ),
        ];
    }
  }

  String _getContextTitle() {
    switch (context) {
      case QuickActionContext.receipts:
        return 'Receipt Actions';
      case QuickActionContext.invoices:
        return 'Invoice Actions';
      case QuickActionContext.clients:
        return 'Client Actions';
    }
  }
}

// Quick action model
class QuickAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? route;
  final String? badge;
  final bool requiresAuth;
  final VoidCallback? onTap;
  final Map<String, dynamic>? metadata;

  const QuickAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.route,
    this.badge,
    this.requiresAuth = false,
    this.onTap,
    this.metadata,
  });

  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      icon: IconData(
        json['iconCodePoint'] ?? Icons.help.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      color: Color(json['color'] ?? AppColors.primary.value),
      route: json['route'],
      badge: json['badge'],
      requiresAuth: json['requiresAuth'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'iconCodePoint': icon.codePoint,
      'color': color.value,
      'route': route,
      'badge': badge,
      'requiresAuth': requiresAuth,
      'metadata': metadata,
    };
  }

  QuickAction copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    Color? color,
    String? route,
    String? badge,
    bool? requiresAuth,
    VoidCallback? onTap,
    Map<String, dynamic>? metadata,
  }) {
    return QuickAction(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      route: route ?? this.route,
      badge: badge ?? this.badge,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      onTap: onTap ?? this.onTap,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum QuickActionContext { receipts, invoices, clients }

// Smart quick actions that adapt based on user behavior
class SmartQuickActions extends ConsumerStatefulWidget {
  final Function(QuickAction)? onActionTap;

  const SmartQuickActions({super.key, this.onActionTap});

  @override
  ConsumerState<SmartQuickActions> createState() => _SmartQuickActionsState();
}

class _SmartQuickActionsState extends ConsumerState<SmartQuickActions> {
  List<QuickAction> _smartActions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSmartActions();
  }

  Future<void> _loadSmartActions() async {
    setState(() => _isLoading = true);

    // Simulate loading smart actions based on user behavior
    await Future.delayed(const Duration(milliseconds: 500));

    final actions = await _generateSmartActions();

    setState(() {
      _smartActions = actions;
      _isLoading = false;
    });
  }

  Future<List<QuickAction>> _generateSmartActions() async {
    // This would normally analyze user behavior and suggest relevant actions
    // For now, we'll return some contextual suggestions

    final timeOfDay = DateTime.now().hour;
    final dayOfWeek = DateTime.now().weekday;

    List<QuickAction> actions = [];

    // Morning suggestions
    if (timeOfDay >= 6 && timeOfDay < 12) {
      actions.addAll([
        QuickAction(
          id: 'morning_receipt',
          title: 'Coffee Receipt',
          subtitle: 'Capture breakfast',
          icon: Icons.coffee,
          color: const Color(0xFF8D6E63),
          badge: 'Morning',
        ),
        QuickAction(
          id: 'daily_plan',
          title: 'Plan Day',
          subtitle: 'Review schedule',
          icon: Icons.today,
          color: AppColors.primary,
        ),
      ]);
    }
    // Afternoon suggestions
    else if (timeOfDay >= 12 && timeOfDay < 18) {
      actions.addAll([
        QuickAction(
          id: 'lunch_receipt',
          title: 'Lunch Receipt',
          subtitle: 'Business meal',
          icon: Icons.restaurant,
          color: const Color(0xFFFF7043),
          badge: 'Lunch',
        ),
        QuickAction(
          id: 'client_follow_up',
          title: 'Client Follow-up',
          subtitle: 'Send invoice',
          icon: Icons.send,
          color: AppColors.secondary,
        ),
      ]);
    }
    // Evening suggestions
    else {
      actions.addAll([
        QuickAction(
          id: 'daily_summary',
          title: 'Daily Summary',
          subtitle: 'Review expenses',
          icon: Icons.summarize,
          color: AppColors.accent,
          badge: 'Review',
        ),
        QuickAction(
          id: 'prepare_tomorrow',
          title: 'Tomorrow Prep',
          subtitle: 'Plan ahead',
          icon: Icons.schedule,
          color: const Color(0xFF7B1FA2),
        ),
      ]);
    }

    // Weekend suggestions
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      actions.add(
        QuickAction(
          id: 'weekend_expense',
          title: 'Weekend Expense',
          subtitle: 'Personal items',
          icon: Icons.weekend,
          color: const Color(0xFF00897B),
          badge: 'Weekend',
        ),
      );
    }

    // Add common actions
    actions.addAll([
      QuickAction(
        id: 'quick_expense',
        title: 'Quick Expense',
        subtitle: 'Manual entry',
        icon: Icons.add_circle_outline,
        color: AppColors.warning,
      ),
      QuickAction(
        id: 'scan_receipt',
        title: 'Scan Receipt',
        subtitle: 'From camera',
        icon: Icons.scanner,
        color: AppColors.error,
      ),
    ]);

    return actions.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.02),
            AppColors.secondary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSmartHeader(),
          const SizedBox(height: 20),
          if (_isLoading) _buildLoadingState() else _buildSmartActionsGrid(),
        ],
      ),
    );
  }

  Widget _buildSmartHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Suggestions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Personalized for you',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadSmartActions,
          icon: Icon(Icons.refresh, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildSmartActionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _smartActions.length,
      itemBuilder: (context, index) {
        return ScaleAnimation(
          delay: Duration(milliseconds: index * 100),
          child: _buildSmartActionCard(_smartActions[index]),
        );
      },
    );
  }

  Widget _buildSmartActionCard(QuickAction action) {
    return GestureDetector(
      onTap: () => widget.onActionTap?.call(action),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: action.color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: action.color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge
              if (action.badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: action.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    action.badge!,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action.icon, color: action.color, size: 20),
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                action.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 2),

              // Subtitle
              Text(
                action.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}
