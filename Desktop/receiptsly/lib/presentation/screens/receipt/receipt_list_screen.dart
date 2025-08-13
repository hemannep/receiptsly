// lib/presentation/screens/receipt/receipt_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shimmer/shimmer.dart';

import '../../../domain/entities/receipt_entity.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/receipt_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/app_snackbar.dart';
import 'widgets/receipt_card.dart';
import 'widgets/receipt_filters.dart';

class ReceiptListScreen extends ConsumerStatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  ConsumerState<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends ConsumerState<ReceiptListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  bool _isSearchMode = false;
  bool _isFilterVisible = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();
    _loadInitialData();
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final receiptState = ref.read(receiptListProvider);
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          receiptState.hasMore &&
          !receiptState.isLoadingMore) {
        ref.read(receiptListProvider.notifier).loadMore();
      }
    });
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receiptListProvider.notifier).loadReceipts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(receiptListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme),
      body: Column(
        children: [
          if (_isFilterVisible) const ReceiptFilters(),
          Expanded(child: _buildBody(context, receiptState)),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      title: _isSearchMode
          ? _buildSearchField(theme)
          : Text(
              'Receipts',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
      actions: [
        if (!_isSearchMode) ...[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _isSearchMode = true),
          ),
          IconButton(
            icon: Icon(
              _isFilterVisible ? Icons.filter_list : Icons.filter_list_outlined,
            ),
            onPressed: () =>
                setState(() => _isFilterVisible = !_isFilterVisible),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bulk_upload',
                child: Row(
                  children: [
                    Icon(Icons.cloud_upload_outlined),
                    SizedBox(width: 8),
                    Text('Bulk Upload'),
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
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ] else
          IconButton(icon: const Icon(Icons.close), onPressed: _exitSearchMode),
      ],
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search receipts...',
        border: InputBorder.none,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      style: theme.textTheme.bodyLarge,
      onChanged: (query) {
        ref.read(receiptListProvider.notifier).searchReceipts(query);
      },
      onSubmitted: (_) => _exitSearchMode(),
    );
  }

  Widget _buildBody(BuildContext context, ReceiptListState state) {
    if (state.isLoading && state.receipts.isEmpty) {
      return _buildShimmerLoading();
    }

    if (state.error != null && state.receipts.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.receipts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(receiptListProvider.notifier).refreshReceipts();
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildReceiptStats(state),
          _buildReceiptList(state),
          if (state.isLoadingMore) _buildLoadingMore(),
        ],
      ),
    );
  }

  Widget _buildReceiptStats(ReceiptListState state) {
    final theme = Theme.of(context);
    final totalAmount = state.receipts.fold<double>(
      0,
      (sum, receipt) => sum + receipt.amount,
    );

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Expenses',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(totalAmount),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.receipts.length}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptList(ReceiptListState state) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final receipt = state.receipts[index];
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            index == 0 ? 0 : 8,
            16,
            index == state.receipts.length - 1 ? 16 : 8,
          ),
          child: _buildReceiptItem(receipt),
        );
      }, childCount: state.receipts.length),
    );
  }

  Widget _buildReceiptItem(ReceiptEntity receipt) {
    return Slidable(
      key: ValueKey(receipt.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _editReceipt(receipt),
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) => _deleteReceipt(receipt),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ReceiptCard(
        receipt: receipt,
        onTap: () => _viewReceiptDetails(receipt),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingMore() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: AppLoader()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No receipts found',
      message: _isSearchMode
          ? 'Try adjusting your search terms'
          : 'Start by capturing your first receipt',
      actionLabel: _isSearchMode ? null : 'Capture Receipt',
      onActionPressed: _isSearchMode ? null : _captureReceipt,
    );
  }

  Widget _buildErrorState(String error) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      message: error,
      actionLabel: 'Retry',
      onActionPressed: () {
        ref.read(receiptListProvider.notifier).loadReceipts();
      },
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isSearchMode || _isFilterVisible) ...[
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton.small(
              heroTag: 'bulk_upload',
              onPressed: _navigateToBulkUpload,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.cloud_upload_outlined),
            ),
          ),
          const SizedBox(height: 8),
        ],
        ScaleTransition(
          scale: _fabAnimation,
          child: FloatingActionButton(
            heroTag: 'capture',
            onPressed: _captureReceipt,
            child: const Icon(Icons.add_a_photo),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'bulk_upload':
        _navigateToBulkUpload();
        break;
      case 'export':
        _exportReceipts();
        break;
      case 'settings':
        _navigateToSettings();
        break;
    }
  }

  void _exitSearchMode() {
    setState(() {
      _isSearchMode = false;
      _searchController.clear();
    });
    ref.read(receiptListProvider.notifier).clearSearch();
  }

  void _captureReceipt() {
    context.push('/receipts/capture');
  }

  void _viewReceiptDetails(ReceiptEntity receipt) {
    context.push('/receipts/${receipt.id}');
  }

  void _editReceipt(ReceiptEntity receipt) {
    context.push('/receipts/${receipt.id}/edit');
  }

  void _deleteReceipt(ReceiptEntity receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: Text(
          'Are you sure you want to delete the receipt from ${receipt.vendor}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(receiptListProvider.notifier).deleteReceipt(receipt.id);
              AppSnackbar.showSuccess(context, 'Receipt deleted successfully');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToBulkUpload() {
    context.push('/receipts/bulk-upload');
  }

  void _exportReceipts() {
    ref.read(receiptListProvider.notifier).exportReceipts();
    AppSnackbar.showInfo(context, 'Exporting receipts...');
  }

  void _navigateToSettings() {
    context.push('/settings');
  }
}
