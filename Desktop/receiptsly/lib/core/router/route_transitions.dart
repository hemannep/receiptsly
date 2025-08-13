// lib/core/router/route_transitions.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Enumeration of available transition types
enum RouteTransitionType {
  fade,
  slide,
  slideFromLeft,
  slideFromRight,
  slideFromTop,
  slideFromBottom,
  scale,
  rotation,
  size,
  slideAndFade,
  scaleAndRotate,
  custom,
  none,
}

/// Route transitions utility class
class RouteTransitions {
  /// Default transition duration
  static const Duration defaultDuration = Duration(milliseconds: 300);

  /// Default curve
  static const Curve defaultCurve = Curves.easeInOut;

  /// Fade transition
  static Page<T> fadeIn<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Slide from right transition
  static Page<T> slideFromRight<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Slide from left transition
  static Page<T> slideFromLeft<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Slide from top transition
  static Page<T> slideFromTop<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Slide from bottom transition
  static Page<T> slideFromBottom<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Scale transition
  static Page<T> scale<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
    double beginScale = 0.0,
    double endScale = 1.0,
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: beginScale,
            end: endScale,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Rotation transition
  static Page<T> rotation<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
    double beginRotation = 0.0,
    double endRotation = 1.0,
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return RotationTransition(
          turns: Tween<double>(
            begin: beginRotation,
            end: endRotation,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Size transition
  static Page<T> size<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
    Axis axis = Axis.vertical,
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SizeTransition(
          sizeFactor: CurvedAnimation(parent: animation, curve: curve),
          axis: axis,
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Slide and fade transition
  static Page<T> slideAndFade<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
    Offset beginOffset = const Offset(1.0, 0.0),
    double beginOpacity = 0.0,
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: beginOpacity,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Scale and rotate transition
  static Page<T> scaleAndRotate<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
    double beginScale = 0.0,
    double beginRotation = 0.0,
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return ScaleTransition(
          scale: Tween<double>(
            begin: beginScale,
            end: 1.0,
          ).animate(curvedAnimation),
          child: RotationTransition(
            turns: Tween<double>(
              begin: beginRotation,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// iOS-style slide transition
  static Page<T> iOSSlide<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(-0.3, 0.0),
                ).animate(
                  CurvedAnimation(
                    parent: secondaryAnimation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Material Design slide transition
  static Page<T> materialSlide<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
              ),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Cupertino-style transition
  static Page<T> cupertinoTransition<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.linearToEaseOut,
                  reverseCurve: Curves.easeInToLinear,
                ),
              ),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Shared axis transition (Material Design)
  static Page<T> sharedAxisHorizontal<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = const Duration(milliseconds: 300),
    bool fillColor = true,
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.35, 1.0, curve: Curves.easeInOut),
          ),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.3, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(-0.3, 0.0),
                  ).animate(
                    CurvedAnimation(
                      parent: secondaryAnimation,
                      curve: Curves.easeInOut,
                    ),
                  ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                  CurvedAnimation(
                    parent: secondaryAnimation,
                    curve: const Interval(0.0, 0.65, curve: Curves.easeInOut),
                  ),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Shared axis vertical transition
  static Page<T> sharedAxisVertical<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.35, 1.0, curve: Curves.easeInOut),
          ),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          ),
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// No transition
  static Page<T> noTransition<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
  }) {
    return NoTransitionPage<T>(key: settings.pageKey, child: child);
  }

  /// Custom transition builder
  static Page<T> custom<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    required RouteTransitionsBuilder transitionsBuilder,
    Duration duration = defaultDuration,
    Duration? reverseTransitionDuration,
    bool opaque = true,
    bool barrierDismissible = false,
    Color? barrierColor,
    String? barrierLabel,
    bool maintainState = true,
  }) {
    return CustomTransitionPage<T>(
      key: settings.pageKey,
      child: child,
      transitionsBuilder: transitionsBuilder,
      transitionDuration: duration,
      reverseTransitionDuration: reverseTransitionDuration ?? duration,
      opaque: opaque,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      maintainState: maintainState,
    );
  }

  /// Get transition by type
  static Page<T> getTransitionByType<T extends Object?>({
    required RouteTransitionType type,
    required Widget child,
    required GoRouterState settings,
    Duration duration = defaultDuration,
    Curve curve = defaultCurve,
    Map<String, dynamic>? customParams,
  }) {
    switch (type) {
      case RouteTransitionType.fade:
        return fadeIn<T>(
          child: child,
          settings: settings,
          duration: duration,
          curve: curve,
        );
      case RouteTransitionType.slideFromRight:
        return slideFromRight<T>(
          child: child,
          settings: settings,
          duration: duration,
          curve: curve,
        );
      case RouteTransitionType.slideFromLeft:
        return slideFromLeft<T>(
          child: child,
          settings: settings,
          duration: duration,
          curve: curve,
        );
      case RouteTransitionType.slideFromTop:
        return slideFromTop<T>(
          child: child,
          settings: settings,
          duration: duration,
          curve: curve,
        );
      case RouteTransitionType.slideFromBottom:
        return slideFromBottom<T>(
          child: child,
          settings: settings,
          duration: duration,
          curve: curve,
        );
      case RouteTransitionType.scale:
        return scale<T>(
          child: child,
          settings: settings,
          duration: duration,
          curve: curve,
        );
      case RouteTransitionType.rotation:
        return rotation<T>(
          child: child,
          settings: settings,
          duration: duration,
          curve: curve,
        );
      case RouteTransitionType.size:
        return size<T>(
          child: child,
          settings: settings,
          duration: duration,
          curve: curve,
        );
      case RouteTransitionType.slideAndFade:
        return slideAndFade<T>(
          child: child,
          settings: settings,
          duration: duration,
          curve: curve,
        );
      case RouteTransitionType.scaleAndRotate:
        return scaleAndRotate<T>(
          child: child,
          settings: settings,
          duration: duration,
          curve: curve,
        );
      case RouteTransitionType.none:
        return noTransition<T>(child: child, settings: settings);
      case RouteTransitionType.slide:
      default:
        return materialSlide<T>(
          child: child,
          settings: settings,
          duration: duration,
        );
    }
  }
}

/// Custom transition page
class CustomTransitionPage<T> extends Page<T> {
  const CustomTransitionPage({
    required this.child,
    required this.transitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration,
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final RouteTransitionsBuilder transitionsBuilder;
  final Duration transitionDuration;
  final Duration? reverseTransitionDuration;
  final bool opaque;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool maintainState;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: transitionsBuilder,
      transitionDuration: transitionDuration,
      reverseTransitionDuration:
          reverseTransitionDuration ?? transitionDuration,
      opaque: opaque,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      maintainState: maintainState,
    );
  }
}

/// No transition page
class NoTransitionPage<T> extends Page<T> {
  const NoTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

/// Transition configuration class
class TransitionConfig {
  final RouteTransitionType type;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve curve;
  final Curve? reverseCurve;
  final Map<String, dynamic>? customParams;

  const TransitionConfig({
    this.type = RouteTransitionType.slide,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration,
    this.curve = Curves.easeInOut,
    this.reverseCurve,
    this.customParams,
  });

  static const TransitionConfig defaultConfig = TransitionConfig();

  static const TransitionConfig fastConfig = TransitionConfig(
    duration: Duration(milliseconds: 200),
  );

  static const TransitionConfig slowConfig = TransitionConfig(
    duration: Duration(milliseconds: 500),
  );

  static const TransitionConfig fadeConfig = TransitionConfig(
    type: RouteTransitionType.fade,
    duration: Duration(milliseconds: 250),
  );

  static const TransitionConfig slideConfig = TransitionConfig(
    type: RouteTransitionType.slideFromRight,
    duration: Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
  );

  static const TransitionConfig scaleConfig = TransitionConfig(
    type: RouteTransitionType.scale,
    duration: Duration(milliseconds: 400),
    curve: Curves.elasticOut,
  );

  TransitionConfig copyWith({
    RouteTransitionType? type,
    Duration? duration,
    Duration? reverseDuration,
    Curve? curve,
    Curve? reverseCurve,
    Map<String, dynamic>? customParams,
  }) {
    return TransitionConfig(
      type: type ?? this.type,
      duration: duration ?? this.duration,
      reverseDuration: reverseDuration ?? this.reverseDuration,
      curve: curve ?? this.curve,
      reverseCurve: reverseCurve ?? this.reverseCurve,
      customParams: customParams ?? this.customParams,
    );
  }
}

/// Transition manager for handling different transition configurations
class TransitionManager {
  static final Map<String, TransitionConfig> _routeConfigs = {};
  static TransitionConfig _defaultConfig = TransitionConfig.defaultConfig;

  /// Set default transition config
  static void setDefaultConfig(TransitionConfig config) {
    _defaultConfig = config;
  }

  /// Set transition config for specific route
  static void setRouteConfig(String routeName, TransitionConfig config) {
    _routeConfigs[routeName] = config;
  }

  /// Get transition config for route
  static TransitionConfig getConfigForRoute(String routeName) {
    return _routeConfigs[routeName] ?? _defaultConfig;
  }

  /// Remove route config
  static void removeRouteConfig(String routeName) {
    _routeConfigs.remove(routeName);
  }

  /// Clear all route configs
  static void clearRouteConfigs() {
    _routeConfigs.clear();
  }

  /// Get all route configs
  static Map<String, TransitionConfig> getAllConfigs() {
    return Map.unmodifiable(_routeConfigs);
  }

  /// Build page with configured transition
  static Page<T> buildPageWithConfig<T extends Object?>({
    required Widget child,
    required GoRouterState settings,
    String? routeName,
    TransitionConfig? overrideConfig,
  }) {
    final config =
        overrideConfig ??
        (routeName != null ? getConfigForRoute(routeName) : _defaultConfig);

    return RouteTransitions.getTransitionByType<T>(
      type: config.type,
      child: child,
      settings: settings,
      duration: config.duration,
      curve: config.curve,
      customParams: config.customParams,
    );
  }
}

/// Animation helper utilities
class AnimationHelpers {
  /// Create staggered animation for multiple widgets
  static List<Animation<double>> createStaggeredAnimations({
    required AnimationController controller,
    required int count,
    Duration delay = const Duration(milliseconds: 100),
    Curve curve = Curves.easeOut,
  }) {
    final animations = <Animation<double>>[];
    final intervalSize = 1.0 / count;

    for (int i = 0; i < count; i++) {
      final start = i * intervalSize;
      final end = start + intervalSize;

      animations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(start, end, curve: curve),
          ),
        ),
      );
    }

    return animations;
  }

  /// Create wave animation
  static Animation<double> createWaveAnimation({
    required AnimationController controller,
    double amplitude = 1.0,
    double frequency = 1.0,
  }) {
    return Tween<double>(begin: -amplitude, end: amplitude).animate(
      CurvedAnimation(
        parent: controller,
        curve: SineCurve(frequency: frequency),
      ),
    );
  }

  /// Create bounce animation
  static Animation<double> createBounceAnimation({
    required AnimationController controller,
    double bounciness = 2.0,
  }) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: ElasticOutCurve(bounciness)),
    );
  }
}

/// Custom curves
class SineCurve extends Curve {
  final double frequency;

  const SineCurve({this.frequency = 1.0});

  @override
  double transform(double t) {
    return 0.5 * (1 + math.sin(frequency * math.pi * t - math.pi / 2));
  }
}

class ElasticOutCurve extends Curve {
  final double bounciness;

  const ElasticOutCurve(this.bounciness);

  @override
  double transform(double t) {
    if (t == 0.0 || t == 1.0) return t;
    return math.pow(2, -10 * t) * math.sin((t - 0.1) * 5 * math.pi) + 1;
  }
}
