import 'package:flutter/material.dart';

class ScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration? duration;
  final Duration? delay;
  final Curve? curve;
  final AnimationController? controller;
  final bool autoStart;
  final VoidCallback? onComplete;
  final double? begin;
  final double? end;
  final Alignment? alignment;

  const ScaleAnimation({
    Key? key,
    required this.child,
    this.duration,
    this.delay,
    this.curve,
    this.controller,
    this.autoStart = true,
    this.onComplete,
    this.begin,
    this.end,
    this.alignment,
  }) : super(key: key);

  @override
  State<ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isControllerOwned = false;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = AnimationController(
        duration: widget.duration ?? const Duration(milliseconds: 300),
        vsync: this,
      );
      _isControllerOwned = true;
    }

    _scaleAnimation =
        Tween<double>(
          begin: widget.begin ?? 0.0,
          end: widget.end ?? 1.0,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: widget.curve ?? Curves.elasticOut,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: widget.curve ?? Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });

    if (widget.autoStart && _isControllerOwned) {
      _startAnimation();
    }
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
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: widget.alignment ?? Alignment.center,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Scale Route for page transitions
class ScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration? duration;
  final Curve? curve;
  final Alignment? alignment;

  ScaleRoute({
    required this.child,
    this.duration,
    this.curve,
    this.alignment,
    RouteSettings? settings,
  }) : super(
         settings: settings,
         pageBuilder: (context, animation, secondaryAnimation) => child,
         transitionDuration: duration ?? const Duration(milliseconds: 300),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return ScaleTransition(
             scale: CurvedAnimation(
               parent: animation,
               curve: curve ?? Curves.elasticOut,
             ),
             alignment: alignment ?? Alignment.center,
             child: child,
           );
         },
       );
}

// Scale In and Out Widget
class ScaleInOut extends StatefulWidget {
  final Widget child;
  final bool show;
  final Duration? duration;
  final Curve? curve;
  final Alignment? alignment;
  final VoidCallback? onScaleIn;
  final VoidCallback? onScaleOut;

  const ScaleInOut({
    Key? key,
    required this.child,
    required this.show,
    this.duration,
    this.curve,
    this.alignment,
    this.onScaleIn,
    this.onScaleOut,
  }) : super(key: key);

  @override
  State<ScaleInOut> createState() => _ScaleInOutState();
}

class _ScaleInOutState extends State<ScaleInOut>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve ?? Curves.elasticOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onScaleIn != null) {
        widget.onScaleIn!();
      } else if (status == AnimationStatus.dismissed &&
          widget.onScaleOut != null) {
        widget.onScaleOut!();
      }
    });

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ScaleInOut oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.show != oldWidget.show) {
      if (widget.show) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
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
        return Transform.scale(
          scale: _animation.value,
          alignment: widget.alignment ?? Alignment.center,
          child: widget.child,
        );
      },
    );
  }
}

// Bounce Scale Animation
class BounceScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration? duration;
  final Duration? delay;
  final bool autoStart;
  final VoidCallback? onComplete;
  final double? maxScale;

  const BounceScaleAnimation({
    Key? key,
    required this.child,
    this.duration,
    this.delay,
    this.autoStart = true,
    this.onComplete,
    this.maxScale,
  }) : super(key: key);

  @override
  State<BounceScaleAnimation> createState() => _BounceScaleAnimationState();
}

class _BounceScaleAnimationState extends State<BounceScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: widget.maxScale ?? 1.2),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.maxScale ?? 1.2, end: 0.9),
        weight: 30,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 1.1), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });

    if (widget.autoStart) {
      _startAnimation();
    }
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: widget.child);
      },
    );
  }
}

// Pulse Scale Animation
class PulseScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration? duration;
  final double? minScale;
  final double? maxScale;
  final bool repeat;
  final int? repeatCount;

  const PulseScaleAnimation({
    Key? key,
    required this.child,
    this.duration,
    this.minScale,
    this.maxScale,
    this.repeat = true,
    this.repeatCount,
  }) : super(key: key);

  @override
  State<PulseScaleAnimation> createState() => _PulseScaleAnimationState();
}

class _PulseScaleAnimationState extends State<PulseScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentCount = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.minScale ?? 0.9,
      end: widget.maxScale ?? 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.repeat) {
          if (widget.repeatCount == null ||
              _currentCount < widget.repeatCount!) {
            _currentCount++;
            _controller.reverse();
          }
        }
      } else if (status == AnimationStatus.dismissed) {
        if (widget.repeat) {
          if (widget.repeatCount == null ||
              _currentCount < widget.repeatCount!) {
            _controller.forward();
          }
        }
      }
    });

    _controller.forward();
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
        return Transform.scale(scale: _animation.value, child: widget.child);
      },
    );
  }
}

// Staggered Scale Animation for lists
class StaggeredScaleAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration? itemDelay;
  final Duration? duration;
  final Curve? curve;
  final Axis? axis;
  final bool autoStart;

  const StaggeredScaleAnimation({
    Key? key,
    required this.children,
    this.itemDelay,
    this.duration,
    this.curve,
    this.axis,
    this.autoStart = true,
  }) : super(key: key);

  @override
  State<StaggeredScaleAnimation> createState() =>
      _StaggeredScaleAnimationState();
}

class _StaggeredScaleAnimationState extends State<StaggeredScaleAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration ?? const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: widget.curve ?? Curves.elasticOut,
        ),
      );
    }).toList();

    if (widget.autoStart) {
      _startStaggeredAnimation();
    }
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
              return Transform.scale(
                scale: _animations[index].value,
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
              return Transform.scale(
                scale: _animations[index].value,
                child: child,
              );
            },
          );
        }).toList(),
      );
    }
  }
}

// Interactive Scale Animation (for buttons)
class InteractiveScaleAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? scaleDown;
  final Duration? duration;

  const InteractiveScaleAnimation({
    Key? key,
    required this.child,
    this.onTap,
    this.scaleDown,
    this.duration,
  }) : super(key: key);

  @override
  State<InteractiveScaleAnimation> createState() =>
      _InteractiveScaleAnimationState();
}

class _InteractiveScaleAnimationState extends State<InteractiveScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 100),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown ?? 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(scale: _animation.value, child: widget.child);
        },
      ),
    );
  }
}
