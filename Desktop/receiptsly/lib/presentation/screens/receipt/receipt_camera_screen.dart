// lib/presentation/screens/receipt/receipt_camera_screen.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/permission_handler.dart';
import '../../../domain/entities/receipt_entity.dart';
import '../../providers/receipt_provider.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/app_snackbar.dart';
import 'widgets/camera_overlay.dart';

class ReceiptCameraScreen extends ConsumerStatefulWidget {
  const ReceiptCameraScreen({super.key});

  @override
  ConsumerState<ReceiptCameraScreen> createState() =>
      _ReceiptCameraScreenState();
}

class _ReceiptCameraScreenState extends ConsumerState<ReceiptCameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isFlashOn = false;
  bool _isRearCamera = true;
  double _zoomLevel = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;

  late AnimationController _flashAnimationController;
  late AnimationController _captureAnimationController;
  late Animation<double> _flashAnimation;
  late Animation<double> _captureAnimation;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _flashAnimationController.dispose();
    _captureAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _setupAnimations() {
    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _captureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _flashAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _flashAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _captureAnimation = Tween<double>(begin: 1, end: 0.8).animate(
      CurvedAnimation(
        parent: _captureAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      // Check camera permission
      final hasPermission =
          await AppPermissionHandler.requestCameraPermission();
      if (!hasPermission) {
        _showPermissionDeniedDialog();
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showNoCameraDialog();
        return;
      }

      // Initialize camera controller
      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Get zoom levels
      _maxZoom = await _cameraController!.getMaxZoomLevel();
      _minZoom = await _cameraController!.getMinZoomLevel();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      _showErrorDialog('Failed to initialize camera: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isCameraInitialized)
            _buildCameraPreview()
          else
            _buildLoadingState(),

          // Flash overlay
          AnimatedBuilder(
            animation: _flashAnimation,
            builder: (context, child) {
              return Container(
                color: Colors.white.withOpacity(_flashAnimation.value * 0.8),
              );
            },
          ),

          // Camera overlay
          const CameraOverlay(),

          // Top controls
          _buildTopControls(),

          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return GestureDetector(
      onScaleStart: (details) {
        // Store initial zoom for pinch-to-zoom
      },
      onScaleUpdate: (details) {
        final newZoom = (_zoomLevel * details.scale).clamp(_minZoom, _maxZoom);
        _cameraController?.setZoomLevel(newZoom);
      },
      onScaleEnd: (details) {
        // Finalize zoom level
      },
      onTapUp: (details) {
        _focusAndMeter(details.localPosition);
      },
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize!.height,
            height: _cameraController!.value.previewSize!.width,
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppLoader(color: Colors.white),
          SizedBox(height: 16),
          Text('Initializing camera...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.all(12),
              ),
            ),

            // Flash toggle
            if (_isCameraInitialized)
              IconButton(
                onPressed: _toggleFlash,
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 28,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.all(12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              IconButton(
                onPressed: _pickFromGallery,
                icon: const Icon(
                  Icons.photo_library,
                  color: Colors.white,
                  size: 32,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.all(16),
                ),
              ),

              // Capture button
              AnimatedBuilder(
                animation: _captureAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _captureAnimation.value,
                    child: GestureDetector(
                      onTap: _isCapturing ? null : _capturePhoto,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 4,
                          ),
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: AppColors.primary,
                                size: 32,
                              ),
                      ),
                    ),
                  );
                },
              ),

              // Camera switch button
              if (_cameras.length > 1)
                IconButton(
                  onPressed: _switchCamera,
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 32,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      // Trigger capture animation
      _captureAnimationController.forward().then((_) {
        _captureAnimationController.reverse();
      });

      // Trigger flash animation
      _flashAnimationController.forward().then((_) {
        _flashAnimationController.reverse();
      });

      // Add haptic feedback
      HapticFeedback.lightImpact();

      final image = await _cameraController!.takePicture();
      await _processImage(File(image.path));
    } catch (e) {
      AppSnackbar.showError(
        context,
        'Failed to capture photo: ${e.toString()}',
      );
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      AppSnackbar.showError(context, 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLoader(),
              SizedBox(height: 16),
              Text('Processing receipt...'),
            ],
          ),
        ),
      );

      // Process receipt with OCR
      final result = await ref
          .read(receiptProviderProvider.notifier)
          .processReceiptImage(imageFile);

      // Close processing dialog
      if (mounted) Navigator.of(context).pop();

      if (result.success && result.receipt != null) {
        // Navigate to edit screen with processed data
        if (mounted) {
          context.pushReplacement(
            '/receipts/${result.receipt!.id}/edit',
            extra: {'isNew': true},
          );
        }
      } else {
        AppSnackbar.showError(
          context,
          result.error ?? 'Failed to process receipt',
        );
      }
    } catch (e) {
      // Close processing dialog
      if (mounted) Navigator.of(context).pop();
      AppSnackbar.showError(context, 'Error processing image: ${e.toString()}');
    }
  }

  Future<void> _toggleFlash() async {
    if (!_isCameraInitialized) return;

    try {
      setState(() => _isFlashOn = !_isFlashOn);
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      AppSnackbar.showError(context, 'Failed to toggle flash');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;

    try {
      setState(() => _isCameraInitialized = false);

      final newCamera = _cameras.firstWhere(
        (camera) =>
            camera.lensDirection !=
            (_isRearCamera
                ? CameraLensDirection.back
                : CameraLensDirection.front),
        orElse: () => _cameras.first,
      );

      await _cameraController?.dispose();
      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      setState(() {
        _isRearCamera = !_isRearCamera;
        _isCameraInitialized = true;
        _isFlashOn = false; // Reset flash when switching cameras
      });
    } catch (e) {
      AppSnackbar.showError(context, 'Failed to switch camera');
    }
  }

  Future<void> _focusAndMeter(Offset position) async {
    if (!_isCameraInitialized) return;

    try {
      final double x = position.dx / MediaQuery.of(context).size.width;
      final double y = position.dy / MediaQuery.of(context).size.height;

      await _cameraController!.setFocusPoint(Offset(x, y));
      await _cameraController!.setExposurePoint(Offset(x, y));
    } catch (e) {
      // Focus failed - not critical, continue silently
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Please grant camera permission to capture receipts. '
          'You can enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showNoCameraDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Camera Available'),
        content: const Text('No camera found on this device.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
