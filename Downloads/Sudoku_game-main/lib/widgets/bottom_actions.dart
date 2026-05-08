import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/Settings Screen/app_settings.dart' show AppSettings;

class BottomActions extends StatelessWidget {
  final bool notesMode;
  final VoidCallback onUndo;
  final VoidCallback onErase;
  final VoidCallback onNotes;
  final VoidCallback onHint;
  final bool canUndo;

  const BottomActions({
    super.key,
    required this.notesMode,
    required this.onUndo,
    required this.onErase,
    required this.onNotes,
    required this.onHint,
    this.canUndo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.undo_rounded,
            label: "Undo",
            onTap: onUndo,
            enabled: canUndo,
          ),
          _ActionButton(
            icon: Icons.delete_outline_rounded,
            label: "Erase",
            onTap: onErase,
          ),
          _ActionButton(
            icon: Icons.edit_note_rounded,
            label: "Notes",
            onTap: onNotes,
            active: notesMode,
          ),
          _ActionButton(
            icon: Icons.lightbulb_outline_rounded,
            label: "Hint",
            onTap: onHint,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool enabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.enabled = true,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;
    final bool showGreen = widget.active || isPressed;

    final disabledBg = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200;
    final defaultBg = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final disabledIcon = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final defaultIcon = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final labelColor = !widget.enabled
        ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
        : (isDark ? Colors.grey.shade200 : Colors.black87);

    return GestureDetector(
      onTapDown:
          widget.enabled ? (_) => setState(() => isPressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => isPressed = false) : null,
      onTapCancel:
          widget.enabled ? () => setState(() => isPressed = false) : null,
      onTap: widget.enabled
          ? () {
              settings.lightHaptic();
              widget.onTap();
            }
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: !widget.enabled
                  ? null
                  : showGreen
                      ? LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        )
                      : null,
              color: !widget.enabled
                  ? disabledBg
                  : showGreen
                      ? null
                      : defaultBg,
              boxShadow: !widget.enabled
                  ? []
                  : [
                      BoxShadow(
                        color: showGreen
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Icon(
              widget.icon,
              size: 24,
              color: !widget.enabled
                  ? disabledIcon
                  : showGreen
                      ? Colors.white
                      : defaultIcon,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
