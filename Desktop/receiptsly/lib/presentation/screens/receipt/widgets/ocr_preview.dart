// lib/presentation/screens/receipt/widgets/ocr_preview.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import '../../../../domain/entities/receipt_entity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../widgets/common/app_loader.dart';
import '../../../widgets/common/app_button.dart';

class OCRPreview extends StatefulWidget {
  final File? imageFile;
  final String? imageUrl;
  final ReceiptData? ocrData;
  final double? confidence;
  final String? rawText;
  final bool isProcessing;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onEdit;
  final Function(ReceiptData)? onDataUpdated;

  const OCRPreview({
    super.key,
    this.imageFile,
    this.imageUrl,
    this.ocrData,
    this.confidence,
    this.rawText,
    this.isProcessing = false,
    this.onAccept,
    this.onReject,
    this.onEdit,
    this.onDataUpdated,
  });

  @override
  State<OCRPreview> createState() => _OCRPreviewState();
}

class _OCRPreviewState extends State<OCRPreview> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showRawText = false;
  bool _showConfidenceDetails = false;

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
      duration: const Duration(milliseconds: 600),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: _buildContent(theme),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(theme),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isProcessing)
                  _buildProcessingState(theme)
                else if (widget.ocrData != null) ...[
                  _buildImagePreview(theme),
                  const SizedBox(height: 16),
                  _buildConfidenceIndicator(theme),
                  const SizedBox(height: 16),
                  _buildExtractedData(theme),
                  const SizedBox(height: 16),
                  _buildRawTextSection(theme),
                ] else
                  _buildErrorState(theme),
              ],
            ),
          ),
        ),
        _buildActionButtons(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.psychology, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          Text(
            'OCR Results',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (widget.confidence != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getConfidenceColor(widget.confidence!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(widget.confidence! * 100).toInt()}% confidence',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _getConfidenceColor(widget.confidence!),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProcessingState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const AppLoader(),
          const SizedBox(height: 16),
          Text(
            'Processing receipt...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is extracting data from your receipt',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.imageFile != null
            ? Image.file(widget.imageFile!, fit: BoxFit.cover)
            : widget.imageUrl != null
            ? Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: AppLoader());
                },
              )
            : Container(
                color: theme.colorScheme.surfaceVariant,
                child: const Center(child: Icon(Icons.image, size: 48)),
              ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(ThemeData theme) {
    if (widget.confidence == null) return const SizedBox.shrink();

    final confidence = widget.confidence!;
    final color = _getConfidenceColor(confidence);
    final percentage = (confidence * 100).toInt();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detection Confidence',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(
                      () => _showConfidenceDetails = !_showConfidenceDetails,
                    );
                  },
                  child: Icon(
                    _showConfidenceDetails
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: confidence,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$percentage%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getConfidenceDescription(confidence),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (_showConfidenceDetails) ...[
              const SizedBox(height: 12),
              _buildConfidenceDetails(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Detection Quality Factors:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildQualityFactor('Image clarity', 0.85, theme),
        _buildQualityFactor('Text readability', 0.92, theme),
        _buildQualityFactor('Structure detection', 0.78, theme),
        _buildQualityFactor('Amount extraction', 0.95, theme),
      ],
    );
  }

  Widget _buildQualityFactor(String label, double score, ThemeData theme) {
    final color = _getConfidenceColor(score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(score * 100).toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedData(ThemeData theme) {
    if (widget.ocrData == null) return const SizedBox.shrink();

    final data = widget.ocrData!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.data_extraction, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Extracted Data',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDataRow('Vendor', data.vendor, Icons.store, theme),
            _buildDataRow(
              'Amount',
              CurrencyFormatter.format(data.amount),
              Icons.attach_money,
              theme,
              isEditable: true,
            ),
            _buildDataRow(
              'Date',
              DateFormat('MMM dd, yyyy').format(data.date),
              Icons.calendar_today,
              theme,
            ),
            _buildDataRow('Category', data.category, Icons.category, theme),
            if (data.taxAmount > 0)
              _buildDataRow(
                'Tax',
                CurrencyFormatter.format(data.taxAmount),
                Icons.receipt,
                theme,
              ),
            if (data.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildItemsList(data.items, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    bool isEditable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: isEditable
                    ? Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isEditable)
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<ReceiptItem> items, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Items (${items.length})',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: items
                .take(3)
                .map((item) => _buildItemRow(item, theme))
                .toList(),
          ),
        ),
        if (items.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${items.length - 3} more items',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemRow(ReceiptItem item, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.description,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawTextSection(ThemeData theme) {
    if (widget.rawText?.isEmpty ?? true) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.text_fields, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Raw OCR Text',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.rawText!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Text copied to clipboard'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy to clipboard',
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _showRawText = !_showRawText);
                      },
                      child: Icon(
                        _showRawText ? Icons.expand_less : Icons.expand_more,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_showRawText) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.rawText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'OCR Processing Failed',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to extract data from the image. Please try again with a clearer photo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          if (widget.onReject != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (widget.onEdit != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onEdit,
                child: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: AppButton(
              onPressed: widget.onAccept,
              child: const Text('Accept & Save'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return AppColors.success;
    } else if (confidence >= 0.6) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  String _getConfidenceDescription(double confidence) {
    if (confidence >= 0.8) {
      return 'High confidence - Data extraction looks accurate';
    } else if (confidence >= 0.6) {
      return 'Medium confidence - Please review extracted data';
    } else {
      return 'Low confidence - Manual review recommended';
    }
  }
}
