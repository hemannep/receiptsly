// lib/presentation/screens/receipt/bulk_upload_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/permission_handler.dart';
import '../../providers/receipt_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_button.dart';

class BulkUploadScreen extends ConsumerStatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  ConsumerState<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends ConsumerState<BulkUploadScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<File> _selectedFiles = [];
  List<UploadProgress> _uploadProgress = [];
  bool _isUploading = false;
  bool _showUploadProgress = false;

  final ImagePicker _imagePicker = ImagePicker();

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _showUploadProgress
                  ? _buildUploadProgressView(theme)
                  : _buildSelectionView(theme),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(_showUploadProgress ? 'Uploading Receipts' : 'Bulk Upload'),
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      actions: [
        if (_selectedFiles.isNotEmpty && !_showUploadProgress)
          TextButton(
            onPressed: _clearSelection,
            child: const Text('Clear All'),
          ),
      ],
    );
  }

  Widget _buildSelectionView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructions(theme),
          const SizedBox(height: 24),
          _buildUploadOptions(theme),
          const SizedBox(height: 24),
          if (_selectedFiles.isNotEmpty) ...[
            _buildSelectedFiles(theme),
            const SizedBox(height: 100), // Space for bottom bar
          ] else
            _buildEmptyState(theme),
        ],
      ),
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Bulk Upload Instructions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Select multiple receipt images at once\n'
              '• Supported formats: JPG, PNG, PDF\n'
              '• Maximum file size: 10MB per file\n'
              '• AI will automatically extract data from each receipt\n'
              '• You can review and edit each receipt after processing',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Upload Method',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildUploadOptionCard(
                icon: Icons.camera_alt,
                title: 'Camera',
                subtitle: 'Take photos',
                onTap: _openCamera,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUploadOptionCard(
                icon: Icons.photo_library,
                title: 'Gallery',
                subtitle: 'Select images',
                onTap: _pickFromGallery,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildUploadOptionCard(
          icon: Icons.folder_outlined,
          title: 'Files',
          subtitle: 'Browse device files (including PDFs)',
          onTap: _pickFiles,
          theme: theme,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildUploadOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: fullWidth ? 24 : 20,
                ),
              ),
              if (fullWidth) const SizedBox(width: 16),
              if (fullWidth)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFiles(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Files (${_selectedFiles.length})',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _addMoreFiles,
              icon: const Icon(Icons.add),
              label: const Text('Add More'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedFiles.length,
          itemBuilder: (context, index) {
            final file = _selectedFiles[index];
            return _buildFileItem(file, index, theme);
          },
        ),
      ],
    );
  }

  Widget _buildFileItem(File file, int index, ThemeData theme) {
    final fileName = file.path.split('/').last;
    final fileSize = _formatFileSize(file.lengthSync());
    final isImage = _isImageFile(file);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
          child: isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.broken_image,
                        color: theme.colorScheme.primary,
                      );
                    },
                  ),
                )
              : Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary),
        ),
        title: Text(
          fileName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(fileSize),
        trailing: IconButton(
          onPressed: () => _removeFile(index),
          icon: const Icon(Icons.remove_circle_outline),
          color: theme.colorScheme.error,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No files selected',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose an upload method above to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgressView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallProgress(theme),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _uploadProgress.length,
              itemBuilder: (context, index) {
                final progress = _uploadProgress[index];
                return _buildProgressItem(progress, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgress(ThemeData theme) {
    final completedCount = _uploadProgress.where((p) => p.isCompleted).length;
    final totalCount = _uploadProgress.length;
    final overallProgress = totalCount > 0 ? completedCount / totalCount : 0.0;

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
                  'Upload Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completedCount / $totalCount',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: overallProgress,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(overallProgress * 100).toInt()}% complete',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(UploadProgress progress, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.fileName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusIcon(progress, theme),
              ],
            ),
            const SizedBox(height: 8),
            if (progress.isCompleted)
              Text(
                progress.error ?? 'Completed successfully',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: progress.error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              )
            else if (progress.isProcessing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress.progress,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress.status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              )
            else
              Text(
                'Waiting to process...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(UploadProgress progress, ThemeData theme) {
    if (progress.error != null) {
      return Icon(
        Icons.error_outline,
        color: theme.colorScheme.error,
        size: 20,
      );
    } else if (progress.isCompleted) {
      return Icon(
        Icons.check_circle_outline,
        color: theme.colorScheme.primary,
        size: 20,
      );
    } else if (progress.isProcessing) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      );
    } else {
      return Icon(
        Icons.schedule,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
        size: 20,
      );
    }
  }

  Widget _buildBottomBar(ThemeData theme) {
    if (_showUploadProgress) {
      final allCompleted = _uploadProgress.every((p) => p.isCompleted);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: AppButton(
            onPressed: allCompleted ? _finishUpload : null,
            child: Text(allCompleted ? 'View Receipts' : 'Processing...'),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: AppButton(
          onPressed: _selectedFiles.isNotEmpty && !_isUploading
              ? _startUpload
              : null,
          isLoading: _isUploading,
          child: Text(
            _selectedFiles.isEmpty
                ? 'Select files to upload'
                : 'Upload ${_selectedFiles.length} file${_selectedFiles.length == 1 ? '' : 's'}',
          ),
        ),
      ),
    );
  }

  Future<void> _openCamera() async {
    final hasPermission = await AppPermissionHandler.requestCameraPermission();
    if (!hasPermission) {
      AppSnackbar.showError(context, 'Camera permission is required');
      return;
    }

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      AppSnackbar.showError(context, 'Failed to capture images');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      AppSnackbar.showError(context, 'Failed to pick images');
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.files.map((file) => File(file.path!)));
        });
      }
    } catch (e) {
      AppSnackbar.showError(context, 'Failed to pick files');
    }
  }

  void _addMoreFiles() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photos'),
              onTap: () {
                Navigator.pop(context);
                _openCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Browse Files'),
              onTap: () {
                Navigator.pop(context);
                _pickFiles();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedFiles.clear();
    });
  }

  Future<void> _startUpload() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
      _showUploadProgress = true;
      _uploadProgress = _selectedFiles.map((file) {
        return UploadProgress(fileName: file.path.split('/').last, file: file);
      }).toList();
    });

    try {
      await ref
          .read(receiptProviderProvider.notifier)
          .bulkUploadReceipts(
            _selectedFiles,
            onProgress: (fileName, progress, status, error) {
              setState(() {
                final index = _uploadProgress.indexWhere(
                  (p) => p.fileName == fileName,
                );
                if (index != -1) {
                  _uploadProgress[index] = _uploadProgress[index].copyWith(
                    progress: progress,
                    status: status,
                    error: error,
                    isProcessing: progress < 1.0 && error == null,
                    isCompleted: progress >= 1.0 || error != null,
                  );
                }
              });
            },
          );
    } catch (e) {
      AppSnackbar.showError(context, 'Upload failed: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _finishUpload() {
    context.pop();
    AppSnackbar.showSuccess(context, 'Bulk upload completed successfully');
  }

  bool _isImageFile(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

class UploadProgress {
  final String fileName;
  final File file;
  final double progress;
  final String status;
  final String? error;
  final bool isProcessing;
  final bool isCompleted;

  UploadProgress({
    required this.fileName,
    required this.file,
    this.progress = 0.0,
    this.status = 'Waiting...',
    this.error,
    this.isProcessing = false,
    this.isCompleted = false,
  });

  UploadProgress copyWith({
    String? fileName,
    File? file,
    double? progress,
    String? status,
    String? error,
    bool? isProcessing,
    bool? isCompleted,
  }) {
    return UploadProgress(
      fileName: fileName ?? this.fileName,
      file: file ?? this.file,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error ?? this.error,
      isProcessing: isProcessing ?? this.isProcessing,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
