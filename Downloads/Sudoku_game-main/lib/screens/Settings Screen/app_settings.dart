import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  bool _isDarkMode = false;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _highlightConflicts = true;
  bool _highlightSameNumber = true;
  bool _autoRemoveNotes = true;
  bool _showTimer = true;
  bool _showMistakeLimit = true;

  late SharedPreferences _prefs;
  bool _initialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;
  bool get highlightConflicts => _highlightConflicts;
  bool get highlightSameNumber => _highlightSameNumber;
  bool get autoRemoveNotes => _autoRemoveNotes;
  bool get showTimer => _showTimer;
  bool get showMistakeLimit => _showMistakeLimit;
  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    _soundEnabled = _prefs.getBool('soundEnabled') ?? true;
    _hapticEnabled = _prefs.getBool('hapticEnabled') ?? true;
    _highlightConflicts = _prefs.getBool('highlightConflicts') ?? true;
    _highlightSameNumber = _prefs.getBool('highlightSameNumber') ?? true;
    _autoRemoveNotes = _prefs.getBool('autoRemoveNotes') ?? true;
    _showTimer = _prefs.getBool('showTimer') ?? true;
    _showMistakeLimit = _prefs.getBool('showMistakeLimit') ?? true;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs.setBool('soundEnabled', value);
    notifyListeners();
  }

  Future<void> setHapticEnabled(bool value) async {
    _hapticEnabled = value;
    await _prefs.setBool('hapticEnabled', value);
    notifyListeners();
  }

  Future<void> setHighlightConflicts(bool value) async {
    _highlightConflicts = value;
    await _prefs.setBool('highlightConflicts', value);
    notifyListeners();
  }

  Future<void> setHighlightSameNumber(bool value) async {
    _highlightSameNumber = value;
    await _prefs.setBool('highlightSameNumber', value);
    notifyListeners();
  }

  Future<void> setAutoRemoveNotes(bool value) async {
    _autoRemoveNotes = value;
    await _prefs.setBool('autoRemoveNotes', value);
    notifyListeners();
  }

  Future<void> setShowTimer(bool value) async {
    _showTimer = value;
    await _prefs.setBool('showTimer', value);
    notifyListeners();
  }

  Future<void> setShowMistakeLimit(bool value) async {
    _showMistakeLimit = value;
    await _prefs.setBool('showMistakeLimit', value);
    notifyListeners();
  }

  // Helper: trigger haptic feedback if enabled
  void lightHaptic() {
    if (_hapticEnabled) HapticFeedback.lightImpact();
  }

  void mediumHaptic() {
    if (_hapticEnabled) HapticFeedback.mediumImpact();
  }

  void heavyHaptic() {
    if (_hapticEnabled) HapticFeedback.heavyImpact();
  }

  void selectionHaptic() {
    if (_hapticEnabled) HapticFeedback.selectionClick();
  }
}
