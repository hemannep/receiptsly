// lib/presentation/widgets/common/app_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Production-ready dialog widget for Receiptsly app
/// Provides consistent styling and functionality across the app
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.contentPadding,
    this.actions = const [],
    this.isDismissible = true,
    this.useRootNavigator = true,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.alignment,
    this.semanticLabel,
    this.clipBehavior = Clip.none,
  });

  /// Dialog title
  final String? title;

  /// Dialog content widget
  final Widget? content;

  /// Padding around content
  final EdgeInsets? contentPadding;

  /// Action buttons
  final List<Widget> actions;

  /// Whether dialog can be dismissed by tapping outside
  final bool isDismissible;

  /// Whether to use root navigator
  final bool useRootNavigator;

  /// Background color
  final Color? backgroundColor;

  /// Dialog elevation
  final double? elevation;

  /// Dialog shape
  final ShapeBorder? shape;

  /// Dialog alignment
  final AlignmentGeometry? alignment;

  /// Semantic label for accessibility
  final String? semanticLabel;

  /// Clip behavior
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: title != null
          ? Text(
              title!,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      content: content,
      contentPadding:
          contentPadding ?? const EdgeInsets.fromLTRB(24, 20, 24, 24),
      actions: actions,
      backgroundColor: backgroundColor ?? theme.dialogBackgroundColor,
      elevation: elevation ?? 6,
      shape:
          shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      alignment: alignment,
      semanticLabel: semanticLabel,
      clipBehavior: clipBehavior,
    );
  }

  /// Shows the dialog
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget dialog,
    bool isDismissible = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => dialog,
      barrierDismissible: isDismissible,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }
}

/// Confirmation dialog for destructive actions
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
    this.icon,
  });

  /// Dialog title
  final String title;

  /// Confirmation message
  final String message;

  /// Confirm button text
  final String confirmText;

  /// Cancel button text
  final String cancelText;

  /// Whether this is a destructive action
  final bool isDestructive;

  /// Callback when confirmed
  final VoidCallback? onConfirm;

  /// Callback when cancelled
  final VoidCallback? onCancel;

  /// Optional icon
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppDialog(
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? theme.colorScheme.error.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Shows confirmation dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) {
    return AppDialog.show<bool>(
      context,
      dialog: AppConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }
}

/// Loading dialog with progress indicator
class AppLoadingDialog extends StatelessWidget {
  const AppLoadingDialog({
    super.key,
    required this.message,
    this.progress,
    this.canCancel = false,
    this.onCancel,
  });

  /// Loading message
  final String message;

  /// Optional progress value (0.0 to 1.0)
  final double? progress;

  /// Whether user can cancel
  final bool canCancel;

  /// Cancel callback
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      isDismissible: canCancel,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progress != null)
            CircularProgressIndicator(value: progress)
          else
            const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            Text(
              '${(progress! * 100).toInt()}%',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
      actions: canCancel
          ? [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
                child: const Text('Cancel'),
              ),
            ]
          : [],
    );
  }

  /// Shows loading dialog
  static Future<T?> show<T>(
    BuildContext context, {
    required String message,
    double? progress,
    bool canCancel = false,
    VoidCallback? onCancel,
  }) {
    return AppDialog.show<T>(
      context,
      dialog: AppLoadingDialog(
        message: message,
        progress: progress,
        canCancel: canCancel,
        onCancel: onCancel,
      ),
      isDismissible: canCancel,
    );
  }
}

/// Information dialog with single OK button
class AppInfoDialog extends StatelessWidget {
  const AppInfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.icon,
    this.onPressed,
  });

  /// Dialog title
  final String title;

  /// Information message
  final String message;

  /// Button text
  final String buttonText;

  /// Optional icon
  final IconData? icon;

  /// Button callback
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppDialog(
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
          ],
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onPressed?.call();
          },
          child: Text(buttonText),
        ),
      ],
    );
  }

  /// Shows info dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    return AppDialog.show(
      context,
      dialog: AppInfoDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }
}

/// Input dialog for text input
class AppInputDialog extends StatefulWidget {
  const AppInputDialog({
    super.key,
    required this.title,
    this.message,
    this.hintText,
    this.initialValue,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isRequired = false,
  });

  /// Dialog title
  final String title;

  /// Optional message
  final String? message;

  /// Input hint text
  final String? hintText;

  /// Initial input value
  final String? initialValue;

  /// Input validator
  final String? Function(String?)? validator;

  /// Keyboard type
  final TextInputType keyboardType;

  /// Maximum lines
  final int maxLines;

  /// Confirm button text
  final String confirmText;

  /// Cancel button text
  final String cancelText;

  /// Whether input is required
  final bool isRequired;

  @override
  State<AppInputDialog> createState() => _AppInputDialogState();
}

class _AppInputDialogState extends State<AppInputDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      if (widget.isRequired && _controller.text.trim().isEmpty) {
        _errorText = 'This field is required';
      } else {
        _errorText = widget.validator?.call(_controller.text);
      }
    });
  }

  void _confirm() {
    _validate();
    if (_errorText == null) {
      Navigator.of(context).pop(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(
              widget.message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            autofocus: true,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelText),
        ),
        ElevatedButton(onPressed: _confirm, child: Text(widget.confirmText)),
      ],
    );
  }

  /// Shows input dialog
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? message,
    String? hintText,
    String? initialValue,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isRequired = false,
  }) {
    return AppDialog.show<String>(
      context,
      dialog: AppInputDialog(
        title: title,
        message: message,
        hintText: hintText,
        initialValue: initialValue,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        confirmText: confirmText,
        cancelText: cancelText,
        isRequired: isRequired,
      ),
    );
  }
}

/// Choice dialog for selecting from options
class AppChoiceDialog<T> extends StatelessWidget {
  const AppChoiceDialog({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
    this.onChanged,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
  });

  /// Dialog title
  final String title;

  /// Available options
  final List<AppDialogOption<T>> options;

  /// Currently selected value
  final T? selectedValue;

  /// Selection change callback
  final ValueChanged<T?>? onChanged;

  /// Confirm button text
  final String confirmText;

  /// Cancel button text
  final String cancelText;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          return RadioListTile<T>(
            value: option.value,
            groupValue: selectedValue,
            onChanged: onChanged,
            title: Text(option.label),
            subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
            controlAffinity: ListTileControlAffinity.leading,
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: selectedValue != null
              ? () => Navigator.of(context).pop(selectedValue)
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Shows choice dialog
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<AppDialogOption<T>> options,
    T? selectedValue,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return AppDialog.show<T>(
      context,
      dialog: StatefulBuilder(
        builder: (context, setState) {
          return AppChoiceDialog<T>(
            title: title,
            options: options,
            selectedValue: selectedValue,
            onChanged: (value) {
              setState(() {
                selectedValue = value;
              });
            },
            confirmText: confirmText,
            cancelText: cancelText,
          );
        },
      ),
    );
  }
}

/// Dialog option model
class AppDialogOption<T> {
  const AppDialogOption({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}

/// Extension for easier dialog usage
extension AppDialogExtension on BuildContext {
  /// Shows confirmation dialog
  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) {
    return AppConfirmDialog.show(
      this,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
      icon: icon,
    );
  }

  /// Shows info dialog
  Future<void> showInfoDialog({
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon,
  }) {
    return AppInfoDialog.show(
      this,
      title: title,
      message: message,
      buttonText: buttonText,
      icon: icon,
    );
  }

  /// Shows loading dialog
  Future<T?> showLoadingDialog<T>({
    required String message,
    double? progress,
    bool canCancel = false,
  }) {
    return AppLoadingDialog.show<T>(
      this,
      message: message,
      progress: progress,
      canCancel: canCancel,
    );
  }

  /// Shows input dialog
  Future<String?> showInputDialog({
    required String title,
    String? message,
    String? hintText,
    String? initialValue,
    bool isRequired = false,
  }) {
    return AppInputDialog.show(
      this,
      title: title,
      message: message,
      hintText: hintText,
      initialValue: initialValue,
      isRequired: isRequired,
    );
  }
}
