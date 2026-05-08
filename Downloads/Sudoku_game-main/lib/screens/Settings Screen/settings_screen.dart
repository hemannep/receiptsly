import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Consumer<AppSettings>(
          builder: (context, settings, _) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.green.shade500,
                              Colors.green.shade700,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            "Settings",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Appearance Section
                  _SectionTitle(title: 'Appearance'),
                  _SettingsTile(
                    icon: Icons.dark_mode_rounded,
                    iconColor: Colors.indigo,
                    title: 'Dark Mode',
                    subtitle: 'Use dark theme',
                    value: settings.isDarkMode,
                    onChanged: (v) => settings.setDarkMode(v),
                  ),

                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Gameplay'),
                  _SettingsTile(
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.orange,
                    title: 'Highlight Conflicts',
                    subtitle: 'Show duplicate numbers in row/col/box',
                    value: settings.highlightConflicts,
                    onChanged: (v) => settings.setHighlightConflicts(v),
                  ),
                  _SettingsTile(
                    icon: Icons.numbers_rounded,
                    iconColor: Colors.green,
                    title: 'Highlight Same Number',
                    subtitle: 'Highlight cells with the same number',
                    value: settings.highlightSameNumber,
                    onChanged: (v) => settings.setHighlightSameNumber(v),
                  ),
                  _SettingsTile(
                    icon: Icons.auto_fix_high_rounded,
                    iconColor: Colors.purple,
                    title: 'Auto-Remove Notes',
                    subtitle: 'Remove notes when number is placed',
                    value: settings.autoRemoveNotes,
                    onChanged: (v) => settings.setAutoRemoveNotes(v),
                  ),
                  _SettingsTile(
                    icon: Icons.timer_rounded,
                    iconColor: Colors.blue,
                    title: 'Show Timer',
                    subtitle: 'Display the game timer',
                    value: settings.showTimer,
                    onChanged: (v) => settings.setShowTimer(v),
                  ),
                  _SettingsTile(
                    icon: Icons.error_outline_rounded,
                    iconColor: Colors.red,
                    title: 'Show Mistake Limit',
                    subtitle: 'Display the mistake counter',
                    value: settings.showMistakeLimit,
                    onChanged: (v) => settings.setShowMistakeLimit(v),
                  ),

                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Feedback'),
                  _SettingsTile(
                    icon: Icons.vibration_rounded,
                    iconColor: Colors.teal,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibrate on actions',
                    value: settings.hapticEnabled,
                    onChanged: (v) => settings.setHapticEnabled(v),
                  ),
                  _SettingsTile(
                    icon: Icons.volume_up_rounded,
                    iconColor: Colors.amber,
                    title: 'Sound Effects',
                    subtitle: 'Play sounds on actions',
                    value: settings.soundEnabled,
                    onChanged: (v) => settings.setSoundEnabled(v),
                  ),

                  const SizedBox(height: 18),
                  _SectionTitle(title: 'About'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '9',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sudoku Game',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Version 2.0.0',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Legal Links ───────────────────────────────────────
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Legal'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: _LegalTile(
                      icon: Icons.description_rounded,
                      iconColor: Colors.green,
                      title: 'Terms & Conditions',
                      subtitle: 'Read our terms of service',
                      url: 'https://mangojuiceapp.blogspot.com/#terms',
                      isDark: isDark,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: _LegalTile(
                      icon: Icons.privacy_tip_rounded,
                      iconColor: Colors.blue,
                      title: 'Privacy Policy',
                      subtitle: 'Read our privacy policy',
                      url: 'https://mangojuiceapp.blogspot.com/#privacy',
                      isDark: isDark,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String url;
  final bool isDark;

  const _LegalTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.isDark,
  });

  Future<void> _launch() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.green.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.green.shade600,
            ),
          ],
        ),
      ),
    );
  }
}
