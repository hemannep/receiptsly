// lib/presentation/widgets/common/app_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Production-ready text field widget for Receiptsly app
/// Supports validation, different input types, and accessibility features
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.inputType = TextInputType.text,
    this.isObscure = false,
    this.isEnabled = true,
    this.isRequired = false,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.textInputAction,
    this.inputFormatters,
    this.semanticLabel,
    this.testKey,
    this.showCharacterCount = false,
    this.autovalidateMode,
    this.readOnly = false,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.borderType = AppTextFieldBorderType.outline,
    this.density = AppTextFieldDensity.standard,
  });

  /// Text editing controller
  final TextEditingController? controller;

  /// Label text displayed above the field
  final String? label;

  /// Hint text displayed when field is empty
  final String? hint;

  /// Helper text displayed below the field
  final String? helperText;

  /// Error text displayed below the field
  final String? errorText;

  /// Icon displayed at the start of the field
  final IconData? prefixIcon;

  /// Widget displayed at the end of the field
  final Widget? suffixIcon;

  /// Keyboard type for the input
  final TextInputType inputType;

  /// Whether the text should be obscured (for passwords)
  final bool isObscure;

  /// Whether the field is enabled
  final bool isEnabled;

  /// Whether the field is required
  final bool isRequired;

  /// Maximum number of lines
  final int maxLines;

  /// Maximum character length
  final int? maxLength;

  /// Validation function
  final String? Function(String?)? validator;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Callback when submitted
  final ValueChanged<String>? onSubmitted;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Focus node for controlling focus
  final FocusNode? focusNode;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Input formatters for controlling input
  final List<TextInputFormatter>? inputFormatters;

  /// Semantic label for accessibility
  final String? semanticLabel;

  /// Test key for widget testing
  final String? testKey;

  /// Whether to show character count
  final bool showCharacterCount;

  /// Auto-validation mode
  final AutovalidateMode? autovalidateMode;

  /// Whether the field is read-only
  final bool readOnly;

  /// Whether to auto-focus
  final bool autofocus;

  /// Text capitalization behavior
  final TextCapitalization textCapitalization;

  /// Border style type
  final AppTextFieldBorderType borderType;

  /// Field density for compact layouts
  final AppTextFieldDensity density;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isObscured = false;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _isObscured = widget.isObscure;
    
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget textField = _buildTextField(theme);
    
    // Add semantic label for accessibility
    if (widget.semanticLabel != null) {
      textField = Semantics(
        label: widget.semanticLabel,
        textField: true,
        child: textField,
      );
    }

    // Add test key if provided
    if (widget.testKey != null) {
      textField = Container(
        key: Key(widget.testKey!),
        child: textField,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) _buildLabel(theme),
        textField,
        if (_shouldShowHelperOrError()) _buildHelperText(theme),
        if (widget.showCharacterCount && widget.maxLength != null) 
          _buildCharacterCount(theme),
      ],
    );
  }

  /// Builds the main text field widget
  Widget _buildTextField(ThemeData theme) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: widget.inputType,
      obscureText: _isObscured,
      enabled: widget.isEnabled,
      maxLines: widget.isObscure ? 1 : widget.maxLines,
      maxLength: widget.showCharacterCount ? null : widget.maxLength,
      validator: _getValidator(),
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      textInputAction: widget.textInputAction,
      inputFormatters: _getInputFormatters(),
      autovalidateMode: widget.autovalidateMode,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      textCapitalization: widget.textCapitalization,
      style: _getTextStyle(theme),
      decoration: _getInputDecoration(theme),
      buildCounter: widget.showCharacterCount ? null : (_,{required currentLength, maxLength, required isFocused}) => null,
    );
  }

  /// Builds the label widget
  Widget _buildLabel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(text: widget.label),
            if (widget.isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds helper text or error text
  Widget _buildHelperText(ThemeData theme) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final text = hasError ? widget.errorText! : widget.helperText!;
    final color = hasError ? theme.colorScheme.error : theme.colorScheme.onSurface.withOpacity(0.6);
    
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasError) ...[
            Icon(
              Icons.error_outline,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds character count indicator
  Widget _buildCharacterCount(ThemeData theme) {
    final currentLength = _controller.text.length;
    final maxLength = widget.maxLength!;
    final isOverLimit = currentLength > maxLength;
    
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$currentLength/$maxLength',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isOverLimit 
              ? theme.colorScheme.error 
              : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  /// Gets input decoration based on theme and state
  InputDecoration _getInputDecoration(ThemeData theme) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    
    return InputDecoration(
      hintText: widget.hint,
      prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
      suffixIcon: _buildSuffixIcon(),
      border: _getBorder(theme, AppTextFieldBorderState.normal),
      enabledBorder: _getBorder(theme, AppTextFieldBorderState.enabled),
      focusedBorder: _getBorder(theme, AppTextFieldBorderState.focused),
      errorBorder: _getBorder(theme, AppTextFieldBorderState.error),
      focusedErrorBorder: _getBorder(theme, AppTextFieldBorderState.focusedError),
      disabledBorder: _getBorder(theme, AppTextFieldBorderState.disabled),
      filled: widget.borderType == AppTextFieldBorderType.filled,
      fillColor: widget.borderType == AppTextFieldBorderType.filled 
        ? theme.colorScheme.surfaceVariant.withOpacity(0.1)
        : null,
      contentPadding: _getContentPadding(),
      isDense: widget.density == AppTextFieldDensity.compact,
      errorText: null, // We handle error text separately
      counterText: '', // We handle counter separately
    );
  }

  /// Builds the suffix icon with password visibility toggle
  Widget? _buildSuffixIcon() {
    if (widget.isObscure) {
      return IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility_off : Icons.visibility,
          semanticLabel: _isObscured ? 'Show password' : 'Hide password',
        ),
        onPressed: () {
          setState(() {
            _isObscured = !_isObscured;
          });
        },
      );
    }
    return widget.suffixIcon;
  }

  /// Gets border based on state and type
  InputBorder _getBorder(ThemeData theme, AppTextFieldBorderState state) {
    final borderRadius = BorderRadius.circular(8.0);
    
    switch (widget.borderType) {
      case AppTextFieldBorderType.outline:
        return OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: _getBorderColor(theme, state),
            width: _getBorderWidth(state),
          ),
        );
      case AppTextFieldBorderType.underline:
        return UnderlineInputBorder(
          borderSide: BorderSide(
            color: _getBorderColor(theme, state),
            width: _getBorderWidth(state),
          ),
        );
      case AppTextFieldBorderType.filled:
        return OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: state == AppTextFieldBorderState.focused 
              ? theme.colorScheme.primary
              : Colors.transparent,
            width: _getBorderWidth(state),
          ),
        );
    }
  }

  /// Gets border color based on state
  Color _getBorderColor(ThemeData theme, AppTextFieldBorderState state) {
    switch (state) {
      case AppTextFieldBorderState.normal:
      case AppTextFieldBorderState.enabled:
        return theme.colorScheme.outline;
      case AppTextFieldBorderState.focused:
        return theme.colorScheme.primary;
      case AppTextFieldBorderState.error:
      case AppTextFieldBorderState.focusedError:
        return theme.colorScheme.error;
      case AppTextFieldBorderState.disabled:
        return theme.colorScheme.outline.withOpacity(0.5);
    }
  }

  /// Gets border width based on state
  double _getBorderWidth(AppTextFieldBorderState state) {
    switch (state) {
      case AppTextFieldBorderState.focused:
      case AppTextFieldBorderState.focusedError:
        return 2.0;
      default:
        return 1.0;
    }
  }

  /// Gets content padding based on density
  EdgeInsets _getContentPadding() {
    switch (widget.density) {
      case AppTextFieldDensity.compact:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppTextFieldDensity.standard:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case AppTextFieldDensity.comfortable:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
  }

  /// Gets text style
  TextStyle _getTextStyle(ThemeData theme) {
    return theme.textTheme.bodyMedium?.copyWith(
      color: widget.isEnabled 
        ? theme.colorScheme.onSurface 
        : theme.colorScheme.onSurface.withOpacity(0.38),
    ) ?? const TextStyle();
  }

  /// Gets effective validator function
  String? Function(String?)? _getValidator() {
    if (widget.validator == null && !widget.isRequired) return null;
    
    return (value) {
      // Check required validation first
      if (widget.isRequired && (value == null || value.trim().isEmpty)) {
        return '${widget.label ?? 'This field'} is required';
      }
      
      // Then apply custom validator
      return widget.validator?.call(value);
    };
  }

  /// Gets input formatters including max length
  List<TextInputFormatter> _getInputFormatters() {
    final formatters = <TextInputFormatter>[
      ...?widget.inputFormatters,
    ];
    
    // Add length formatter if maxLength is specified and not showing counter
    if (widget.maxLength != null && !widget.showCharacterCount) {
      formatters.add(LengthLimitingTextInputFormatter(widget.maxLength));
    }
    
    return formatters;
  }

  /// Whether to show helper text or error text
  bool _shouldShowHelperOrError() {
    return (widget.helperText != null && widget.helperText!.isNotEmpty) ||
           (widget.errorText != null && widget.errorText!.isNotEmpty);
  }
}

/// Border type variants for text field
enum AppTextFieldBorderType {
  outline,    // Outlined border
  underline,  // Underline border
  filled,     // Filled background with border
}

/// Border state for styling
enum AppTextFieldBorderState {
  normal,
  enabled,
  focused,
  error,
  focusedError,
  disabled,
}

/// Density variants for text field
enum AppTextFieldDensity {
  compact,    // Smaller padding
  standard,   // Default padding
  comfortable, // Larger padding
}

/// Extension methods for common text field types
extension AppTextFieldExtension on AppTextField {
  /// Creates an email text field
  static AppTextField email({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? helperText,
    String? errorText,
    bool isRequired = false,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    bool isEnabled = true,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label ?? 'Email',
      hint: hint ?? 'Enter your email address',
      helperText: helperText,
      errorText: errorText,
      prefixIcon: Icons.email_outlined,
      inputType: TextInputType.emailAddress,
      isRequired: isRequired,
      onChanged: onChanged,
      validator: validator ?? _emailValidator,
      isEnabled: isEnabled,
      textInputAction: TextInputAction.next,
    );
  }

  /// Creates a password text field
  static AppTextField password({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? helperText,
    String? errorText,
    bool isRequired = false,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    bool isEnabled = true,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label ?? 'Password',
      hint: hint ?? 'Enter your password',
      helperText: helperText,
      errorText: errorText,
      prefixIcon: Icons.lock_outline,
      isObscure: true,
      isRequired: isRequired,
      onChanged: onChanged,
      validator: validator,
      isEnabled: isEnabled,
      textInputAction: TextInputAction.done,
    );
  }

  /// Creates a phone number text field
  static AppTextField phone({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? helperText,
    String? errorText,
    bool isRequired = false,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    bool isEnabled = true,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label ?? 'Phone Number',
      hint: hint ?? 'Enter your phone number',
      helperText: helperText,
      errorText: errorText,
      prefixIcon: Icons.phone_outlined,
      inputType: TextInputType.phone,
      isRequired: isRequired,
      onChanged: onChanged,
      validator: validator ?? _phoneValidator,
      isEnabled: isEnabled,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(15),
      ],
    );
  }

  /// Creates a currency amount text field
  static AppTextField currency({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? helperText,
    String? errorText,
    bool isRequired = false,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    bool isEnabled = true,
    String currencySymbol = '\,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label ?? 'Amount',
      hint: hint ?? '0.00',
      helperText: helperText,
      errorText: errorText,
      prefixIcon: Icons.attach_money,
      inputType: const TextInputType.numberWithOptions(decimal: true),
      isRequired: isRequired,
      onChanged: onChanged,
      validator: validator ?? _currencyValidator,
      isEnabled: isEnabled,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
    );
  }

  /// Creates a search text field
  static AppTextField search({
    Key? key,
    TextEditingController? controller,
    String? hint,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
    bool isEnabled = true,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      hint: hint ?? 'Search...',
      prefixIcon: Icons.search,
      suffixIcon: onClear != null 
        ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: onClear,
            tooltip: 'Clear search',
          )
        : null,
      onChanged: onChanged,
      isEnabled: isEnabled,
      textInputAction: TextInputAction.search,
      borderType: AppTextFieldBorderType.filled,
    );
  }

  /// Creates a multiline text area
  static AppTextField textArea({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? helperText,
    String? errorText,
    bool isRequired = false,
    int maxLines = 3,
    int? maxLength,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    bool isEnabled = true,
    bool showCharacterCount = false,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      isRequired: isRequired,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      isEnabled: isEnabled,
      showCharacterCount: showCharacterCount,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  /// Email validation
  static String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,});
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Phone validation
  static String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]{10,15});
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\+\(\)]'), ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Currency validation
  static String? _currencyValidator(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount < 0) {
      return 'Amount cannot be negative';
    }
    return null;
  }
}