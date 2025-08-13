// lib/presentation/screens/invoice/widgets/invoice_pdf_viewer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/invoice/invoice_model.dart';

class InvoicePdfViewer extends StatefulWidget {
  final InvoiceModel invoice;
  final String? pdfUrl;
  final bool isLoading;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onPrint;

  const InvoicePdfViewer({
    super.key,
    required this.invoice,
    this.pdfUrl,
    this.isLoading = false,
    this.onDownload,
    this.onShare,
    this.onPrint,
  });

  @override
  State<InvoicePdfViewer> createState() => _InvoicePdfViewerState();
}

class _InvoicePdfViewerState extends State<InvoicePdfViewer> {
  bool _isFullscreen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _isFullscreen ? null : _buildAppBar(),
      body: Column(
        children: [
          if (!_isFullscreen) _buildToolbar(),
          Expanded(
            child: widget.isLoading
                ? _buildLoadingView()
                : widget.pdfUrl != null
                ? _buildPdfView()
                : _buildErrorView(),
          ),
        ],
      ),
      floatingActionButton: _isFullscreen ? _buildFloatingActions() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Invoice ${widget.invoice.invoiceNumber}'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      actions: [
        IconButton(
          onPressed: _toggleFullscreen,
          icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
          tooltip: _isFullscreen ? 'Exit fullscreen' : 'Fullscreen',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.print),
                  SizedBox(width: 8),
                  Text('Print'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'copy_link',
              child: Row(
                children: [
                  Icon(Icons.link),
                  SizedBox(width: 8),
                  Text('Copy Link'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Invoice info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.invoice.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Total: \$${widget.invoice.total.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),

          // Action buttons
          _buildActionButton(
            icon: Icons.download,
            label: 'Download',
            onPressed: widget.onDownload,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.share,
            label: 'Share',
            onPressed: widget.onShare,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.print,
            label: 'Print',
            onPressed: widget.onPrint,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            foregroundColor: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Generating PDF...'),
        ],
      ),
    );
  }

  Widget _buildPdfView() {
    // Note: In a real implementation, you would use a PDF viewer package
    // like flutter_pdfview, syncfusion_flutter_pdfviewer, or pdf_viewer_plugin
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // PDF viewer placeholder
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PDF Viewer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invoice ${widget.invoice.invoiceNumber}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openExternalPdf,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open in External App'),
                  ),
                ],
              ),
            ),
          ),

          // PDF controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPdfControl(
                  icon: Icons.zoom_out,
                  label: 'Zoom Out',
                  onPressed: () {},
                ),
                _buildPdfControl(
                  icon: Icons.zoom_in,
                  label: 'Zoom In',
                  onPressed: () {},
                ),
                _buildPdfControl(
                  icon: Icons.fit_screen,
                  label: 'Fit Screen',
                  onPressed: () {},
                ),
                _buildPdfControl(
                  icon: Icons.rotate_right,
                  label: 'Rotate',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfControl({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text(
            'Failed to load PDF',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to generate or load the PDF file',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Retry loading PDF
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'exit_fullscreen',
          onPressed: _toggleFullscreen,
          backgroundColor: Colors.black54,
          child: const Icon(Icons.fullscreen_exit, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'share',
          onPressed: widget.onShare,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.share, color: Colors.white),
        ),
      ],
    );
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'download':
        widget.onDownload?.call();
        break;
      case 'share':
        widget.onShare?.call();
        break;
      case 'print':
        widget.onPrint?.call();
        break;
      case 'copy_link':
        _copyLink();
        break;
    }
  }

  void _copyLink() {
    if (widget.pdfUrl != null) {
      Clipboard.setData(ClipboardData(text: widget.pdfUrl!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF link copied to clipboard')),
      );
    }
  }

  void _openExternalPdf() async {
    if (widget.pdfUrl != null) {
      final uri = Uri.parse(widget.pdfUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open PDF')));
        }
      }
    }
  }

  @override
  void dispose() {
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
    super.dispose();
  }
}

// Simplified PDF preview widget for inline display
class InvoicePdfPreview extends StatelessWidget {
  final InvoiceModel invoice;
  final String? pdfUrl;
  final bool isLoading;
  final VoidCallback? onTap;

  const InvoicePdfPreview({
    super.key,
    required this.invoice,
    this.pdfUrl,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Generating...'),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 48,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Invoice PDF',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            invoice.invoiceNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
