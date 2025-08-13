// lib/core/utils/device_info.dart
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

/// Comprehensive device information manager for Receiptsly app
/// Provides detailed device, app, and system information for analytics and debugging
class DeviceInfo {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static final Connectivity _connectivity = Connectivity();

  // Cached device information
  static Map<String, dynamic>? _cachedDeviceInfo;
  static Map<String, dynamic>? _cachedAppInfo;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(hours: 1);

  // Device information getters
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_isCacheValid()) {
      return _cachedDeviceInfo!;
    }

    try {
      Map<String, dynamic> deviceInfo = {};

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceInfo = _buildAndroidInfo(androidInfo);
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceInfo = _buildIOSInfo(iosInfo);
      } else {
        deviceInfo = _buildGenericInfo();
      }

      // Add common information
      deviceInfo.addAll(await _getCommonDeviceInfo());

      _cachedDeviceInfo = deviceInfo;
      _cacheTimestamp = DateTime.now();

      return deviceInfo;
    } catch (e) {
      return _buildFallbackInfo();
    }
  }

  // Android-specific information
  static Map<String, dynamic> _buildAndroidInfo(AndroidDeviceInfo androidInfo) {
    return {
      'platform': 'android',
      'brand': androidInfo.brand,
      'model': androidInfo.model,
      'device': androidInfo.device,
      'manufacturer': androidInfo.manufacturer,
      'product': androidInfo.product,
      'androidId': androidInfo.id,
      'androidVersion': {
        'release': androidInfo.version.release,
        'sdkInt': androidInfo.version.sdkInt,
        'incremental': androidInfo.version.incremental,
        'codename': androidInfo.version.codename,
        'baseOS': androidInfo.version.baseOS ?? '',
        'previewSdkInt': androidInfo.version.previewSdkInt ?? 0,
        'securityPatch': androidInfo.version.securityPatch ?? '',
      },
      'hardware': androidInfo.hardware,
      'bootloader': androidInfo.bootloader,
      'fingerprint': androidInfo.fingerprint,
      'host': androidInfo.host,
      'tags': androidInfo.tags,
      'type': androidInfo.type,
      'board': androidInfo.board,
      'display': androidInfo.display,
      'isPhysicalDevice': androidInfo.isPhysicalDevice,
      'systemFeatures': androidInfo.systemFeatures,
      'supportedAbis': androidInfo.supportedAbis,
      'supported32BitAbis': androidInfo.supported32BitAbis,
      'supported64BitAbis': androidInfo.supported64BitAbis,
    };
  }

  // iOS-specific information
  static Map<String, dynamic> _buildIOSInfo(IosDeviceInfo iosInfo) {
    return {
      'platform': 'ios',
      'name': iosInfo.name,
      'model': iosInfo.model,
      'localizedModel': iosInfo.localizedModel,
      'systemName': iosInfo.systemName,
      'systemVersion': iosInfo.systemVersion,
      'identifierForVendor': iosInfo.identifierForVendor ?? 'unknown',
      'isPhysicalDevice': iosInfo.isPhysicalDevice,
      'utsname': {
        'sysname': iosInfo.utsname.sysname,
        'nodename': iosInfo.utsname.nodename,
        'release': iosInfo.utsname.release,
        'version': iosInfo.utsname.version,
        'machine': iosInfo.utsname.machine,
      },
    };
  }

  // Generic platform information
  static Map<String, dynamic> _buildGenericInfo() {
    return {
      'platform': Platform.operatingSystem,
      'operatingSystemVersion': Platform.operatingSystemVersion,
      'localHostname': Platform.localHostname,
      'numberOfProcessors': Platform.numberOfProcessors,
      'pathSeparator': Platform.pathSeparator,
      'localeName': Platform.localeName,
    };
  }

  // Common device information across all platforms
  static Future<Map<String, dynamic>> _getCommonDeviceInfo() async {
    try {
      final view = PlatformDispatcher.instance.views.first;

      return {
        'screenInfo': {
          'size': {
            'width': view.physicalSize.width,
            'height': view.physicalSize.height,
          },
          'devicePixelRatio': view.devicePixelRatio,
          'logicalSize': {
            'width': view.physicalSize.width / view.devicePixelRatio,
            'height': view.physicalSize.height / view.devicePixelRatio,
          },
          'aspectRatio': view.physicalSize.width / view.physicalSize.height,
        },
        'locale': {
          'languageCode': PlatformDispatcher.instance.locale.languageCode,
          'countryCode': PlatformDispatcher.instance.locale.countryCode ?? '',
          'scriptCode': PlatformDispatcher.instance.locale.scriptCode ?? '',
          'toString': PlatformDispatcher.instance.locale.toString(),
        },
        'platformBrightness': PlatformDispatcher.instance.platformBrightness
            .toString(),
        'textScaleFactor': view.devicePixelRatio, // Approximation
        'alwaysUse24HourFormat':
            PlatformDispatcher.instance.alwaysUse24HourFormat,
        'accessibilityFeatures': {
          'accessibleNavigation': PlatformDispatcher
              .instance
              .accessibilityFeatures
              .accessibleNavigation,
          'boldText':
              PlatformDispatcher.instance.accessibilityFeatures.boldText,
          'disableAnimations': PlatformDispatcher
              .instance
              .accessibilityFeatures
              .disableAnimations,
          'highContrast':
              PlatformDispatcher.instance.accessibilityFeatures.highContrast,
          'invertColors':
              PlatformDispatcher.instance.accessibilityFeatures.invertColors,
          'reduceMotion':
              PlatformDispatcher.instance.accessibilityFeatures.reduceMotion,
        },
      };
    } catch (e) {
      return {
        'screenInfo': {
          'size': {'width': 0.0, 'height': 0.0},
          'devicePixelRatio': 1.0,
          'logicalSize': {'width': 0.0, 'height': 0.0},
          'aspectRatio': 1.0,
        },
        'locale': {
          'languageCode': 'en',
          'countryCode': 'US',
          'scriptCode': '',
          'toString': 'en_US',
        },
        'platformBrightness': 'light',
        'textScaleFactor': 1.0,
        'alwaysUse24HourFormat': false,
        'accessibilityFeatures': {
          'accessibleNavigation': false,
          'boldText': false,
          'disableAnimations': false,
          'highContrast': false,
          'invertColors': false,
          'reduceMotion': false,
        },
      };
    }
  }

  // Fallback information when device info cannot be retrieved
  static Map<String, dynamic> _buildFallbackInfo() {
    return {
      'platform': Platform.operatingSystem,
      'error': 'Unable to retrieve detailed device information',
      'fallback': true,
      'isPhysicalDevice': true,
    };
  }

  // App information
  static Future<Map<String, dynamic>> getAppInfo() async {
    if (_cachedAppInfo != null && _isCacheValid()) {
      return _cachedAppInfo!;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      _cachedAppInfo = {
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'buildSignature': packageInfo.buildSignature,
        'installerStore': packageInfo.installerStore ?? '',
      };

      return _cachedAppInfo!;
    } catch (e) {
      return {
        'error': 'Unable to retrieve app information',
        'exception': e.toString(),
        'appName': 'Receiptsly',
        'packageName': 'com.receiptsly.app',
        'version': '1.0.0',
        'buildNumber': '1',
      };
    }
  }

  // Network information
  static Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();

      return {
        'connectivityTypes': connectivityResults.map((e) => e.name).toList(),
        'isConnected':
            connectivityResults.isNotEmpty &&
            !connectivityResults.contains(ConnectivityResult.none),
        'hasWifi': connectivityResults.contains(ConnectivityResult.wifi),
        'hasMobile': connectivityResults.contains(ConnectivityResult.mobile),
        'hasEthernet': connectivityResults.contains(
          ConnectivityResult.ethernet,
        ),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Unable to retrieve network information',
        'exception': e.toString(),
        'isConnected': false,
        'connectivityTypes': <String>[],
      };
    }
  }

  // System information
  static Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final appInfo = await getAppInfo();
      final networkInfo = await getNetworkInfo();

      return {
        'device': deviceInfo,
        'app': appInfo,
        'network': networkInfo,
        'system': {
          'dartVersion': Platform.version,
          'operatingSystem': Platform.operatingSystem,
          'operatingSystemVersion': Platform.operatingSystemVersion,
          'localHostname': Platform.localHostname,
          'numberOfProcessors': Platform.numberOfProcessors,
          'pathSeparator': Platform.pathSeparator,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Unable to retrieve complete system information',
        'exception': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Device capabilities
  static Future<Map<String, dynamic>> getDeviceCapabilities() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final capabilities = <String, dynamic>{};

      // Screen capabilities
      capabilities['screen'] = _analyzeScreenCapabilities(deviceInfo);

      // Platform capabilities
      if (Platform.isAndroid) {
        capabilities['android'] = await _getAndroidCapabilities(deviceInfo);
      } else if (Platform.isIOS) {
        capabilities['ios'] = await _getIOSCapabilities(deviceInfo);
      }

      // General capabilities
      capabilities['general'] = await _getGeneralCapabilities();

      return capabilities;
    } catch (e) {
      return {
        'error': 'Unable to determine device capabilities',
        'exception': e.toString(),
      };
    }
  }

  static Map<String, dynamic> _analyzeScreenCapabilities(
    Map<String, dynamic> deviceInfo,
  ) {
    final screenInfo = deviceInfo['screenInfo'] as Map<String, dynamic>?;
    if (screenInfo == null) return {};

    final physicalSize = screenInfo['size'] as Map<String, dynamic>?;
    final logicalSize = screenInfo['logicalSize'] as Map<String, dynamic>?;

    if (physicalSize == null || logicalSize == null) return {};

    final width = logicalSize['width'] as double? ?? 0;
    final height = logicalSize['height'] as double? ?? 0;
    final aspectRatio = screenInfo['aspectRatio'] as double? ?? 1;

    return {
      'screenSize': _categorizeScreenSize(width, height),
      'aspectRatio': aspectRatio,
      'aspectRatioCategory': _categorizeAspectRatio(aspectRatio),
      'isTablet': _isTabletSize(width, height),
      'orientation': width > height ? 'landscape' : 'portrait',
      'pixelDensity': _categorizePixelDensity(
        screenInfo['devicePixelRatio'] as double? ?? 1,
      ),
    };
  }

  static Future<Map<String, dynamic>> _getAndroidCapabilities(
    Map<String, dynamic> deviceInfo,
  ) async {
    final androidVersion =
        deviceInfo['androidVersion'] as Map<String, dynamic>?;
    final sdkInt = androidVersion?['sdkInt'] as int? ?? 0;

    return {
      'apiLevel': sdkInt,
      'supportsScopedStorage': sdkInt >= 30,
      'supportsNotificationChannels': sdkInt >= 26,
      'supportsAdaptiveIcons': sdkInt >= 26,
      'supportsBiometrics': sdkInt >= 23,
      'supportsFileProvider': sdkInt >= 24,
      'supportsRuntimePermissions': sdkInt >= 23,
      'supportsCameraX': sdkInt >= 21,
      'supportsMLKit': sdkInt >= 19,
    };
  }

  static Future<Map<String, dynamic>> _getIOSCapabilities(
    Map<String, dynamic> deviceInfo,
  ) async {
    final systemVersion = deviceInfo['systemVersion'] as String? ?? '0.0';
    final versionParts = systemVersion.split('.');
    final majorVersion = int.tryParse(versionParts.first) ?? 0;

    return {
      'systemVersion': systemVersion,
      'majorVersion': majorVersion,
      'supportsWidgets': majorVersion >= 14,
      'supportsAppClips': majorVersion >= 14,
      'supportsSwiftUI': majorVersion >= 13,
      'supportsDarkMode': majorVersion >= 13,
      'supportsSignInWithApple': majorVersion >= 13,
      'supportsCameraCapture': majorVersion >= 10,
      'supportsMLKit': majorVersion >= 11,
      'supportsBiometrics': majorVersion >= 8,
    };
  }

  static Future<Map<String, dynamic>> _getGeneralCapabilities() async {
    return {
      'hasCamera': await _hasCamera(),
      'hasFlash': await _hasFlash(),
      'hasBiometrics': await _hasBiometrics(),
      'hasNFC': await _hasNFC(),
      'hasGPS': await _hasGPS(),
      'hasAccelerometer': await _hasAccelerometer(),
      'hasGyroscope': await _hasGyroscope(),
      'hasMagnetometer': await _hasMagnetometer(),
    };
  }

  // Hardware feature detection methods
  static Future<bool> _hasCamera() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.systemFeatures.contains('android.hardware.camera');
      }
      return true; // Assume iOS devices have cameras
    } catch (e) {
      return true; // Default to true
    }
  }

  static Future<bool> _hasFlash() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.systemFeatures.contains(
          'android.hardware.camera.flash',
        );
      }
      return true; // Assume iOS devices have flash
    } catch (e) {
      return true;
    }
  }

  static Future<bool> _hasBiometrics() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.systemFeatures.contains(
              'android.hardware.fingerprint',
            ) ||
            androidInfo.systemFeatures.contains('android.hardware.biometrics');
      }
      return true; // Most modern iOS devices support biometrics
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _hasNFC() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.systemFeatures.contains('android.hardware.nfc');
      }
      return false; // iOS NFC is limited
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _hasGPS() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.systemFeatures.contains(
          'android.hardware.location.gps',
        );
      }
      return true; // iOS devices typically have GPS
    } catch (e) {
      return true;
    }
  }

  static Future<bool> _hasAccelerometer() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.systemFeatures.contains(
          'android.hardware.sensor.accelerometer',
        );
      }
      return true; // iOS devices have accelerometers
    } catch (e) {
      return true;
    }
  }

  static Future<bool> _hasGyroscope() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.systemFeatures.contains(
          'android.hardware.sensor.gyroscope',
        );
      }
      return true; // Modern iOS devices have gyroscopes
    } catch (e) {
      return true;
    }
  }

  static Future<bool> _hasMagnetometer() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.systemFeatures.contains(
          'android.hardware.sensor.compass',
        );
      }
      return true; // iOS devices have magnetometers
    } catch (e) {
      return true;
    }
  }

  // Helper methods for screen analysis
  static String _categorizeScreenSize(double width, double height) {
    final diagonal = width > height ? width : height;

    if (diagonal < 480) return 'small';
    if (diagonal < 600) return 'normal';
    if (diagonal < 720) return 'large';
    if (diagonal < 960) return 'xlarge';
    return 'xxlarge';
  }

  static String _categorizeAspectRatio(double ratio) {
    if (ratio < 1.5) return 'square';
    if (ratio < 1.8) return 'standard';
    if (ratio < 2.0) return 'wide';
    return 'ultrawide';
  }

  static bool _isTabletSize(double width, double height) {
    final minDimension = width < height ? width : height;
    return minDimension >= 600; // Rough tablet threshold
  }

  static String _categorizePixelDensity(double pixelRatio) {
    if (pixelRatio < 1.5) return 'ldpi';
    if (pixelRatio < 2.0) return 'mdpi';
    if (pixelRatio < 3.0) return 'hdpi';
    if (pixelRatio < 4.0) return 'xhdpi';
    return 'xxhdpi';
  }

  // Performance and optimization helpers
  static Future<Map<String, dynamic>> getPerformanceInfo() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final performance = <String, dynamic>{};

      // Device performance category
      performance['category'] = _categorizeDevicePerformance(deviceInfo);

      // Memory and processing indicators
      performance['processorCount'] = Platform.numberOfProcessors;
      performance['isPhysicalDevice'] = deviceInfo['isPhysicalDevice'] ?? true;

      // Platform-specific performance indicators
      if (Platform.isAndroid) {
        final androidVersion =
            deviceInfo['androidVersion'] as Map<String, dynamic>?;
        final sdkInt = androidVersion?['sdkInt'] as int? ?? 0;

        performance['android'] = {
          'apiLevel': sdkInt,
          'supportsAOT': sdkInt >= 23, // Ahead-of-time compilation
          'supportsVulkan': sdkInt >= 24,
          'supports64Bit':
              (deviceInfo['supported64BitAbis'] as List?)?.isNotEmpty ?? false,
        };
      } else if (Platform.isIOS) {
        final systemVersion = deviceInfo['systemVersion'] as String? ?? '0.0';
        final majorVersion = int.tryParse(systemVersion.split('.').first) ?? 0;

        performance['ios'] = {
          'majorVersion': majorVersion,
          'supportsMetalAPI': majorVersion >= 8,
          'supportsNeuralEngine': majorVersion >= 11,
          'supports64Bit': majorVersion >= 7,
        };
      }

      // Screen performance factors
      final screenInfo = deviceInfo['screenInfo'] as Map<String, dynamic>?;
      if (screenInfo != null) {
        final devicePixelRatio =
            screenInfo['devicePixelRatio'] as double? ?? 1.0;
        final physicalSize = screenInfo['size'] as Map<String, dynamic>?;

        if (physicalSize != null) {
          final totalPixels =
              (physicalSize['width'] as double? ?? 0) *
              (physicalSize['height'] as double? ?? 0);

          performance['screen'] = {
            'pixelRatio': devicePixelRatio,
            'totalPixels': totalPixels,
            'pixelDensityCategory': _categorizePixelDensity(devicePixelRatio),
            'renderingLoad': _categorizeRenderingLoad(
              totalPixels,
              devicePixelRatio,
            ),
          };
        }
      }

      return performance;
    } catch (e) {
      return {
        'error': 'Unable to retrieve performance information',
        'exception': e.toString(),
        'category': 'unknown',
      };
    }
  }

  static String _categorizeDevicePerformance(Map<String, dynamic> deviceInfo) {
    if (Platform.isAndroid) {
      final androidVersion =
          deviceInfo['androidVersion'] as Map<String, dynamic>?;
      final sdkInt = androidVersion?['sdkInt'] as int? ?? 0;
      final isPhysical = deviceInfo['isPhysicalDevice'] as bool? ?? true;

      if (!isPhysical) return 'emulator';
      if (sdkInt >= 30) return 'high';
      if (sdkInt >= 26) return 'medium';
      return 'low';
    } else if (Platform.isIOS) {
      final systemVersion = deviceInfo['systemVersion'] as String? ?? '0.0';
      final majorVersion = int.tryParse(systemVersion.split('.').first) ?? 0;
      final isPhysical = deviceInfo['isPhysicalDevice'] as bool? ?? true;

      if (!isPhysical) return 'simulator';
      if (majorVersion >= 15) return 'high';
      if (majorVersion >= 12) return 'medium';
      return 'low';
    }

    return 'medium'; // Default for other platforms
  }

  static String _categorizeRenderingLoad(
    double totalPixels,
    double pixelRatio,
  ) {
    final effectivePixels = totalPixels * pixelRatio;

    if (effectivePixels < 2000000) return 'low'; // < 2M pixels
    if (effectivePixels < 8000000) return 'medium'; // < 8M pixels
    if (effectivePixels < 16000000) return 'high'; // < 16M pixels
    return 'ultra'; // >= 16M pixels
  }

  // Cache management
  static bool _isCacheValid() {
    if (_cachedDeviceInfo == null || _cacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    return now.difference(_cacheTimestamp!).inMilliseconds <
        _cacheValidDuration.inMilliseconds;
  }

  static void clearCache() {
    _cachedDeviceInfo = null;
    _cachedAppInfo = null;
    _cacheTimestamp = null;
  }

  static Future<void> warmupCache() async {
    try {
      await getDeviceInfo();
      await getAppInfo();
    } catch (e) {
      // Ignore errors during warmup
    }
  }

  // Utility methods
  static Future<String> generateDeviceFingerprint() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final appInfo = await getAppInfo();

      final fingerprintData = [
        deviceInfo['platform'],
        _getPlatformVersion(deviceInfo),
        deviceInfo['model'] ?? deviceInfo['name'],
        appInfo['packageName'],
        deviceInfo['screenInfo']?['size']?.toString(),
      ].where((element) => element != null).join('|');

      // Simple hash of the fingerprint data
      return fingerprintData.hashCode.abs().toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  static String _getPlatformVersion(Map<String, dynamic> deviceInfo) {
    if (Platform.isAndroid) {
      final androidVersion =
          deviceInfo['androidVersion'] as Map<String, dynamic>?;
      return androidVersion?['release'] ?? 'unknown';
    } else if (Platform.isIOS) {
      return deviceInfo['systemVersion'] ?? 'unknown';
    }
    return Platform.operatingSystemVersion;
  }

  static Future<bool> isDeviceSupported() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        return false;
      }

      final deviceInfo = await getDeviceInfo();

      if (Platform.isAndroid) {
        final androidVersion =
            deviceInfo['androidVersion'] as Map<String, dynamic>?;
        final sdkInt = androidVersion?['sdkInt'] as int? ?? 0;
        return sdkInt >= 21; // Minimum Android API level 21 (Android 5.0)
      } else if (Platform.isIOS) {
        final systemVersion = deviceInfo['systemVersion'] as String? ?? '0.0';
        final majorVersion = int.tryParse(systemVersion.split('.').first) ?? 0;
        return majorVersion >= 11; // Minimum iOS 11
      }

      return false;
    } catch (e) {
      return true; // Default to supported if we can't determine
    }
  }

  static Future<Map<String, String>> getDebugInfo() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final appInfo = await getAppInfo();

      return {
        'Platform': deviceInfo['platform'] ?? 'unknown',
        'OS Version': _getPlatformVersion(deviceInfo),
        'Device Model': deviceInfo['model'] ?? deviceInfo['name'] ?? 'unknown',
        'App Version': '${appInfo['version']} (${appInfo['buildNumber']})',
        'Device ID': _getDeviceId(deviceInfo),
        'Is Physical': (deviceInfo['isPhysicalDevice'] ?? true).toString(),
        'Dart Version': Platform.version,
        'Cache Valid': _isCacheValid().toString(),
      };
    } catch (e) {
      return {'Error': 'Failed to retrieve debug info: ${e.toString()}'};
    }
  }

  static String _getDeviceId(Map<String, dynamic> deviceInfo) {
    if (Platform.isAndroid) {
      return deviceInfo['androidId'] ?? 'unknown';
    } else if (Platform.isIOS) {
      return deviceInfo['identifierForVendor'] ?? 'unknown';
    }
    return 'unknown';
  }

  // Analytics and reporting helpers
  static Future<Map<String, dynamic>> getAnalyticsInfo() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final appInfo = await getAppInfo();
      final performanceInfo = await getPerformanceInfo();

      // Create anonymized analytics-safe information
      return {
        'platform': deviceInfo['platform'],
        'platformVersion': _getPlatformVersion(deviceInfo),
        'appVersion': appInfo['version'],
        'buildNumber': appInfo['buildNumber'],
        'deviceCategory': performanceInfo['category'],
        'screenCategory': performanceInfo['screen']?['pixelDensityCategory'],
        'isTablet': deviceInfo['screenInfo'] != null
            ? _isTabletFromScreenInfo(deviceInfo['screenInfo'])
            : false,
        'locale': deviceInfo['locale']?['languageCode'],
        'country': deviceInfo['locale']?['countryCode'],
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Unable to generate analytics information',
        'platform': Platform.operatingSystem,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  static bool _isTabletFromScreenInfo(Map<String, dynamic> screenInfo) {
    final logicalSize = screenInfo['logicalSize'] as Map<String, dynamic>?;
    if (logicalSize == null) return false;

    final width = logicalSize['width'] as double? ?? 0;
    final height = logicalSize['height'] as double? ?? 0;

    return _isTabletSize(width, height);
  }
}
