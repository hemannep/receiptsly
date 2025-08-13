// lib/presentation/screens/auth/widgets/otp_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class OTPInputField extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final Function(String)? onCompleted;
  final Function(String)? onChanged;
  final bool enabled;
  final bool autoFocus;
  final double fieldWidth;
  final double fieldHeight;
  final double spacing;

  const OTPInputField({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.autoFocus = true,
    this.fieldWidth = 50,
    this.fieldHeight = 60,
    this.spacing = 12,
  });

  @override
  State<OTPInputField> createState() => _OTPInputFieldState();
}

class _OTPInputFieldState extends State<OTPInputField> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );

    // Listen to main controller changes
    widget.controller.addListener(_onMainControllerChanged);

    if (widget.autoFocus && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onMainControllerChanged);
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onMainControllerChanged() {
    final text = widget.controller.text;
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].text = i < text.length ? text[i] : '';
    }
  }

  void _onFieldChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste operation
      _handlePaste(value, index);
      return;
    }

    // Update the specific field
    _controllers[index].text = value;

    // Update main controller
    final currentText = _controllers.map((c) => c.text).join();
    widget.controller.text = currentText;

    // Call onChanged callback
    widget.onChanged?.call(currentText);

    // Move to next field or complete
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (currentText.length == widget.length) {
          widget.onCompleted?.call(currentText);
        }
      }
    }
  }

  void _handlePaste(String pastedText, int startIndex) {
    final digits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');

    for (int i = 0; i < widget.length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }

    final finalText = _controllers.map((c) => c.text).join();
    widget.controller.text = finalText;
    widget.onChanged?.call(finalText);

    // Focus appropriate field
    final focusIndex = (startIndex + digits.length).clamp(0, widget.length - 1);
    _focusNodes[focusIndex].requestFocus();

    if (finalText.length == widget.length) {
      widget.onCompleted?.call(finalText);
    }
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      // Move to previous field on backspace if current field is empty
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _updateMainController();
    }
  }

  void _updateMainController() {
    final currentText = _controllers.map((c) => c.text).join();
    widget.controller.text = currentText;
    widget.onChanged?.call(currentText);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.length,
            (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: _buildOTPField(index),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Enter the 6-digit code sent to your phone',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOTPField(int index) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (event) => _onKeyPressed(index, event),
      child: SizedBox(
        width: widget.fieldWidth,
        height: widget.fieldHeight,
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          enabled: widget.enabled,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          decoration: InputDecoration(
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: widget.enabled
                ? AppColors.surface
                : AppColors.surface.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (value) => _onFieldChanged(index, value),
          onTap: () {
            // Clear field and position cursor properly
            if (_controllers[index].text.isNotEmpty) {
              _controllers[index].selection = TextSelection.fromPosition(
                TextPosition(offset: _controllers[index].text.length),
              );
            }
          },
        ),
      ),
    );
  }
}
