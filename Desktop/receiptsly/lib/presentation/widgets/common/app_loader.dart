// lib/presentation/widgets/common/app_loader.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Production-ready loading widget for Receiptsly app
/// Supports different loading types, sizes, and overlay functionality
class AppLoader extends StatefulWidget {
  const AppLoader({
    super.key,
    this.type = AppLoaderType.circular,
    this.size = AppLoaderSize.medium,
    this.color,
    this.strokeWidth,
    this.message,
    this.isOverlay = false,
    this.overlayColor,
    this.backgroundColor,
    this.semanticLabel,
    this.duration = const Duration(milliseconds: 1000),
  });

  /// Type of loading animation
  final AppLoaderType type;

  /// Size of the loader
  final AppLoaderSize size;

  /// Color of the loader
  final Color? color;

  /// Stroke width for circular loaders
  final double? strokeWidth;

  /// Optional message to display below loader
  final String? message;

  /// Whether to show as overlay
  final bool isOverlay;

  /// Overlay background color
  final Color? overlayColor;

  /// Background color for the loader container
  final Color? backgroundColor;

  /// Semantic label for accessibility
  final String? semanticLabel;

  /// Animation duration
  final Duration duration;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _controller.repeat();

    if (widget.type == AppLoaderType.pulse ||
        widget.type == AppLoaderType.breathe) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget loader = _buildLoader(theme);

    // Add semantic label for accessibility
    loader = Semantics(
      label: widget.semanticLabel ?? 'Loading',
      liveRegion: true,
      child: loader,
    );

    if (widget.isOverlay) {
      return _buildOverlay(theme, loader);
    }

    return loader;
  }

  /// Builds the main loader widget
  Widget _buildLoader(ThemeData theme) {
    final loaderColor = widget.color ?? theme.colorScheme.primary;
    final loaderSize = _getLoaderSize();

    Widget loader = SizedBox(
      width: loaderSize,
      height: loaderSize,
      child: _buildLoaderByType(theme, loaderColor, loaderSize),
    );

    // Add background if specified
    if (widget.backgroundColor != null) {
      loader = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: loader,
      );
    }

    // Add message if provided
    if (widget.message != null) {
      loader = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return loader;
  }

  /// Builds loader based on type
  Widget _buildLoaderByType(ThemeData theme, Color color, double size) {
    switch (widget.type) {
      case AppLoaderType.circular:
        return CircularProgressIndicator(
          strokeWidth: widget.strokeWidth ?? _getStrokeWidth(),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        );

      case AppLoaderType.linear:
        return LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(color),
          backgroundColor: color.withOpacity(0.2),
        );

      case AppLoaderType.dots:
        return _buildDotsLoader(color, size);

      case AppLoaderType.spinningDots:
        return _buildSpinningDotsLoader(color, size);

      case AppLoaderType.pulse:
        return _buildPulseLoader(color, size);

      case AppLoaderType.wave:
        return _buildWaveLoader(color, size);

      case AppLoaderType.breathe:
        return _buildBreatheLoader(color, size);

      case AppLoaderType.ripple:
        return _buildRippleLoader(color, size);

      case AppLoaderType.custom:
        return _buildCustomLoader(color, size);
    }
  }

  /// Builds dots loader
  Widget _buildDotsLoader(Color color, double size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            final delay = index * 0.15;
            final animationValue = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = math.sin(animationValue * math.pi) * 0.5 + 0.5;

            return Transform.scale(
              scale: 0.5 + scale * 0.5,
              child: Container(
                width: size * 0.2,
                height: size * 0.2,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.4 + scale * 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Builds spinning dots loader
  Widget _buildSpinningDotsLoader(Color color, double size) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(8, (index) {
              final angle = (index * 2 * math.pi) / 8;
              final radius = size * 0.3;
              final dotSize = size * 0.12;

              return Transform.translate(
                offset: Offset(
                  radius * math.cos(angle),
                  radius * math.sin(angle),
                ),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3 + (index / 8) * 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  /// Builds pulse loader
  Widget _buildPulseLoader(Color color, double size) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  /// Builds wave loader
  Widget _buildWaveLoader(Color color, double size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final delay = index * 0.1;
            final animationValue = (_controller.value - delay).clamp(0.0, 1.0);
            final height = math.sin(animationValue * 2 * math.pi) * 0.5 + 0.5;

            return Container(
              width: size * 0.12,
              height: size * 0.3 + height * size * 0.4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(size * 0.06),
              ),
            );
          }),
        );
      },
    );
  }

  /// Builds breathe loader
  Widget _buildBreatheLoader(Color color, double size) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.8)],
              stops: [0.0, _scaleAnimation.value],
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  /// Builds ripple loader
  Widget _buildRippleLoader(Color color, double size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final animationValue = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = animationValue;
            final opacity = 1.0 - animationValue;

            return Transform.scale(
              scale: scale,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: color.withOpacity(opacity * 0.6),
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Builds custom loader with logo or brand elements
  Widget _buildCustomLoader(Color color, double size) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: SweepGradient(
                colors: [color.withOpacity(0.1), color, color.withOpacity(0.1)],
                stops: const [0.0, 0.5, 1.0],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: size * 0.6,
                height: size * 0.6,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long, size: size * 0.3, color: color),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds overlay wrapper
  Widget _buildOverlay(ThemeData theme, Widget loader) {
    return Material(
      color: widget.overlayColor ?? theme.colorScheme.surface.withOpacity(0.8),
      child: Center(child: loader),
    );
  }

  /// Gets loader size based on size enum
  double _getLoaderSize() {
    switch (widget.size) {
      case AppLoaderSize.small:
        return 24.0;
      case AppLoaderSize.medium:
        return 40.0;
      case AppLoaderSize.large:
        return 64.0;
      case AppLoaderSize.extraLarge:
        return 80.0;
    }
  }

  /// Gets stroke width based on size
  double _getStrokeWidth() {
    switch (widget.size) {
      case AppLoaderSize.small:
        return 2.0;
      case AppLoaderSize.medium:
        return 3.0;
      case AppLoaderSize.large:
        return 4.0;
      case AppLoaderSize.extraLarge:
        return 5.0;
    }
  }
}

/// Loading animation types
enum AppLoaderType {
  circular, // Standard circular progress indicator
  linear, // Linear progress bar
  dots, // Bouncing dots
  spinningDots, // Spinning dots in circle
  pulse, // Pulsing circle
  wave, // Wave animation
  breathe, // Breathing gradient
  ripple, // Ripple effect
  custom, // Custom branded loader
}

/// Loader size variants
enum AppLoaderSize { small, medium, large, extraLarge }

/// Extension methods for easier loader creation
extension AppLoaderExtension on AppLoader {
  /// Creates a small circular loader
  static AppLoader circular({
    Key? key,
    AppLoaderSize size = AppLoaderSize.medium,
    Color? color,
    double? strokeWidth,
    String? message,
  }) {
    return AppLoader(
      key: key,
      type: AppLoaderType.circular,
      size: size,
      color: color,
      strokeWidth: strokeWidth,
      message: message,
    );
  }

  /// Creates a dots loader
  static AppLoader dots({
    Key? key,
    AppLoaderSize size = AppLoaderSize.medium,
    Color? color,
    String? message,
  }) {
    return AppLoader(
      key: key,
      type: AppLoaderType.dots,
      size: size,
      color: color,
      message: message,
    );
  }

  /// Creates an overlay loader
  static AppLoader overlay({
    Key? key,
    AppLoaderType type = AppLoaderType.circular,
    AppLoaderSize size = AppLoaderSize.large,
    Color? color,
    String? message,
    Color? overlayColor,
    Color? backgroundColor,
  }) {
    return AppLoader(
      key: key,
      type: type,
      size: size,
      color: color,
      message: message,
      isOverlay: true,
      overlayColor: overlayColor,
      backgroundColor: backgroundColor,
    );
  }

  /// Creates a custom branded loader
  static AppLoader branded({
    Key? key,
    AppLoaderSize size = AppLoaderSize.large,
    Color? color,
    String? message,
    bool isOverlay = false,
  }) {
    return AppLoader(
      key: key,
      type: AppLoaderType.custom,
      size: size,
      color: color,
      message: message,
      isOverlay: isOverlay,
    );
  }

  /// Creates a linear progress loader
  static AppLoader linear({Key? key, Color? color, String? message}) {
    return AppLoader(
      key: key,
      type: AppLoaderType.linear,
      size: AppLoaderSize.medium,
      color: color,
      message: message,
    );
  }
}

/// Helper widget for showing loading states in async operations
class AppLoadingBuilder extends StatelessWidget {
  const AppLoadingBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loader,
    this.errorBuilder,
    this.initialData,
  });

  /// Future to watch
  final Future<dynamic> future;

  /// Builder for success state
  final Widget Function(BuildContext, dynamic) builder;

  /// Custom loader widget
  final Widget? loader;

  /// Builder for error state
  final Widget Function(BuildContext, Object)? errorBuilder;

  /// Initial data
  final dynamic initialData;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: loader ?? const AppLoader());
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
        }

        return builder(context, snapshot.data);
      },
    );
  }
}
