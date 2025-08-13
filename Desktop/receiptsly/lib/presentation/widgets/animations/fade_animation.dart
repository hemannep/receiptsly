import 'package:flutter/material.dart';

class FadeAnimation extends StatefulWidget {
  final Widget child;
  final Duration? duration;
  final Duration? delay;
  final Curve? curve;
  final AnimationController? controller;
  final bool autoStart;
  final VoidCallback? onComplete;
  final double? begin;
  final double? end;

  const FadeAnimation({
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
  }) : super(key: key);

  @override
  State<FadeAnimation> createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
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

    _animation =
        Tween<double>(
          begin: widget.begin ?? 0.0,
          end: widget.end ?? 1.0,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: widget.curve ?? Curves.easeInOut,
          ),
        );

    _animation.addStatusListener((status) {
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
      animation: _animation,
      builder: (context, child) {
        return Opacity(opacity: _animation.value, child: widget.child);
      },
    );
  }
}

// Fade Transition for route animations
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration? duration;
  final Curve? curve;

  FadeRoute({
    required this.child,
    this.duration,
    this.curve,
    RouteSettings? settings,
  }) : super(
         settings: settings,
         pageBuilder: (context, animation, secondaryAnimation) => child,
         transitionDuration: duration ?? const Duration(milliseconds: 300),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return FadeTransition(
             opacity: CurvedAnimation(
               parent: animation,
               curve: curve ?? Curves.easeInOut,
             ),
             child: child,
           );
         },
       );
}

// Fade In and Out Widget
class FadeInOut extends StatefulWidget {
  final Widget child;
  final bool show;
  final Duration? duration;
  final Curve? curve;
  final VoidCallback? onFadeIn;
  final VoidCallback? onFadeOut;

  const FadeInOut({
    Key? key,
    required this.child,
    required this.show,
    this.duration,
    this.curve,
    this.onFadeIn,
    this.onFadeOut,
  }) : super(key: key);

  @override
  State<FadeInOut> createState() => _FadeInOutState();
}

class _FadeInOutState extends State<FadeInOut>
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
        curve: widget.curve ?? Curves.easeInOut,
      ),
    );

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onFadeIn != null) {
        widget.onFadeIn!();
      } else if (status == AnimationStatus.dismissed &&
          widget.onFadeOut != null) {
        widget.onFadeOut!();
      }
    });

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FadeInOut oldWidget) {
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
        return Opacity(opacity: _animation.value, child: widget.child);
      },
    );
  }
}

// Staggered Fade Animation for lists
class StaggeredFadeAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration? itemDelay;
  final Duration? duration;
  final Curve? curve;
  final Axis? axis;
  final bool autoStart;

  const StaggeredFadeAnimation({
    Key? key,
    required this.children,
    this.itemDelay,
    this.duration,
    this.curve,
    this.axis,
    this.autoStart = true,
  }) : super(key: key);

  @override
  State<StaggeredFadeAnimation> createState() => _StaggeredFadeAnimationState();
}

class _StaggeredFadeAnimationState extends State<StaggeredFadeAnimation>
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
          curve: widget.curve ?? Curves.easeInOut,
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
              return Opacity(opacity: _animations[index].value, child: child);
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
              return Opacity(opacity: _animations[index].value, child: child);
            },
          );
        }).toList(),
      );
    }
  }
}
