// lib/presentation/screens/receipt/widgets/receipt_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../domain/entities/receipt_entity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../widgets/common/app_loader.dart';

class ReceiptCard extends StatefulWidget {
  final ReceiptEntity receipt;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool showImage;

  const ReceiptCard({
    super.key,
    required this.receipt,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.showImage = true,
  });

  @override
  State<ReceiptCard> createState() => _ReceiptCardState();
}

class _ReceiptCardState extends State<ReceiptCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: widget.isSelected ? 8.0 : _elevationAnimation.value,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: widget.isSelected
                  ? BorderSide(color: theme.colorScheme.primary, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _animationController.reverse(),
              onTapCancel: () => _animationController.reverse(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: _buildCardContent(theme),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showImage) ...[
          _buildReceiptImage(theme),
          const SizedBox(width: 16),
        ],
        Expanded(child: _buildReceiptInfo(theme)),
        const SizedBox(width: 8),
        _buildReceiptMeta(theme),
      ],
    );
  }

  Widget _buildReceiptImage(ThemeData theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceVariant,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.receipt.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: widget.receipt.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: const Center(
                    child: SizedBox(width: 20, height: 20, child: AppLoader()),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.broken_image,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              )
            : Container(
                color: theme.colorScheme.surfaceVariant,
                child: Icon(
                  Icons.receipt_long,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
      ),
    );
  }

  Widget _buildReceiptInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vendor name
        Text(
          widget.receipt.vendor,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Amount
        Text(
          CurrencyFormatter.format(widget.receipt.amount),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),

        // Date and category row
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(widget.receipt.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.category,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.receipt.category.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Description (if available)
        if (widget.receipt.description?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(
            widget.receipt.description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Tags row
        const SizedBox(height: 8),
        _buildTagsRow(theme),
      ],
    );
  }

  Widget _buildReceiptMeta(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Status badge
        _buildStatusBadge(theme),
        const SizedBox(height: 8),

        // Sync status
        _buildSyncIndicator(theme),

        // Time since creation
        const SizedBox(height: 12),
        Text(
          _getTimeSince(widget.receipt.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        // OCR confidence (if available)
        if (widget.receipt.ocrConfidence > 0) ...[
          const SizedBox(height: 4),
          _buildConfidenceIndicator(theme),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final status = widget.receipt.status;
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSyncIndicator(ThemeData theme) {
    final syncStatus = widget.receipt.syncStatus;
    IconData icon;
    Color color;

    switch (syncStatus) {
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        color = AppColors.success;
        break;
      case SyncStatus.pending:
        icon = Icons.cloud_queue;
        color = AppColors.warning;
        break;
      case SyncStatus.failed:
        icon = Icons.cloud_off;
        color = AppColors.error;
        break;
      case SyncStatus.syncing:
        icon = Icons.cloud_sync;
        color = AppColors.primary;
        break;
    }

    return Tooltip(
      message: 'Sync: ${syncStatus.displayName}',
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildConfidenceIndicator(ThemeData theme) {
    final confidence = widget.receipt.ocrConfidence;
    final percentage = (confidence * 100).round();

    Color color;
    if (percentage >= 80) {
      color = AppColors.success;
    } else if (percentage >= 60) {
      color = AppColors.warning;
    } else {
      color = AppColors.error;
    }

    return Tooltip(
      message: 'OCR Confidence: $percentage%',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '$percentage%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow(ThemeData theme) {
    final tags = <Widget>[];

    // Payment method tag
    if (widget.receipt.paymentMethod?.isNotEmpty == true) {
      tags.add(
        _buildTag(
          icon: Icons.payment,
          label: widget.receipt.paymentMethod!,
          theme: theme,
        ),
      );
    }

    // Currency tag (if not default)
    if (widget.receipt.currency != 'USD') {
      tags.add(
        _buildTag(
          icon: Icons.currency_exchange,
          label: widget.receipt.currency,
          theme: theme,
        ),
      );
    }

    // Tax tag (if has tax)
    if (widget.receipt.taxAmount > 0) {
      tags.add(
        _buildTag(
          icon: Icons.receipt,
          label: 'Tax: ${CurrencyFormatter.format(widget.receipt.taxAmount)}',
          theme: theme,
        ),
      );
    }

    // Items count tag
    if (widget.receipt.items.isNotEmpty) {
      tags.add(
        _buildTag(
          icon: Icons.list_alt,
          label:
              '${widget.receipt.items.length} item${widget.receipt.items.length == 1 ? '' : 's'}',
          theme: theme,
        ),
      );
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.take(2).toList(), // Show max 2 tags to avoid overflow
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReceiptStatus status) {
    switch (status) {
      case ReceiptStatus.processed:
        return AppColors.success;
      case ReceiptStatus.pendingReview:
        return AppColors.warning;
      case ReceiptStatus.rejected:
        return AppColors.error;
      case ReceiptStatus.draft:
        return AppColors.secondary;
    }
  }

  String _getTimeSince(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
