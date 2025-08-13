// lib/presentation/screens/settings/widgets/settings_tile.dart
import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final bool enabled;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      enabled: enabled,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? theme.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled
              ? (iconColor ?? theme.primaryColor)
              : theme.disabledColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: enabled
              ? (titleColor ?? theme.colorScheme.onSurface)
              : theme.disabledColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.disabledColor,
              ),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: enabled
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.disabledColor,
                )
              : null),
      onTap: enabled ? onTap : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
