// lib/services/firebase/analytics_service.dart
import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// Service for handling Firebase Analytics and custom event tracking
/// Manages user analytics, conversion tracking, and performance metrics
class AnalyticsService {
  static AnalyticsService? _instance;
  late FirebaseAnalytics _analytics;
  late FirebaseAnalyticsObserver _observer;

  String? _userId;
  Map<String, dynamic> _userProperties = {};
  Map<String, dynamic> _deviceInfo = {};
  final List<AnalyticsEvent> _eventQueue = [];
  Timer? _flushTimer;

  // Event categories
  static const String categoryAuth = 'auth';
  static const String categoryReceipt = 'receipt';
  static const String categoryInvoice = 'invoice';
  static const String categoryUI = 'ui';
  static const String categoryError = 'error';
  static const String categoryPerformance = 'performance';
  static const String categorySubscription = 'subscription';
  static const String categorySync = 'sync';

  // Singleton pattern
  AnalyticsService._();

  static AnalyticsService getInstance() {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  /// Initialize the analytics service
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics);

      // Set analytics collection based on build mode
      if (kReleaseMode) {
        await _analytics.setAnalyticsCollectionEnabled(true);
      } else {
        await _analytics.setAnalyticsCollectionEnabled(false);
      }

      // Collect device info
      await _collectDeviceInfo();

      // Setup periodic flush
      _setupPeriodicFlush();

      // Track app open
      await trackEvent('app_open');

      debugPrint('AnalyticsService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AnalyticsService: $e');
    }
  }

  /// Get Firebase Analytics observer for navigation tracking
  FirebaseAnalyticsObserver get observer => _observer;

  /// Setup periodic event flushing
  void _setupPeriodicFlush() {
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _flushEventQueue();
    });
  }

  /// Collect device and app information
  Future<void> _collectDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      _deviceInfo = {
        'app_version': packageInfo.version,
        'app_build': packageInfo.buildNumber,
        'package_name': packageInfo.packageName,
        'platform': Platform.operatingSystem,
      };

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceInfo.addAll({
          'device_model': androidInfo.model,
          'device_brand': androidInfo.brand,
          'device_manufacturer': androidInfo.manufacturer,
          'android_version': androidInfo.version.release,
          'device_type': 'android',
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceInfo.addAll({
          'device_model': iosInfo.model,
          'device_name': iosInfo.name,
          'ios_version': iosInfo.systemVersion,
          'device_type': 'ios',
        });
      }

      // Set default user properties
      await _setDeviceProperties();
    } catch (e) {
      debugPrint('Error collecting device info: $e');
    }
  }

  /// Set device properties as user properties
  Future<void> _setDeviceProperties() async {
    try {
      for (final entry in _deviceInfo.entries) {
        await _analytics.setUserProperty(
          name: entry.key,
          value: entry.value?.toString(),
        );
      }
    } catch (e) {
      debugPrint('Error setting device properties: $e');
    }
  }

  // User Management

  /// Set user ID for analytics
  Future<void> setUserId(String userId) async {
    try {
      _userId = userId;
      await _analytics.setUserId(id: userId);
      debugPrint('Analytics user ID set: $userId');
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      _userProperties.addAll(properties);

      for (final entry in properties.entries) {
        await _analytics.setUserProperty(
          name: entry.key,
          value: entry.value?.toString(),
        );
      }

      debugPrint('User properties set: ${properties.keys}');
    } catch (e) {
      debugPrint('Error setting user properties: $e');
    }
  }

  /// Clear user data
  Future<void> clearUserData() async {
    try {
      _userId = null;
      _userProperties.clear();
      await _analytics.setUserId(id: null);
      debugPrint('User analytics data cleared');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  // Event Tracking

  /// Track custom event
  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? parameters,
    String? category,
    bool immediate = false,
  }) async {
    try {
      final event = AnalyticsEvent(
        name: name,
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'category': category ?? 'general',
          'user_id': _userId,
          ...?parameters,
        },
      );

      if (immediate) {
        await _sendEvent(event);
      } else {
        _eventQueue.add(event);
      }

      debugPrint('Event tracked: $name (${event.parameters})');
    } catch (e) {
      debugPrint('Error tracking event: $e');
    }
  }

  /// Send event to Firebase Analytics
  Future<void> _sendEvent(AnalyticsEvent event) async {
    try {
      // Clean parameters for Firebase Analytics
      final cleanedParameters = <String, Object>{};

      event.parameters?.forEach((key, value) {
        if (value != null) {
          if (value is String || value is num || value is bool) {
            cleanedParameters[key] = value;
          } else {
            cleanedParameters[key] = value.toString();
          }
        }
      });

      await _analytics.logEvent(
        name: event.name,
        parameters: cleanedParameters,
      );
    } catch (e) {
      debugPrint('Error sending event: $e');
    }
  }

  /// Flush event queue
  Future<void> _flushEventQueue() async {
    if (_eventQueue.isEmpty) return;

    try {
      final events = List<AnalyticsEvent>.from(_eventQueue);
      _eventQueue.clear();

      for (final event in events) {
        await _sendEvent(event);
      }

      debugPrint('Flushed ${events.length} analytics events');
    } catch (e) {
      debugPrint('Error flushing event queue: $e');
    }
  }

  // Authentication Events

  /// Track user sign up
  Future<void> trackSignUp(String method) async {
    await trackEvent(
      'sign_up',
      parameters: {'method': method},
      category: categoryAuth,
      immediate: true,
    );
  }

  /// Track user login
  Future<void> trackLogin(String method) async {
    await trackEvent(
      'login',
      parameters: {'method': method},
      category: categoryAuth,
      immediate: true,
    );
  }

  /// Track user logout
  Future<void> trackLogout() async {
    await trackEvent('logout', category: categoryAuth, immediate: true);
  }

  // Receipt Events

  /// Track receipt capture
  Future<void> trackReceiptCapture({
    required String source,
    required String method,
    double? amount,
    String? category,
  }) async {
    await trackEvent(
      'receipt_capture',
      parameters: {
        'source': source, // camera, gallery, whatsapp, telegram
        'method': method, // manual, auto
        'amount': amount,
        'category': category,
      },
      category: categoryReceipt,
    );
  }

  /// Track OCR processing
  Future<void> trackOCRProcessing({
    required double confidence,
    required int processingTime,
    required bool success,
  }) async {
    await trackEvent(
      'ocr_processing',
      parameters: {
        'confidence': confidence,
        'processing_time_ms': processingTime,
        'success': success,
      },
      category: categoryReceipt,
    );
  }

  /// Track receipt edit
  Future<void> trackReceiptEdit({
    required String field,
    required String changeType,
  }) async {
    await trackEvent(
      'receipt_edit',
      parameters: {
        'field': field, // vendor, amount, category, date
        'change_type': changeType, // manual, suggestion
      },
      category: categoryReceipt,
    );
  }

  /// Track receipt deletion
  Future<void> trackReceiptDelete() async {
    await trackEvent('receipt_delete', category: categoryReceipt);
  }

  // Invoice Events

  /// Track invoice creation
  Future<void> trackInvoiceCreate({
    required double amount,
    required int itemCount,
    String? template,
  }) async {
    await trackEvent(
      'invoice_create',
      parameters: {
        'amount': amount,
        'item_count': itemCount,
        'template': template,
      },
      category: categoryInvoice,
    );
  }

  /// Track invoice sent
  Future<void> trackInvoiceSent({
    required String method,
    required double amount,
  }) async {
    await trackEvent(
      'invoice_sent',
      parameters: {
        'method': method, // email, whatsapp, link
        'amount': amount,
      },
      category: categoryInvoice,
    );
  }

  /// Track invoice payment
  Future<void> trackInvoicePayment({
    required double amount,
    required String currency,
    int? daysToPay,
  }) async {
    await trackEvent(
      'invoice_payment',
      parameters: {
        'amount': amount,
        'currency': currency,
        'days_to_pay': daysToPay,
      },
      category: categoryInvoice,
    );
  }

  // UI Events

  /// Track screen view
  Future<void> trackScreenView(String screenName, {String? screenClass}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  /// Track button tap
  Future<void> trackButtonTap(String buttonName, {String? screen}) async {
    await trackEvent(
      'button_tap',
      parameters: {'button_name': buttonName, 'screen': screen},
      category: categoryUI,
    );
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(
    String featureName, {
    Map<String, dynamic>? context,
  }) async {
    await trackEvent(
      'feature_usage',
      parameters: {'feature_name': featureName, ...?context},
      category: categoryUI,
    );
  }

  /// Track search
  Future<void> trackSearch({
    required String searchTerm,
    required String searchType,
    int? resultCount,
  }) async {
    await trackEvent(
      'search',
      parameters: {
        'search_term': searchTerm,
        'search_type': searchType,
        'result_count': resultCount,
      },
      category: categoryUI,
    );
  }
}
