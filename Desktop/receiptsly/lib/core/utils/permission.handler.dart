// lib/core/utils/permission_handler.dart
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Comprehensive permission handler for Receiptsly app
/// Manages all app permissions with proper error handling and user guidance
// Permission status enum for better type safety
enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
  unknown,
}

class PermissionHandler {
  // Camera permissions
  static Future<PermissionResult> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<PermissionResult> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<bool> hasCameraPermission() async {
    final result = await checkCameraPermission();
    return result == PermissionResult.granted;
  }

  // Photo/Gallery permissions
  static Future<PermissionResult> requestPhotosPermission() async {
    try {
      Permission permission;

      if (Platform.isIOS) {
        permission = Permission.photos;
      } else {
        // Android 13+ uses granular permissions
        if (await _isAndroid13OrHigher()) {
          permission = Permission.photos;
        } else {
          permission = Permission.storage;
        }
      }

      final status = await permission.request();
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<PermissionResult> checkPhotosPermission() async {
    try {
      Permission permission;

      if (Platform.isIOS) {
        permission = Permission.photos;
      } else {
        if (await _isAndroid13OrHigher()) {
          permission = Permission.photos;
        } else {
          permission = Permission.storage;
        }
      }

      final status = await permission.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<bool> hasPhotosPermission() async {
    final result = await checkPhotosPermission();
    return result == PermissionResult.granted ||
        result == PermissionResult.limited;
  }

  // Storage permissions (Android)
  static Future<PermissionResult> requestStoragePermission() async {
    if (Platform.isIOS) {
      return PermissionResult
          .granted; // iOS doesn't need explicit storage permission
    }

    try {
      if (await _isAndroid13OrHigher()) {
        // Android 13+ uses granular media permissions
        final results = await [Permission.photos, Permission.videos].request();

        // Return granted if any permission is granted
        for (final status in results.values) {
          if (status.isGranted) {
            return PermissionResult.granted;
          }
        }

        return _mapPermissionStatus(results.values.first);
      } else {
        final status = await Permission.storage.request();
        return _mapPermissionStatus(status);
      }
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<PermissionResult> checkStoragePermission() async {
    if (Platform.isIOS) {
      return PermissionResult.granted;
    }

    try {
      if (await _isAndroid13OrHigher()) {
        final photosStatus = await Permission.photos.status;
        return _mapPermissionStatus(photosStatus);
      } else {
        final status = await Permission.storage.status;
        return _mapPermissionStatus(status);
      }
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<bool> hasStoragePermission() async {
    final result = await checkStoragePermission();
    return result == PermissionResult.granted ||
        result == PermissionResult.limited;
  }

  // Notification permissions
  static Future<PermissionResult> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<PermissionResult> checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<bool> hasNotificationPermission() async {
    final result = await checkNotificationPermission();
    return result == PermissionResult.granted ||
        result == PermissionResult.provisional;
  }

  // Microphone permissions (for future features)
  static Future<PermissionResult> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<PermissionResult> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<bool> hasMicrophonePermission() async {
    final result = await checkMicrophonePermission();
    return result == PermissionResult.granted;
  }

  // Location permissions (for business location features)
  static Future<PermissionResult> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<PermissionResult> checkLocationPermission() async {
    try {
      final status = await Permission.location.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<bool> hasLocationPermission() async {
    final result = await checkLocationPermission();
    return result == PermissionResult.granted;
  }

  static Future<PermissionResult> requestLocationWhenInUsePermission() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  // Contacts permissions (for client management)
  static Future<PermissionResult> requestContactsPermission() async {
    try {
      final status = await Permission.contacts.request();
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<PermissionResult> checkContactsPermission() async {
    try {
      final status = await Permission.contacts.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<bool> hasContactsPermission() async {
    final result = await checkContactsPermission();
    return result == PermissionResult.granted;
  }

  // Phone permissions (for WhatsApp integration)
  static Future<PermissionResult> requestPhonePermission() async {
    try {
      final status = await Permission.phone.request();
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<PermissionResult> checkPhonePermission() async {
    try {
      final status = await Permission.phone.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<bool> hasPhonePermission() async {
    final result = await checkPhonePermission();
    return result == PermissionResult.granted;
  }

  // SMS permissions (for verification)
  static Future<PermissionResult> requestSmsPermission() async {
    try {
      final status = await Permission.sms.request();
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<PermissionResult> checkSmsPermission() async {
    try {
      final status = await Permission.sms.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<bool> hasSmsPermission() async {
    final result = await checkSmsPermission();
    return result == PermissionResult.granted;
  }

  // Calendar permissions (for invoice scheduling)
  static Future<PermissionResult> requestCalendarPermission() async {
    try {
      final status = await Permission.calendar.request();
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<PermissionResult> checkCalendarPermission() async {
    try {
      final status = await Permission.calendar.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  static Future<bool> hasCalendarPermission() async {
    final result = await checkCalendarPermission();
    return result == PermissionResult.granted;
  }

  // Multiple permission requests
  static Future<Map<String, PermissionResult>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    try {
      final results = await permissions.request();
      final mappedResults = <String, PermissionResult>{};

      for (final entry in results.entries) {
        mappedResults[entry.key.toString()] = _mapPermissionStatus(entry.value);
      }

      return mappedResults;
    } catch (e) {
      final errorResults = <String, PermissionResult>{};
      for (final permission in permissions) {
        errorResults[permission.toString()] = PermissionResult.unknown;
      }
      return errorResults;
    }
  }

  static Future<Map<String, PermissionResult>> checkMultiplePermissions(
    List<Permission> permissions,
  ) async {
    try {
      final results = <String, PermissionResult>{};

      for (final permission in permissions) {
        final status = await permission.status;
        results[permission.toString()] = _mapPermissionStatus(status);
      }

      return results;
    } catch (e) {
      final errorResults = <String, PermissionResult>{};
      for (final permission in permissions) {
        errorResults[permission.toString()] = PermissionResult.unknown;
      }
      return errorResults;
    }
  }

  // Essential permissions for the app
  static Future<Map<String, PermissionResult>>
  requestEssentialPermissions() async {
    final permissions = <Permission>[
      Permission.camera,
      Permission.notification,
    ];

    // Add platform-specific permissions
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        permissions.add(Permission.photos);
      } else {
        permissions.add(Permission.storage);
      }
    } else {
      permissions.add(Permission.photos);
    }

    return await requestMultiplePermissions(permissions);
  }

  static Future<bool> hasAllEssentialPermissions() async {
    final cameraPermission = await hasCameraPermission();
    final photosPermission = await hasPhotosPermission();
    final notificationPermission = await hasNotificationPermission();

    return cameraPermission && photosPermission && notificationPermission;
  }

  // Permission status helpers
  static Future<bool> isPermissionPermanentlyDenied(
    Permission permission,
  ) async {
    try {
      final status = await permission.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> shouldShowPermissionRationale(
    Permission permission,
  ) async {
    try {
      if (Platform.isAndroid) {
        final status = await permission.status;
        return status.isDenied && !status.isPermanentlyDenied;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Settings navigation
  static Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      return false;
    }
  }

  static Future<bool> openPermissionSettings() async {
    try {
      if (Platform.isAndroid) {
        return await openAppSettings();
      } else {
        return await openAppSettings();
      }
    } catch (e) {
      return false;
    }
  }

  // Permission request with rationale
  static Future<PermissionResult> requestPermissionWithRationale(
    Permission permission,
    String rationale, {
    Function? onShowRationale,
  }) async {
    try {
      // Check current status
      final currentStatus = await permission.status;

      if (currentStatus.isGranted) {
        return PermissionResult.granted;
      }

      // Show rationale if needed
      if (Platform.isAndroid &&
          currentStatus.isDenied &&
          !currentStatus.isPermanentlyDenied) {
        if (onShowRationale != null) {
          await onShowRationale();
        }
      }

      // Request permission
      final status = await permission.request();
      return _mapPermissionStatus(status);
    } catch (e) {
      return PermissionResult.unknown;
    }
  }

  // Batch permission operations
  static Future<List<Permission>> getMissingPermissions(
    List<Permission> permissions,
  ) async {
    final missing = <Permission>[];

    try {
      for (final permission in permissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          missing.add(permission);
        }
      }
    } catch (e) {
      return permissions; // Return all if error occurred
    }

    return missing;
  }

  static Future<List<Permission>> getPermanentlyDeniedPermissions(
    List<Permission> permissions,
  ) async {
    final permanentlyDenied = <Permission>[];

    try {
      for (final permission in permissions) {
        final status = await permission.status;
        if (status.isPermanentlyDenied) {
          permanentlyDenied.add(permission);
        }
      }
    } catch (e) {
      return [];
    }

    return permanentlyDenied;
  }

  // Feature-specific permission checks
  static Future<bool> canCaptureReceipts() async {
    final cameraPermission = await hasCameraPermission();
    final storagePermission = await hasStoragePermission();

    return cameraPermission && storagePermission;
  }

  static Future<bool> canAccessGallery() async {
    return await hasPhotosPermission();
  }

  static Future<bool> canSendNotifications() async {
    return await hasNotificationPermission();
  }

  static Future<bool> canAccessLocation() async {
    return await hasLocationPermission();
  }

  static Future<bool> canAccessContacts() async {
    return await hasContactsPermission();
  }

  // Permission descriptions for user education
  static String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera access is needed to capture receipt photos quickly and efficiently.';
      case Permission.photos:
        return 'Photo library access allows you to select existing receipt images from your gallery.';
      case Permission.storage:
        return 'Storage access is required to save and manage your receipt images locally.';
      case Permission.notification:
        return 'Notifications help you stay updated on invoice due dates and payment reminders.';
      case Permission.microphone:
        return 'Microphone access enables voice notes and audio recording features.';
      case Permission.location:
        return 'Location access helps automatically tag business locations on receipts.';
      case Permission.locationWhenInUse:
        return 'Location access when using the app helps tag business locations on receipts.';
      case Permission.contacts:
        return 'Contacts access allows you to easily select clients when creating invoices.';
      case Permission.phone:
        return 'Phone access enables direct calling and WhatsApp integration features.';
      case Permission.sms:
        return 'SMS access is used for phone number verification and two-factor authentication.';
      case Permission.calendar:
        return 'Calendar access helps schedule invoice due dates and payment reminders.';
      default:
        return 'This permission is required for the app to function properly.';
    }
  }

  static String getPermissionRationale(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'To capture receipt photos, Receiptsly needs access to your camera. This allows you to quickly snap photos of your business receipts for expense tracking.';
      case Permission.photos:
        return 'Access to your photo library lets you import existing receipt images into Receiptsly for expense management.';
      case Permission.storage:
        return 'Storage permission allows Receiptsly to save receipt images locally and work offline when needed.';
      case Permission.notification:
        return 'Notifications keep you informed about important events like invoice due dates, payment reminders, and sync status updates.';
      case Permission.location:
        return 'Location services help automatically tag where expenses occurred, making your receipt tracking more organized and useful for business purposes.';
      case Permission.contacts:
        return 'Contact access streamlines invoice creation by letting you quickly select clients from your address book.';
      default:
        return 'This permission helps Receiptsly provide you with the best possible experience for managing your business finances.';
    }
  }

  // Permission grouping for UI presentation
  static Map<String, List<Permission>> getPermissionGroups() {
    return {
      'Essential': [
        Permission.camera,
        Platform.isIOS ? Permission.photos : Permission.storage,
        Permission.notification,
      ],
      'Enhanced Features': [
        Permission.location,
        Permission.contacts,
        Permission.microphone,
      ],
      'Communication': [Permission.phone, Permission.sms],
      'Productivity': [Permission.calendar],
    };
  }

  static List<Permission> getGroupPermissions(String groupName) {
    final groups = getPermissionGroups();
    return groups[groupName] ?? [];
  }

  // Permission workflow helpers
  static Future<Map<String, dynamic>> getPermissionWorkflowStatus() async {
    final essential = await checkMultiplePermissions(
      getGroupPermissions('Essential'),
    );
    final enhanced = await checkMultiplePermissions(
      getGroupPermissions('Enhanced Features'),
    );
    final communication = await checkMultiplePermissions(
      getGroupPermissions('Communication'),
    );
    final productivity = await checkMultiplePermissions(
      getGroupPermissions('Productivity'),
    );

    final essentialGranted = essential.values.every(
      (status) =>
          status == PermissionResult.granted ||
          status == PermissionResult.limited,
    );

    final enhancedGranted = enhanced.values
        .where((status) => status == PermissionResult.granted)
        .length;

    final communicationGranted = communication.values
        .where((status) => status == PermissionResult.granted)
        .length;

    final productivityGranted = productivity.values
        .where((status) => status == PermissionResult.granted)
        .length;

    return {
      'essential': {
        'permissions': essential,
        'allGranted': essentialGranted,
        'count': essential.length,
        'grantedCount': essential.values
            .where(
              (status) =>
                  status == PermissionResult.granted ||
                  status == PermissionResult.limited,
            )
            .length,
      },
      'enhanced': {
        'permissions': enhanced,
        'count': enhanced.length,
        'grantedCount': enhancedGranted,
      },
      'communication': {
        'permissions': communication,
        'count': communication.length,
        'grantedCount': communicationGranted,
      },
      'productivity': {
        'permissions': productivity,
        'count': productivity.length,
        'grantedCount': productivityGranted,
      },
      'canUseApp': essentialGranted,
      'completionPercentage': _calculateCompletionPercentage(
        essential.length +
            enhanced.length +
            communication.length +
            productivity.length,
        essential.values.where((s) => s == PermissionResult.granted).length +
            enhancedGranted +
            communicationGranted +
            productivityGranted,
      ),
    };
  }

  static double _calculateCompletionPercentage(int total, int granted) {
    if (total == 0) return 0.0;
    return (granted / total * 100).clamp(0.0, 100.0);
  }

  // Permission timing and scheduling
  static Future<bool> shouldRequestPermissionsOnLaunch() async {
    final essential = await checkMultiplePermissions(
      getGroupPermissions('Essential'),
    );

    // Request on launch if any essential permission is not granted
    return essential.values.any(
      (status) =>
          status != PermissionResult.granted &&
          status != PermissionResult.limited,
    );
  }

  static Future<List<Permission>> getPermissionsToRequestOnFeatureUse() async {
    final permissions = <Permission>[];

    // Only suggest enhanced permissions when user tries to use related features
    final enhanced = getGroupPermissions('Enhanced Features');
    for (final permission in enhanced) {
      final status = await permission.status;
      if (!status.isGranted && !status.isPermanentlyDenied) {
        permissions.add(permission);
      }
    }

    return permissions;
  }

  // Recovery and troubleshooting
  static Future<Map<String, dynamic>> diagnosePermissionIssues() async {
    final issues = <String, dynamic>{};
    final recommendations = <String>[];

    // Check for permanently denied permissions
    final essential = getGroupPermissions('Essential');
    final permanentlyDenied = await getPermanentlyDeniedPermissions(essential);

    if (permanentlyDenied.isNotEmpty) {
      issues['permanentlyDenied'] = permanentlyDenied
          .map((p) => p.toString())
          .toList();
      recommendations.add(
        'Some essential permissions are permanently denied. Please enable them in Settings.',
      );
    }

    // Check camera specifically
    if (!await hasCameraPermission()) {
      issues['cameraIssue'] = true;
      recommendations.add(
        'Camera permission is required to capture receipt photos.',
      );
    }

    // Check storage/photos
    if (!await hasPhotosPermission()) {
      issues['storageIssue'] = true;
      recommendations.add(
        'Photo library access is needed to select and save receipt images.',
      );
    }

    // Check notification status
    if (!await hasNotificationPermission()) {
      issues['notificationIssue'] = true;
      recommendations.add(
        'Enable notifications to receive important reminders and updates.',
      );
    }

    issues['canRecover'] = permanentlyDenied.isEmpty;
    issues['recommendations'] = recommendations;
    issues['needsSettingsNavigation'] = permanentlyDenied.isNotEmpty;

    return issues;
  }

  // Utility functions
  static PermissionResult _mapPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return PermissionResult.granted;
      case PermissionStatus.denied:
        return PermissionResult.denied;
      case PermissionStatus.permanentlyDenied:
        return PermissionResult.permanentlyDenied;
      case PermissionStatus.restricted:
        return PermissionResult.restricted;
      case PermissionStatus.limited:
        return PermissionResult.limited;
      case PermissionStatus.provisional:
        return PermissionResult.provisional;
      default:
        return PermissionResult.unknown;
    }
  }

  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    try {
      // Check Android API level - simplified approach
      // In a real implementation, you would use device_info_plus
      return Platform.version.contains('13') ||
          Platform.version.contains('14') ||
          Platform.version.contains('15');
    } catch (e) {
      return false;
    }
  }

  // Platform-specific helpers
  static Future<Map<String, dynamic>>
  getPlatformSpecificPermissionInfo() async {
    final info = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'isAndroid': Platform.isAndroid,
      'isIOS': Platform.isIOS,
    };

    if (Platform.isAndroid) {
      info['usesScopedStorage'] = await _isAndroid13OrHigher();
      info['requiresManageExternalStorage'] =
          false; // For this app, we don't need broad storage access
    }

    if (Platform.isIOS) {
      // iOS specific permission features
      info['supportsLimitedPhotoLibrary'] = true;
      info['supportsProvisionalNotifications'] = true;
    }

    return info;
  }

  // Logging and analytics helpers
  static Map<String, dynamic> getPermissionAnalytics(
    Map<String, PermissionResult> permissions,
  ) {
    final granted = permissions.values
        .where(
          (status) =>
              status == PermissionResult.granted ||
              status == PermissionResult.limited,
        )
        .length;

    final denied = permissions.values
        .where((status) => status == PermissionResult.denied)
        .length;

    final permanentlyDenied = permissions.values
        .where((status) => status == PermissionResult.permanentlyDenied)
        .length;

    return {
      'total': permissions.length,
      'granted': granted,
      'denied': denied,
      'permanentlyDenied': permanentlyDenied,
      'grantRate': permissions.isNotEmpty
          ? (granted / permissions.length * 100).round()
          : 0,
      'permissions': permissions.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    };
  }

  // Feature availability based on permissions
  static Future<Map<String, bool>> getFeatureAvailability() async {
    return {
      'receiptCapture': await canCaptureReceipts(),
      'galleryImport': await canAccessGallery(),
      'notifications': await canSendNotifications(),
      'locationTagging': await canAccessLocation(),
      'contactIntegration': await canAccessContacts(),
      'fullFunctionality': await hasAllEssentialPermissions(),
    };
  }

  // Permission request strategies
  static Future<PermissionResult> requestPermissionWithStrategy(
    Permission permission, {
    bool showRationale = true,
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int retries = 0;

    while (retries < maxRetries) {
      try {
        // Check if already granted
        final currentStatus = await permission.status;
        if (currentStatus.isGranted) {
          return PermissionResult.granted;
        }

        // Don't retry if permanently denied
        if (currentStatus.isPermanentlyDenied) {
          return PermissionResult.permanentlyDenied;
        }

        // Request permission
        final status = await permission.request();
        final result = _mapPermissionStatus(status);

        if (result == PermissionResult.granted ||
            result == PermissionResult.permanentlyDenied) {
          return result;
        }

        retries++;
        if (retries < maxRetries) {
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          return PermissionResult.unknown;
        }
        await Future.delayed(retryDelay);
      }
    }

    return PermissionResult.denied;
  }

  // Helper method to handle permission request results
  static String getPermissionResultMessage(PermissionResult result) {
    switch (result) {
      case PermissionResult.granted:
        return 'Permission granted successfully';
      case PermissionResult.denied:
        return 'Permission denied. Please try again.';
      case PermissionResult.permanentlyDenied:
        return 'Permission permanently denied. Please enable it in Settings.';
      case PermissionResult.restricted:
        return 'Permission is restricted on this device';
      case PermissionResult.limited:
        return 'Limited permission granted';
      case PermissionResult.provisional:
        return 'Provisional permission granted';
      case PermissionResult.unknown:
        return 'Unable to determine permission status';
    }
  }

  // Debug helpers
  static Future<Map<String, String>> getDebugPermissionInfo() async {
    final debugInfo = <String, String>{};

    final allPermissions = [
      Permission.camera,
      Permission.photos,
      Permission.storage,
      Permission.notification,
      Permission.location,
      Permission.contacts,
      Permission.microphone,
      Permission.phone,
      Permission.sms,
      Permission.calendar,
    ];

    for (final permission in allPermissions) {
      try {
        final status = await permission.status;
        debugInfo[permission.toString()] = status.toString();
      } catch (e) {
        debugInfo[permission.toString()] = 'Error: ${e.toString()}';
      }
    }

    return debugInfo;
  }
}
