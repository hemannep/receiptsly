// lib/presentation/screens/dashboard/tabs/notifications_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receiptsly/core/theme/app_colors.dart';
import 'package:receiptsly/core/utils/currency_utils.dart';
import 'package:receiptsly/core/utils/date_utils.dart';
import 'package:receiptsly/data/models/notification/notification_model.dart';
import 'package:receiptsly/presentation/providers/notification_provider.dart';
import 'package:receiptsly/presentation/widgets/animations/slide_animation.dart';
import 'package:receiptsly/presentation/widgets/animations/fade_animation.dart';
import 'package:receiptsly/presentation/widgets/common/app_button.dart';

class NotificationsTab extends ConsumerStatefulWidget {
  const NotificationsTab({super.key});

  @override
  ConsumerState<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<NotificationsTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _filterTabController;
  NotificationFilter _selectedFilter = NotificationFilter.all;
  bool _showOnlyUnread = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _filterTabController = TabController(length: 4, vsync: this);

    _filterTabController.addListener(() {
      if (!_filterTabController.indexIsChanging) {
        setState(() {
          _selectedFilter =
              NotificationFilter.values[_filterTabController.index];
        });
      }
    });

    // Load notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  @override
  void dispose() {
    _filterTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationProvider.notifier).refreshNotifications();
        },
        child: Column(
          children: [
            _buildNotificationHeader(),
            _buildFilterSection(),
            Expanded(
              child: notificationState.when(
                data: (notifications) => _buildNotificationsList(notifications),
                loading: () => _buildLoadingState(),
                error: (error, stackTrace) =>
                    _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHeader() {
    final unreadCount = ref
        .watch(notificationProvider.notifier)
        .getUnreadCount();

    return Container(
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
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unreadCount > 0
                            ? '$unreadCount new notifications'
                            : 'You\'re all caught up!',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildHeaderActions(),
              ],
            ),
            const SizedBox(height: 20),
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _markAllAsRead,
          icon: Icon(Icons.done_all, color: AppColors.primary),
          tooltip: 'Mark all as read',
        ),
        IconButton(
          onPressed: _showNotificationSettings,
          icon: Icon(Icons.settings, color: AppColors.primary),
          tooltip: 'Notification settings',
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final stats = ref
        .watch(notificationProvider.notifier)
        .getNotificationStats();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pending',
            '${stats.pendingCount}',
            Icons.pending,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Alerts',
            '${stats.alertCount}',
            Icons.warning,
            AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Updates',
            '${stats.updateCount}',
            Icons.info,
            AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filter tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _filterTabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Alerts'),
                Tab(text: 'Updates'),
                Tab(text: 'System'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Additional filters
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Switch(
                      value: _showOnlyUnread,
                      onChanged: (value) {
                        setState(() => _showOnlyUnread = value);
                      },
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Show only unread',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _clearAllNotifications,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    final filteredNotifications = _filterNotifications(notifications);

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];

        return SlideAnimation(
          delay: Duration(milliseconds: index * 50),
          direction: SlideDirection.left,
          child: _buildNotificationItem(notification, index),
        );
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, int index) {
    return Dismissible(
      key: Key(notification.id),
      background: _buildSwipeBackground(isLeft: true),
      secondaryBackground: _buildSwipeBackground(isLeft: false),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _markAsRead(notification);
        } else {
          _deleteNotification(notification);
        }
      },
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : AppColors.primary.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.border.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              if (!notification.isRead)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification.type,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        _buildNotificationBadge(notification.type),
                        const Spacer(),
                        Text(
                          DateUtils.formatRelative(notification.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Action buttons for actionable notifications
                    if (notification.actions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildNotificationActions(notification),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({required bool isLeft}) {
    return Container(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isLeft ? AppColors.primary : AppColors.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isLeft ? Icons.mark_email_read : Icons.delete,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildNotificationBadge(NotificationType type) {
    final color = _getNotificationColor(type);
    final label = _getNotificationLabel(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildNotificationActions(NotificationModel notification) {
    return Row(
      children: notification.actions.map((action) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AppButton(
            text: action.label,
            onPressed: () => _handleNotificationAction(notification, action),
            variant: action.isPrimary
                ? AppButtonVariant.primary
                : AppButtonVariant.outline,
            size: AppButtonSize.small,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(12),
          ),
          height: 100,
        );
      },
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
            'Failed to load notifications',
            style: TextStyle(
              fontSize: 18,
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
          AppButton(
            text: 'Try Again',
            onPressed: () {
              ref.read(notificationProvider.notifier).refreshNotifications();
            },
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case NotificationFilter.all:
        title = _showOnlyUnread
            ? 'No unread notifications'
            : 'No notifications';
        subtitle = _showOnlyUnread
            ? 'You\'re all caught up!'
            : 'We\'ll notify you when something important happens';
        icon = Icons.notifications_none;
        break;
      case NotificationFilter.alerts:
        title = 'No alerts';
        subtitle = 'No urgent notifications at the moment';
        icon = Icons.warning_amber;
        break;
      case NotificationFilter.updates:
        title = 'No updates';
        subtitle = 'No recent updates to show';
        icon = Icons.info_outline;
        break;
      case NotificationFilter.system:
        title = 'No system notifications';
        subtitle = 'All systems running smoothly';
        icon = Icons.settings_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            if (_selectedFilter == NotificationFilter.all && !_showOnlyUnread)
              AppButton(
                text: 'Refresh',
                onPressed: () {
                  ref
                      .read(notificationProvider.notifier)
                      .refreshNotifications();
                },
                variant: AppButtonVariant.outline,
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
  ) {
    var filtered = notifications;

    // Filter by type
    if (_selectedFilter != NotificationFilter.all) {
      filtered = filtered.where((notification) {
        switch (_selectedFilter) {
          case NotificationFilter.alerts:
            return notification.type == NotificationType.alert ||
                notification.type == NotificationType.warning;
          case NotificationFilter.updates:
            return notification.type == NotificationType.info ||
                notification.type == NotificationType.success;
          case NotificationFilter.system:
            return notification.type == NotificationType.system;
          case NotificationFilter.all:
            return true;
        }
      }).toList();
    }

    // Filter by read status
    if (_showOnlyUnread) {
      filtered = filtered
          .where((notification) => !notification.isRead)
          .toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
      case NotificationType.warning:
        return AppColors.error;
      case NotificationType.info:
        return AppColors.primary;
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.system:
        return AppColors.textSecondary;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return Icons.warning;
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.system:
        return Icons.settings;
    }
  }

  String _getNotificationLabel(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return 'Alert';
      case NotificationType.warning:
        return 'Warning';
      case NotificationType.info:
        return 'Info';
      case NotificationType.success:
        return 'Success';
      case NotificationType.system:
        return 'System';
    }
  }

  // Event handlers
  void _markAllAsRead() async {
    await ref.read(notificationProvider.notifier).markAllAsRead();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All notifications marked as read'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _markAsRead(NotificationModel notification) async {
    await ref.read(notificationProvider.notifier).markAsRead(notification.id);
  }

  void _deleteNotification(NotificationModel notification) async {
    await ref
        .read(notificationProvider.notifier)
        .deleteNotification(notification.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification deleted'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Restore notification
              ref
                  .read(notificationProvider.notifier)
                  .restoreNotification(notification);
            },
          ),
        ),
      );
    }
  }

  void _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(notificationProvider.notifier).clearAllNotifications();
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read if not already read
    if (!notification.isRead) {
      _markAsRead(notification);
    }

    // Navigate based on notification data
    if (notification.data != null) {
      final data = notification.data!;

      switch (data['type']) {
        case 'receipt':
          Navigator.of(context).pushNamed('/receipts/${data['id']}');
          break;
        case 'invoice':
          Navigator.of(context).pushNamed('/invoices/${data['id']}');
          break;
        case 'client':
          Navigator.of(context).pushNamed('/clients/${data['id']}');
          break;
        case 'payment':
          Navigator.of(context).pushNamed('/payments/${data['id']}');
          break;
        default:
          _showNotificationDetails(notification);
      }
    } else {
      _showNotificationDetails(notification);
    }
  }

  void _handleNotificationAction(
    NotificationModel notification,
    NotificationAction action,
  ) {
    switch (action.type) {
      case NotificationActionType.navigate:
        Navigator.of(context).pushNamed(action.data['route']);
        break;
      case NotificationActionType.approve:
        _approveAction(notification, action);
        break;
      case NotificationActionType.dismiss:
        _dismissAction(notification, action);
        break;
      case NotificationActionType.retry:
        _retryAction(notification, action);
        break;
    }
  }

  void _approveAction(
    NotificationModel notification,
    NotificationAction action,
  ) async {
    // Handle approval action
    await ref
        .read(notificationProvider.notifier)
        .processNotificationAction(notification.id, action.type, action.data);
  }

  void _dismissAction(
    NotificationModel notification,
    NotificationAction action,
  ) async {
    await _deleteNotification(notification);
  }

  void _retryAction(
    NotificationModel notification,
    NotificationAction action,
  ) async {
    // Handle retry action
    await ref
        .read(notificationProvider.notifier)
        .processNotificationAction(notification.id, action.type, action.data);
  }

  void _showNotificationDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationDetailsSheet(notification),
    );
  }

  Widget _buildNotificationDetailsSheet(NotificationModel notification) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(
                      notification.type,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (notification.data != null) ...[
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notification.data.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateUtils.formatFull(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Actions
                  if (notification.actions.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: notification.actions.map((action) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AppButton(
                              text: action.label,
                              onPressed: () {
                                Navigator.of(context).pop();
                                _handleNotificationAction(notification, action);
                              },
                              variant: action.isPrimary
                                  ? AppButtonVariant.primary
                                  : AppButtonVariant.outline,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    Navigator.of(context).pushNamed('/settings/notifications');
  }
}

// Enums and models
enum NotificationFilter { all, alerts, updates, system }

enum NotificationType { alert, warning, info, success, system }

enum NotificationActionType { navigate, approve, dismiss, retry }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final List<NotificationAction> actions;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
    this.actions = const [],
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    List<NotificationAction>? actions,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      actions: actions ?? this.actions,
    );
  }
}

class NotificationAction {
  final String label;
  final NotificationActionType type;
  final Map<String, dynamic> data;
  final bool isPrimary;

  const NotificationAction({
    required this.label,
    required this.type,
    this.data = const {},
    this.isPrimary = false,
  });
}

class NotificationStats {
  final int totalCount;
  final int unreadCount;
  final int pendingCount;
  final int alertCount;
  final int updateCount;

  const NotificationStats({
    required this.totalCount,
    required this.unreadCount,
    required this.pendingCount,
    required this.alertCount,
    required this.updateCount,
  });
}
