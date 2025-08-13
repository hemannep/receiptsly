// lib/presentation/screens/receipt/widgets/camera_overlay.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../../core/theme/app_colors.dart';

class CameraOverlay extends StatefulWidget {
  final String? instructionText;
  final bool showFocusIndicator;
  final Offset? focusPoint;

  const CameraOverlay({
    super.key,
    this.instructionText,
    this.showFocusIndicator = false,
    this.focusPoint,
  });

  @override
  State<CameraOverlay> createState() => _CameraOverlayState();
}

class _CameraOverlayState extends State<CameraOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  late AnimationController _focusAnimationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _focusAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _focusAnimationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    // Scanning line animation
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _scanAnimationController.repeat(reverse: true);

    // Focus indicator animation
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _focusAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(CameraOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showFocusIndicator && !oldWidget.showFocusIndicator) {
      _focusAnimationController.reset();
      _focusAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main overlay with cutout
        _buildOverlayWithCutout(),

        // Corner guides
        _buildCornerGuides(),

        // Scanning line
        _buildScanningLine(),

        // Instructions
        _buildInstructions(),

        // Focus indicator
        if (widget.showFocusIndicator && widget.focusPoint != null)
          _buildFocusIndicator(),
      ],
    );
  }

  Widget _buildOverlayWithCutout() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(painter: _OverlayPainter()),
    );
  }

  Widget _buildCornerGuides() {
    return Center(
      child: Container(
        width: 280,
        height: 200,
        child: Stack(
          children: [
            // Top-left corner
            Positioned(
              top: 0,
              left: 0,
              child: _buildCorner(
                topLeft: true,
                topRight: false,
                bottomLeft: false,
                bottomRight: false,
              ),
            ),
            // Top-right corner
            Positioned(
              top: 0,
              right: 0,
              child: _buildCorner(
                topLeft: false,
                topRight: true,
                bottomLeft: false,
                bottomRight: false,
              ),
            ),
            // Bottom-left corner
            Positioned(
              bottom: 0,
              left: 0,
              child: _buildCorner(
                topLeft: false,
                topRight: false,
                bottomLeft: true,
                bottomRight: false,
              ),
            ),
            // Bottom-right corner
            Positioned(
              bottom: 0,
              right: 0,
              child: _buildCorner(
                topLeft: false,
                topRight: false,
                bottomLeft: false,
                bottomRight: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({
    required bool topLeft,
    required bool topRight,
    required bool bottomLeft,
    required bool bottomRight,
  }) {
    return Container(
      width: 30,
      height: 30,
      child: CustomPaint(
        painter: _CornerPainter(
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }

  Widget _buildScanningLine() {
    return Center(
      child: Container(
        width: 280,
        height: 200,
        child: AnimatedBuilder(
          animation: _scanAnimation,
          builder: (context, child) {
            return CustomPaint(painter: _ScanLinePainter(_scanAnimation.value));
          },
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.center_focus_strong, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              widget.instructionText ?? 'Position receipt within the frame',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap to focus • Hold steady for best results',
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusIndicator() {
    return Positioned(
      left: widget.focusPoint!.dx - 30,
      top: widget.focusPoint!.dy - 30,
      child: AnimatedBuilder(
        animation: _focusAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _focusAnimation.value,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const cutoutWidth = 280.0;
    const cutoutHeight = 200.0;

    final cutoutRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: cutoutWidth,
      height: cutoutHeight,
    );

    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(cutoutRect, const Radius.circular(12)),
      );

    final overlayPath = Path.combine(
      PathOperation.difference,
      outerPath,
      cutoutPath,
    );
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  _CornerPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const cornerLength = 20.0;

    if (topLeft) {
      // Top line
      canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
      // Left line
      canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);
    }

    if (topRight) {
      // Top line
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width - cornerLength, 0),
        paint,
      );
      // Right line
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, cornerLength),
        paint,
      );
    }

    if (bottomLeft) {
      // Bottom line
      canvas.drawLine(
        Offset(0, size.height),
        Offset(cornerLength, size.height),
        paint,
      );
      // Left line
      canvas.drawLine(
        Offset(0, size.height),
        Offset(0, size.height - cornerLength),
        paint,
      );
    }

    if (bottomRight) {
      // Bottom line
      canvas.drawLine(
        Offset(size.width, size.height),
        Offset(size.width - cornerLength, size.height),
        paint,
      );
      // Right line
      canvas.drawLine(
        Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLength),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanLinePainter extends CustomPainter {
  final double progress;

  _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        AppColors.primary.withOpacity(0.3),
        AppColors.primary.withOpacity(0.8),
        AppColors.primary.withOpacity(0.3),
        Colors.transparent,
      ],
    );

    final lineY = size.height * progress;
    const lineHeight = 3.0;

    final rect = Rect.fromLTWH(
      0,
      lineY - lineHeight / 2,
      size.width,
      lineHeight,
    );
    final shader = gradient.createShader(rect);

    paint.shader = shader;
    canvas.drawRect(rect, paint);

    // Add glow effect
    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRect(Rect.fromLTWH(0, lineY - 4, size.width, 8), glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _ScanLinePainter || oldDelegate.progress != progress;
  }
}

/// Custom camera overlay for receipt scanning with advanced features
class AdvancedCameraOverlay extends StatefulWidget {
  final VoidCallback? onCapture;
  final VoidCallback? onFlashToggle;
  final VoidCallback? onGallery;
  final bool isFlashOn;
  final double? detectionConfidence;
  final String? detectedText;

  const AdvancedCameraOverlay({
    super.key,
    this.onCapture,
    this.onFlashToggle,
    this.onGallery,
    this.isFlashOn = false,
    this.detectionConfidence,
    this.detectedText,
  });

  @override
  State<AdvancedCameraOverlay> createState() => _AdvancedCameraOverlayState();
}

class _AdvancedCameraOverlayState extends State<AdvancedCameraOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base overlay
        const CameraOverlay(
          instructionText: 'Position receipt clearly within frame',
        ),

        // Detection feedback
        if (widget.detectionConfidence != null) _buildDetectionFeedback(),

        // Advanced controls overlay
        _buildControlsOverlay(),
      ],
    );
  }

  Widget _buildDetectionFeedback() {
    final confidence = widget.detectionConfidence!;
    final isGoodDetection = confidence > 0.7;

    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isGoodDetection ? AppColors.success : AppColors.warning)
              .withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isGoodDetection ? Icons.check_circle : Icons.warning,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isGoodDetection
                        ? 'Receipt detected!'
                        : 'Improve positioning',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (widget.detectedText?.isNotEmpty == true)
                    Text(
                      widget.detectedText!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '${(confidence * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          _buildControlButton(
            icon: Icons.photo_library,
            onTap: widget.onGallery,
          ),

          // Capture button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: GestureDetector(
                  onTap: widget.onCapture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.primary, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),

          // Flash button
          _buildControlButton(
            icon: widget.isFlashOn ? Icons.flash_on : Icons.flash_off,
            onTap: widget.onFlashToggle,
            isActive: widget.isFlashOn,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? AppColors.primary : Colors.white.withOpacity(0.2),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.9),
          size: 24,
        ),
      ),
    );
  }
}
