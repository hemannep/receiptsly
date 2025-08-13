// lib/presentation/screens/receipt/receipt_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';

import '../../../domain/entities/receipt_entity.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/receipt_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_dialog.dart';

class ReceiptDetailScreen extends ConsumerStatefulWidget {
  final String receiptId;

  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  ConsumerState<ReceiptDetailScreen> createState() =>
      _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends ConsumerState<ReceiptDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isImageExpanded = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _pageController = PageController();
    _loadReceiptDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  void _loadReceiptDetails() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receiptDetailProvider(widget.receiptId).notifier).loadReceipt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(receiptDetailProvider(widget.receiptId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: receiptState.when(
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error.toString()),
        data: (receipt) => _buildReceiptDetails(receipt, theme),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLoader(),
            SizedBox(height: 16),
            Text('Loading receipt details...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Details')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load receipt',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadReceiptDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptDetails(ReceiptEntity receipt, ThemeData theme) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(receipt, theme),
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(receipt, theme),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(ReceiptEntity receipt, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildReceiptImage(receipt),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            receipt.vendor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, receipt),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy_outlined),
                  SizedBox(width: 8),
                  Text('Duplicate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share_outlined),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download_outlined),
                  SizedBox(width: 8),
                  Text('Export'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiptImage(ReceiptEntity receipt) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(receipt),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black54],
          ),
        ),
        child: receipt.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: receipt.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: AppLoader()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Image not available'),
                    ],
                  ),
                ),
              )
            : Container(
                color: Colors.grey[200],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No image available'),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildContent(ReceiptEntity receipt, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainInfo(receipt, theme),
          const SizedBox(height: 24),
          _buildDetailsSection(receipt, theme),
          const SizedBox(height: 24),
          if (receipt.items.isNotEmpty) ...[
            _buildItemsSection(receipt, theme),
            const SizedBox(height: 24),
          ],
          _buildMetadataSection(receipt, theme),
          const SizedBox(height: 32),
          _buildActionButtons(receipt, theme),
        ],
      ),
    );
  }

  Widget _buildMainInfo(ReceiptEntity receipt, ThemeData theme) {
    return Card(
      elevation: 0,
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(receipt.amount),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(receipt.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    receipt.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.calendar_today,
                    title: 'Date',
                    value: DateFormat('MMM dd, yyyy').format(receipt.date),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.category,
                    title: 'Category',
                    value: receipt.category.name,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(ReceiptEntity receipt, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Vendor', receipt.vendor, theme),
            if (receipt.description?.isNotEmpty == true)
              _buildDetailRow('Description', receipt.description!, theme),
            if (receipt.taxAmount > 0)
              _buildDetailRow(
                'Tax Amount',
                CurrencyFormatter.format(receipt.taxAmount),
                theme,
              ),
            if (receipt.tipAmount > 0)
              _buildDetailRow(
                'Tip Amount',
                CurrencyFormatter.format(receipt.tipAmount),
                theme,
              ),
            if (receipt.currency != 'USD')
              _buildDetailRow('Currency', receipt.currency, theme),
            if (receipt.paymentMethod?.isNotEmpty == true)
              _buildDetailRow('Payment Method', receipt.paymentMethod!, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(ReceiptEntity receipt, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Items (${receipt.items.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...receipt.items.map((item) => _buildItemRow(item, theme)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(ReceiptItem item, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(item.description, style: theme.textTheme.bodyMedium),
          ),
          if (item.quantity > 1) ...[
            Text(
              '${item.quantity}x',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            CurrencyFormatter.format(item.amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(ReceiptEntity receipt, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Metadata',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Created',
              DateFormat('MMM dd, yyyy • hh:mm a').format(receipt.createdAt),
              theme,
            ),
            if (receipt.updatedAt.isAfter(receipt.createdAt))
              _buildDetailRow(
                'Updated',
                DateFormat('MMM dd, yyyy • hh:mm a').format(receipt.updatedAt),
                theme,
              ),
            if (receipt.ocrConfidence > 0)
              _buildDetailRow(
                'OCR Confidence',
                '${(receipt.ocrConfidence * 100).toStringAsFixed(1)}%',
                theme,
              ),
            _buildDetailRow('Source', receipt.source, theme),
            if (receipt.syncStatus != SyncStatus.synced)
              _buildDetailRow(
                'Sync Status',
                receipt.syncStatus.displayName,
                theme,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ReceiptEntity receipt, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _editReceipt(receipt),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _shareReceipt(receipt),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
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

  void _handleMenuAction(String action, ReceiptEntity receipt) {
    switch (action) {
      case 'edit':
        _editReceipt(receipt);
        break;
      case 'duplicate':
        _duplicateReceipt(receipt);
        break;
      case 'share':
        _shareReceipt(receipt);
        break;
      case 'export':
        _exportReceipt(receipt);
        break;
      case 'delete':
        _deleteReceipt(receipt);
        break;
    }
  }

  void _editReceipt(ReceiptEntity receipt) {
    context.push('/receipts/${receipt.id}/edit');
  }

  void _duplicateReceipt(ReceiptEntity receipt) {
    ref.read(receiptProviderProvider.notifier).duplicateReceipt(receipt);
    AppSnackbar.showSuccess(context, 'Receipt duplicated successfully');
  }

  void _shareReceipt(ReceiptEntity receipt) {
    final text =
        '''
Receipt from ${receipt.vendor}
Amount: ${CurrencyFormatter.format(receipt.amount)}
Date: ${DateFormat('MMM dd, yyyy').format(receipt.date)}
Category: ${receipt.category.name}
''';

    Share.share(text, subject: 'Receipt from ${receipt.vendor}');
  }

  void _exportReceipt(ReceiptEntity receipt) {
    ref.read(receiptProviderProvider.notifier).exportReceipt(receipt.id);
    AppSnackbar.showInfo(context, 'Exporting receipt...');
  }

  void _deleteReceipt(ReceiptEntity receipt) {
    AppDialog.showConfirmation(
      context: context,
      title: 'Delete Receipt',
      message:
          'Are you sure you want to delete this receipt? This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
      onConfirm: () async {
        try {
          await ref
              .read(receiptProviderProvider.notifier)
              .deleteReceipt(receipt.id);
          if (mounted) {
            context.pop(); // Go back to list
            AppSnackbar.showSuccess(context, 'Receipt deleted successfully');
          }
        } catch (e) {
          AppSnackbar.showError(context, 'Failed to delete receipt');
        }
      },
    );
  }

  void _showFullScreenImage(ReceiptEntity receipt) {
    if (receipt.imageUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                onPressed: () => _shareImage(receipt.imageUrl!),
                icon: const Icon(Icons.share, color: Colors.white),
              ),
            ],
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(receipt.imageUrl!),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            heroAttributes: PhotoViewHeroAttributes(tag: receipt.id),
          ),
        ),
      ),
    );
  }

  void _shareImage(String imageUrl) {
    Share.share(imageUrl, subject: 'Receipt Image');
  }
}
