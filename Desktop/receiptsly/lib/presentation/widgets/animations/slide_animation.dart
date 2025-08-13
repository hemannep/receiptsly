import 'package:flutter/material.dart';

enum SlideDirection {
  left,
  right,
  up,
  down,
  leftUp,
  leftDown,
  rightUp,
  rightDown,
}

class SlideAnimation extends StatefulWidget {
  final Widget child;
  final SlideDirection direction;
  final Duration? duration;
  final Duration? delay;
  final Curve? curve;
  final AnimationController? controller;
  final bool autoStart;
  final VoidCallback? onComplete;
  final double? distance;

  const SlideAnimation({
    Key? key,
    required this.child,
    this.direction = SlideDirection.up,
    this.duration,
    this.delay,
    this.curve,
    this.controller,
    this.autoStart = true,
    this.onComplete,
    this.distance,
  }) : super(key: key);

  @override
  State<SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isControllerOwned = false;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = AnimationController(
        duration: widget.duration ?? const Duration(milliseconds: 400),
        vsync: this,
      );
      _isControllerOwned = true;
    }

    _setupAnimations();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });

    if (widget.autoStart && _isControllerOwned) {
      _startAnimation();
    }
  }

  void _setupAnimations() {
    final distance = widget.distance ?? 1.0;
    Offset beginOffset;

    switch (widget.direction) {
      case SlideDirection.left:
        beginOffset = Offset(-distance, 0.0);
        break;
      case SlideDirection.right:
        beginOffset = Offset(distance, 0.0);
        break;
      case SlideDirection.up:
        beginOffset = Offset(0.0, -distance);
        break;
      case SlideDirection.down:
        beginOffset = Offset(0.0, distance);
        break;
      case SlideDirection.leftUp:
        beginOffset = Offset(-distance, -distance);
        break;
      case SlideDirection.leftDown:
        beginOffset = Offset(-distance, distance);
        break;
      case SlideDirection.rightUp:
        beginOffset = Offset(distance, -distance);
        break;
      case SlideDirection.rightDown:
        beginOffset = Offset(distance, distance);
        break;
    }

    _slideAnimation = Tween<Offset>(begin: beginOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: widget.curve ?? Curves.easeOutCubic,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.8, curve: widget.curve ?? Curves.easeOutCubic),
      ),
    );
  }

  void _startAnimation() async {
    if (widget.delay != null) {
      await Future.delayed(widget.delay!);
    }
    if (mounted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    if (_isControllerOwned) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Slide Route for page transitions
class SlideRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final SlideDirection direction;
  final Duration? duration;
  final Curve? curve;

  SlideRoute({
    required this.child,
    this.direction = SlideDirection.right,
    this.duration,
    this.curve,
    RouteSettings? settings,
  }) : super(
         settings: settings,
         pageBuilder: (context, animation, secondaryAnimation) => child,
         transitionDuration: duration ?? const Duration(milliseconds: 300),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           Offset beginOffset;

           switch (direction) {
             case SlideDirection.left:
               beginOffset = const Offset(-1.0, 0.0);
               break;
             case SlideDirection.right:
               beginOffset = const Offset(1.0, 0.0);
               break;
             case SlideDirection.up:
               beginOffset = const Offset(0.0, -1.0);
               break;
             case SlideDirection.down:
               beginOffset = const Offset(0.0, 1.0);
               break;
             default:
               beginOffset = const Offset(1.0, 0.0);
           }

           return SlideTransition(
             position: Tween<Offset>(begin: beginOffset, end: Offset.zero)
                 .animate(
                   CurvedAnimation(
                     parent: animation,
                     curve: curve ?? Curves.easeInOut,
                   ),
                 ),
             child: child,
           );
         },
       );
}

// Slide In and Out Widget
class SlideInOut extends StatefulWidget {
  final Widget child;
  final bool show;
  final SlideDirection direction;
  final Duration? duration;
  final Curve? curve;
  final VoidCallback? onSlideIn;
  final VoidCallback? onSlideOut;

  const SlideInOut({
    Key? key,
    required this.child,
    required this.show,
    this.direction = SlideDirection.up,
    this.duration,
    this.curve,
    this.onSlideIn,
    this.onSlideOut,
  }) : super(key: key);

  @override
  State<SlideInOut> createState() => _SlideInOutState();
}

class _SlideInOutState extends State<SlideInOut>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 300),
      vsync: this,
    );

    _setupAnimation();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onSlideIn != null) {
        widget.onSlideIn!();
      } else if (status == AnimationStatus.dismissed &&
          widget.onSlideOut != null) {
        widget.onSlideOut!();
      }
    });

    if (widget.show) {
      _controller.forward();
    }
  }

  void _setupAnimation() {
    Offset beginOffset;

    switch (widget.direction) {
      case SlideDirection.left:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.right:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideDirection.up:
        beginOffset = const Offset(0.0, -1.0);
        break;
      case SlideDirection.down:
        beginOffset = const Offset(0.0, 1.0);
        break;
      default:
        beginOffset = const Offset(0.0, 1.0);
    }

    _animation = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve ?? Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(SlideInOut oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.show != oldWidget.show) {
      if (widget.show) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }

    if (widget.direction != oldWidget.direction) {
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SlideTransition(position: _animation, child: widget.child);
      },
    );
  }
}

// Staggered Slide Animation for lists
class StaggeredSlideAnimation extends StatefulWidget {
  final List<Widget> children;
  final SlideDirection direction;
  final Duration? itemDelay;
  final Duration? duration;
  final Curve? curve;
  final Axis? axis;
  final bool autoStart;

  const StaggeredSlideAnimation({
    Key? key,
    required this.children,
    this.direction = SlideDirection.up,
    this.itemDelay,
    this.duration,
    this.curve,
    this.axis,
    this.autoStart = true,
  }) : super(key: key);

  @override
  State<StaggeredSlideAnimation> createState() =>
      _StaggeredSlideAnimationState();
}

class _StaggeredSlideAnimationState extends State<StaggeredSlideAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration ?? const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    _setupAnimations();

    if (widget.autoStart) {
      _startStaggeredAnimation();
    }
  }

  void _setupAnimations() {
    Offset beginOffset;

    switch (widget.direction) {
      case SlideDirection.left:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.right:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideDirection.up:
        beginOffset = const Offset(0.0, -1.0);
        break;
      case SlideDirection.down:
        beginOffset = const Offset(0.0, 1.0);
        break;
      default:
        beginOffset = const Offset(0.0, 1.0);
    }

    _animations = _controllers.map((controller) {
      return Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
        CurvedAnimation(
          parent: controller,
          curve: widget.curve ?? Curves.easeOutCubic,
        ),
      );
    }).toList();
  }

  void _startStaggeredAnimation() async {
    final delay = widget.itemDelay ?? const Duration(milliseconds: 100);

    for (int i = 0; i < _controllers.length; i++) {
      if (mounted) {
        _controllers[i].forward();
        await Future.delayed(delay);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final axis = widget.axis ?? Axis.vertical;

    if (axis == Axis.vertical) {
      return Column(
        children: widget.children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, _) {
              return SlideTransition(
                position: _animations[index],
                child: child,
              );
            },
          );
        }).toList(),
      );
    } else {
      return Row(
        children: widget.children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, _) {
              return SlideTransition(
                position: _animations[index],
                child: child,
              );
            },
          );
        }).toList(),
      );
    }
  }
}
