// lib/presentation/screens/onboarding/widgets/progress_indicator.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class OnboardingProgressIndicator extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final bool showLabels;
  final List<String>? labels;
  final bool showPercentage;
  final Duration animationDuration;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.showLabels = false,
    this.labels,
    this.showPercentage = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<OnboardingProgressIndicator> createState() =>
      _OnboardingProgressIndicatorState();
}

class _OnboardingProgressIndicatorState
    extends State<OnboardingProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _updateProgress();
  }

  @override
  void didUpdateWidget(OnboardingProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage ||
        oldWidget.totalPages != widget.totalPages) {
      _updateProgress();
    }
  }

  void _updateProgress() {
    final progress = (widget.currentPage + 1) / widget.totalPages;
    _progressAnimation =
        Tween<double>(begin: _progressController.value, end: progress).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showPercentage) ...[
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              final percentage = (_progressAnimation.value * 100).round();
              return Text(
                '$percentage% Complete',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],

        // Progress Bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                borderRadius: BorderRadius.circular(3),
              );
            },
          ),
        ),

        if (widget.showLabels && widget.labels != null) ...[
          const SizedBox(height: 12),
          _buildStepLabels(),
        ],
      ],
    );
  }

  Widget _buildStepLabels() {
    final labels = widget.labels!;

    return Row(
      children: List.generate(
        labels.length,
        (index) => Expanded(
          child: _buildStepLabel(
            label: labels[index],
            index: index,
            isActive: index <= widget.currentPage,
            isCompleted: index < widget.currentPage,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLabel({
    required String label,
    required int index,
    required bool isActive,
    required bool isCompleted,
  }) {
    Color circleColor;
    Color textColor;
    IconData? icon;

    if (isCompleted) {
      circleColor = AppColors.success;
      textColor = AppColors.success;
      icon = Icons.check;
    } else if (isActive) {
      circleColor = AppColors.primary;
      textColor = AppColors.primary;
    } else {
      circleColor = AppColors.surface;
      textColor = AppColors.textSecondary;
    }

    return Column(
      children: [
        // Step Circle
        AnimatedContainer(
          duration: widget.animationDuration,
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isCompleted ? circleColor : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 14, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isActive || isCompleted
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 8),

        // Label Text
        AnimatedDefaultTextStyle(
          duration: widget.animationDuration,
          style: AppTypography.bodySmall.copyWith(
            color: textColor,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Alternative Dot Style Progress Indicator
class DotProgressIndicator extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final double dotSize;
  final double spacing;
  final Color activeColor;
  final Color inactiveColor;
  final Duration animationDuration;

  const DotProgressIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.dotSize = 8.0,
    this.spacing = 8.0,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.grey,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<DotProgressIndicator> createState() => _DotProgressIndicatorState();
}

class _DotProgressIndicatorState extends State<DotProgressIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.totalPages,
      (index) =>
          AnimationController(duration: widget.animationDuration, vsync: this),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _updateAnimations();
  }

  void _updateAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      if (i <= widget.currentPage) {
        _controllers[i].forward();
      } else {
        _controllers[i].reverse();
      }
    }
  }

  @override
  void didUpdateWidget(DotProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _updateAnimations();
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.totalPages,
        (index) => AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            final isActive = index == widget.currentPage;
            final progress = _animations[index].value;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              width: isActive ? widget.dotSize * 3 : widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: Color.lerp(
                  widget.inactiveColor,
                  widget.activeColor,
                  progress,
                ),
                borderRadius: BorderRadius.circular(widget.dotSize / 2),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Stepper Style Progress Indicator
class StepperProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;
  final Color activeColor;
  final Color completedColor;
  final Color inactiveColor;

  const StepperProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
    this.activeColor = Colors.blue,
    this.completedColor = Colors.green,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(totalSteps, (index) => _buildStep(index)),
    );
  }

  Widget _buildStep(int index) {
    final isCompleted = index < currentStep;
    final isActive = index == currentStep;
    final isLast = index == totalSteps - 1;

    Color circleColor;
    Color lineColor;
    IconData? icon;

    if (isCompleted) {
      circleColor = completedColor;
      lineColor = completedColor;
      icon = Icons.check;
    } else if (isActive) {
      circleColor = activeColor;
      lineColor = inactiveColor;
    } else {
      circleColor = inactiveColor;
      lineColor = inactiveColor;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: Colors.white, size: 14)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (!isLast) Container(width: 2, height: 40, color: lineColor),
          ],
        ),

        const SizedBox(width: 12),

        // Step content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepTitles[index],
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive || isCompleted
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 40,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
