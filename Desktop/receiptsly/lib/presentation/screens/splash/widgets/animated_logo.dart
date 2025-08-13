import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/theme/app_colors.dart';

class AnimatedLogo extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration animationDuration;

  const AnimatedLogo({
    super.key,
    this.size = 120,
    this.color,
    this.animationDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Rotation Animation
    _rotationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    // Pulse Animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _rotationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.5,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.3), Colors.transparent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Circle
                  Container(
                    width: widget.size * 0.8,
                    height: widget.size * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),

                  // Logo Icon
                  _buildLogoIcon(),

                  // Animated Border
                  _buildAnimatedBorder(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoIcon() {
    return Container(
      width: widget.size * 0.6,
      height: widget.size * 0.6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.asset(
          AssetPaths.logoIcon,
          width: widget.size * 0.4,
          height: widget.size * 0.4,
          colorFilter: ColorFilter.mode(
            widget.color ?? AppColors.primary,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBorder() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 6.28, // 2π for full rotation
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.transparent, width: 3),
            ),
            child: Stack(
              children: [
                // Animated Arc
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: AnimatedArcPainter(
                    progress: _rotationAnimation.value,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  AnimatedArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Draw animated arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // Start from top (-π/2)
      2 * 3.14159 * progress, // Sweep based on progress
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
