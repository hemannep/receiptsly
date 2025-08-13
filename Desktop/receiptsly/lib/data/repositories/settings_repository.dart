// lib/data/repositories/settings_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/models/settings/settings_model.dart';
import '../../domain/datasources/remote/firebase/user_remote_datasource.dart';
import '../../services/sync/sync_service.dart';

class SettingsRepository implements ISettingsRepository {
  final SharedPreferences _preferences;
  final FlutterSecureStorage _secureStorage;
  final UserRemoteDatasource _userRemoteDatasource;
  final SyncService _syncService;
  final Connectivity _connectivity;

  static const String _settingsKey = 'app_settings';
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';
  static const String _currencyKey = 'default_currency';
  static const String _categoryKey = 'default_category';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _autoSyncKey = 'auto_sync_enabled';
  static const String _offlineModeKey = 'offline_mode_enabled';
  static const String _biometricKey = 'biometric_enabled';
  static const String _dataBackupKey = 'data_backup_enabled';
  static const String _syncIntervalKey = 'sync_interval_minutes';
  static const String _receiptQualityKey = 'receipt_image_quality';
  static const String _exportFormatKey = 'default_export_format';
  static const String _invoiceTemplateKey = 'default_invoice_template';
  static const String _taxSettingsKey = 'tax_settings';
  static const String _businessInfoKey = 'business_info';
  static const String _chatIntegrationsKey = 'chat_integrations';

  SettingsRepository({
    required SharedPreferences preferences,
    required FlutterSecureStorage secureStorage,
    required UserRemoteDatasource userRemoteDatasource,
    required SyncService syncService,
    required Connectivity connectivity,
  }) : _preferences = preferences,
       _secureStorage = secureStorage,
       _userRemoteDatasource = userRemoteDatasource,
       _syncService = syncService,
       _connectivity = connectivity;

  @override
  Future<Either<Failure, SettingsEntity>> getSettings() async {
    try {
      final settingsJson = _preferences.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson);
        final settings = SettingsModel.fromJson(settingsMap);
        return Right(settings.toEntity());
      } else {
        // Return default settings
        final defaultSettings = _getDefaultSettings();
        await _saveSettings(defaultSettings);
        return Right(defaultSettings.toEntity());
      }
    } catch (e) {
      return Left(DatabaseFailure('Failed to get settings: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateSettings(SettingsEntity settings) async {
    try {
      final settingsModel = SettingsModel.fromEntity(settings);
      await _saveSettings(settingsModel);

      // Sync to remote if connected
      await _syncSettingsToRemote(settingsModel);

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to update settings: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> getThemeMode() async {
    try {
      final theme = _preferences.getString(_themeKey) ?? 'system';
      return Right(theme);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get theme mode: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> setThemeMode(String themeMode) async {
    try {
      await _preferences.setString(_themeKey, themeMode);
      await _updateSettingsField('theme', themeMode);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to set theme mode: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> getLanguage() async {
    try {
      final language = _preferences.getString(_languageKey) ?? 'en';
      return Right(language);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get language: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> setLanguage(String languageCode) async {
    try {
      await _preferences.setString(_languageKey, languageCode);
      await _updateSettingsField('language', languageCode);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to set language: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> getDefaultCurrency() async {
    try {
      final currency = _preferences.getString(_currencyKey) ?? 'USD';
      return Right(currency);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get default currency: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultCurrency(String currency) async {
    try {
      await _preferences.setString(_currencyKey, currency);
      await _updateSettingsField('defaultCurrency', currency);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set default currency: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> getDefaultCategory() async {
    try {
      final category = _preferences.getString(_categoryKey) ?? 'General';
      return Right(category);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get default category: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultCategory(String category) async {
    try {
      await _preferences.setString(_categoryKey, category);
      await _updateSettingsField('defaultCategory', category);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set default category: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> isNotificationsEnabled() async {
    try {
      final enabled = _preferences.getBool(_notificationsKey) ?? true;
      return Right(enabled);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get notifications setting: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setNotificationsEnabled(bool enabled) async {
    try {
      await _preferences.setBool(_notificationsKey, enabled);
      await _updateSettingsField('notificationsEnabled', enabled);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set notifications: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> isAutoSyncEnabled() async {
    try {
      final enabled = _preferences.getBool(_autoSyncKey) ?? true;
      return Right(enabled);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get auto sync setting: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setAutoSyncEnabled(bool enabled) async {
    try {
      await _preferences.setBool(_autoSyncKey, enabled);
      await _updateSettingsField('autoSyncEnabled', enabled);

      // Update sync service
      await _syncService.setAutoSyncEnabled(enabled);

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to set auto sync: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isOfflineModeEnabled() async {
    try {
      final enabled = _preferences.getBool(_offlineModeKey) ?? true;
      return Right(enabled);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get offline mode setting: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setOfflineModeEnabled(bool enabled) async {
    try {
      await _preferences.setBool(_offlineModeKey, enabled);
      await _updateSettingsField('offlineModeEnabled', enabled);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set offline mode: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> isBiometricEnabled() async {
    try {
      final biometricData = await _secureStorage.read(key: _biometricKey);
      final enabled = biometricData == 'true';
      return Right(enabled);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get biometric setting: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.write(key: _biometricKey, value: enabled.toString());
      await _updateSettingsField('biometricEnabled', enabled);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to set biometric: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isDataBackupEnabled() async {
    try {
      final enabled = _preferences.getBool(_dataBackupKey) ?? true;
      return Right(enabled);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get data backup setting: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setDataBackupEnabled(bool enabled) async {
    try {
      await _preferences.setBool(_dataBackupKey, enabled);
      await _updateSettingsField('dataBackupEnabled', enabled);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set data backup: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getSyncInterval() async {
    try {
      final interval =
          _preferences.getInt(_syncIntervalKey) ?? 30; // Default 30 minutes
      return Right(interval);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get sync interval: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setSyncInterval(int intervalMinutes) async {
    try {
      await _preferences.setInt(_syncIntervalKey, intervalMinutes);
      await _updateSettingsField('syncIntervalMinutes', intervalMinutes);

      // Update sync service
      await _syncService.setSyncInterval(Duration(minutes: intervalMinutes));

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set sync interval: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> getReceiptImageQuality() async {
    try {
      final quality = _preferences.getString(_receiptQualityKey) ?? 'high';
      return Right(quality);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get receipt quality: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setReceiptImageQuality(String quality) async {
    try {
      await _preferences.setString(_receiptQualityKey, quality);
      await _updateSettingsField('receiptImageQuality', quality);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set receipt quality: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> getDefaultExportFormat() async {
    try {
      final format = _preferences.getString(_exportFormatKey) ?? 'pdf';
      return Right(format);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get export format: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultExportFormat(String format) async {
    try {
      await _preferences.setString(_exportFormatKey, format);
      await _updateSettingsField('defaultExportFormat', format);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set export format: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> getDefaultInvoiceTemplate() async {
    try {
      final template = _preferences.getString(_invoiceTemplateKey) ?? 'default';
      return Right(template);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get invoice template: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultInvoiceTemplate(
    String template,
  ) async {
    try {
      await _preferences.setString(_invoiceTemplateKey, template);
      await _updateSettingsField('defaultInvoiceTemplate', template);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set invoice template: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTaxSettings() async {
    try {
      final taxSettingsJson = _preferences.getString(_taxSettingsKey);
      if (taxSettingsJson != null) {
        final taxSettings = jsonDecode(taxSettingsJson);
        return Right(Map<String, dynamic>.from(taxSettings));
      } else {
        final defaultTaxSettings = _getDefaultTaxSettings();
        await _preferences.setString(
          _taxSettingsKey,
          jsonEncode(defaultTaxSettings),
        );
        return Right(defaultTaxSettings);
      }
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get tax settings: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setTaxSettings(
    Map<String, dynamic> taxSettings,
  ) async {
    try {
      await _preferences.setString(_taxSettingsKey, jsonEncode(taxSettings));
      await _updateSettingsField('taxSettings', taxSettings);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set tax settings: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getBusinessInfo() async {
    try {
      final businessInfoJson = _preferences.getString(_businessInfoKey);
      if (businessInfoJson != null) {
        final businessInfo = jsonDecode(businessInfoJson);
        return Right(Map<String, dynamic>.from(businessInfo));
      } else {
        final defaultBusinessInfo = _getDefaultBusinessInfo();
        await _preferences.setString(
          _businessInfoKey,
          jsonEncode(defaultBusinessInfo),
        );
        return Right(defaultBusinessInfo);
      }
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get business info: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setBusinessInfo(
    Map<String, dynamic> businessInfo,
  ) async {
    try {
      await _preferences.setString(_businessInfoKey, jsonEncode(businessInfo));
      await _updateSettingsField('businessInfo', businessInfo);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set business info: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getChatIntegrations() async {
    try {
      final integrationsJson = _preferences.getString(_chatIntegrationsKey);
      if (integrationsJson != null) {
        final integrations = jsonDecode(integrationsJson);
        return Right(Map<String, dynamic>.from(integrations));
      } else {
        final defaultIntegrations = _getDefaultChatIntegrations();
        await _preferences.setString(
          _chatIntegrationsKey,
          jsonEncode(defaultIntegrations),
        );
        return Right(defaultIntegrations);
      }
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get chat integrations: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> setChatIntegrations(
    Map<String, dynamic> integrations,
  ) async {
    try {
      await _preferences.setString(
        _chatIntegrationsKey,
        jsonEncode(integrations),
      );
      await _updateSettingsField('chatIntegrations', integrations);
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to set chat integrations: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> resetSettings() async {
    try {
      // Clear all preferences
      await _preferences.clear();

      // Clear secure storage
      await _secureStorage.deleteAll();

      // Set default settings
      final defaultSettings = _getDefaultSettings();
      await _saveSettings(defaultSettings);

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to reset settings: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> exportSettings() async {
    try {
      final settings = await getSettings();
      return settings.fold((failure) => Left(failure), (settingsEntity) {
        final exportData = {
          'settings': SettingsModel.fromEntity(settingsEntity).toJson(),
          'exportedAt': DateTime.now().toIso8601String(),
          'version': '1.0',
        };
        return Right(exportData);
      });
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to export settings: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> importSettings(
    Map<String, dynamic> settingsData,
  ) async {
    try {
      if (settingsData['settings'] == null) {
        return Left(ValidationFailure('Invalid settings data'));
      }

      final settingsModel = SettingsModel.fromJson(settingsData['settings']);
      await _saveSettings(settingsModel);

      // Sync to remote
      await _syncSettingsToRemote(settingsModel);

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to import settings: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> syncSettings({String? userId}) async {
    try {
      if (userId == null) {
        return Left(ValidationFailure('User ID is required for settings sync'));
      }

      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return Left(NetworkFailure('No internet connection'));
      }

      // Get local settings
      final localSettings = await getSettings();

      return localSettings.fold((failure) => Left(failure), (settings) async {
        try {
          // Sync to remote
          await _userRemoteDatasource.updateUserSettings(
            userId,
            SettingsModel.fromEntity(settings).toJson(),
          );

          return const Right(null);
        } catch (e) {
          return Left(
            NetworkFailure('Failed to sync settings: ${e.toString()}'),
          );
        }
      });
    } catch (e) {
      return Left(DatabaseFailure('Failed to sync settings: ${e.toString()}'));
    }
  }

  @override
  Stream<SettingsEntity> watchSettings() {
    // Since SharedPreferences doesn't have a watch mechanism,
    // we'll create a periodic stream that checks for changes
    return Stream.periodic(const Duration(seconds: 1), (_) async {
      final result = await getSettings();
      return result.fold(
        (failure) => _getDefaultSettings().toEntity(),
        (settings) => settings,
      );
    }).asyncMap((future) => future);
  }

  // Private helper methods
  Future<void> _saveSettings(SettingsModel settings) async {
    final settingsJson = jsonEncode(settings.toJson());
    await _preferences.setString(_settingsKey, settingsJson);
  }

  Future<void> _updateSettingsField(String field, dynamic value) async {
    try {
      final currentSettings = await getSettings();
      currentSettings.fold(
        (failure) => throw Exception('Failed to get current settings'),
        (settings) async {
          final settingsModel = SettingsModel.fromEntity(settings);
          final updatedModel = settingsModel.copyWith(
            updatedAt: DateTime.now(),
          );

          await _saveSettings(updatedModel);
          await _syncSettingsToRemote(updatedModel);
        },
      );
    } catch (e) {
      // Log error but don't throw to prevent settings update from failing
      print('Failed to update settings field $field: $e');
    }
  }

  Future<void> _syncSettingsToRemote(SettingsModel settings) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Add to sync queue for background sync
        await _syncService.addToSyncQueue(
          action: 'UPDATE',
          collection: 'users',
          documentId: 'current_user', // Will be replaced with actual user ID
          data: {'settings': settings.toJson()},
        );
      }
    } catch (e) {
      // Log error but don't throw
      print('Failed to sync settings to remote: $e');
    }
  }

  SettingsModel _getDefaultSettings() {
    return SettingsModel(
      theme: 'system',
      language: 'en',
      defaultCurrency: 'USD',
      defaultCategory: 'General',
      notificationsEnabled: true,
      autoSyncEnabled: true,
      offlineModeEnabled: true,
      biometricEnabled: false,
      dataBackupEnabled: true,
      receiptImageQuality: 'high',
      defaultExportFormat: 'pdf',
      defaultInvoiceTemplate: 'default',
      taxSettings: _getDefaultTaxSettings(),
      businessInfo: _getDefaultBusinessInfo(),
      chatIntegrations: _getDefaultChatIntegrations(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _getDefaultTaxSettings() {
    return {
      'defaultTaxRate': 0.0,
      'taxIncluded': false,
      'taxNumber': '',
      'taxRegion': '',
      'autoCalculateTax': true,
      'taxCategories': [
        {'name': 'Standard', 'rate': 0.0},
        {'name': 'Reduced', 'rate': 0.0},
        {'name': 'Exempt', 'rate': 0.0},
      ],
    };
  }

  Map<String, dynamic> _getDefaultBusinessInfo() {
    return {
      'businessName': '',
      'businessType': 'freelancer',
      'ownerName': '',
      'email': '',
      'phone': '',
      'website': '',
      'address': {
        'street': '',
        'city': '',
        'state': '',
        'zipCode': '',
        'country': '',
      },
      'logo': '',
      'taxId': '',
      'registrationNumber': '',
      'bankDetails': {
        'bankName': '',
        'accountNumber': '',
        'routingNumber': '',
        'iban': '',
        'swift': '',
      },
    };
  }

  Map<String, dynamic> _getDefaultChatIntegrations() {
    return {
      'whatsapp': {
        'enabled': false,
        'phoneNumber': '',
        'qrCode': '',
        'connectionStatus': 'disconnected',
        'lastConnected': null,
      },
      'telegram': {
        'enabled': false,
        'botToken': '',
        'chatId': '',
        'connectionStatus': 'disconnected',
        'lastConnected': null,
      },
      'slack': {
        'enabled': false,
        'workspaceId': '',
        'channelId': '',
        'webhookUrl': '',
        'connectionStatus': 'disconnected',
        'lastConnected': null,
      },
    };
  }
}

// Settings Model
class SettingsModel {
  final String theme;
  final String language;
  final String defaultCurrency;
  final String defaultCategory;
  final bool notificationsEnabled;
  final bool autoSyncEnabled;
  final bool offlineModeEnabled;
  final bool biometricEnabled;
  final bool dataBackupEnabled;
  final int syncIntervalMinutes;
  final String receiptImageQuality;
  final String defaultExportFormat;
  final String defaultInvoiceTemplate;
  final Map<String, dynamic> taxSettings;
  final Map<String, dynamic> businessInfo;
  final Map<String, dynamic> chatIntegrations;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SettingsModel({
    required this.theme,
    required this.language,
    required this.defaultCurrency,
    required this.defaultCategory,
    required this.notificationsEnabled,
    required this.autoSyncEnabled,
    required this.offlineModeEnabled,
    required this.biometricEnabled,
    required this.dataBackupEnabled,
    required this.syncIntervalMinutes,
    required this.receiptImageQuality,
    required this.defaultExportFormat,
    required this.defaultInvoiceTemplate,
    required this.taxSettings,
    required this.businessInfo,
    required this.chatIntegrations,
    required this.createdAt,
    required this.updatedAt,
  });

  SettingsModel copyWith({
    String? theme,
    String? language,
    String? defaultCurrency,
    String? defaultCategory,
    bool? notificationsEnabled,
    bool? autoSyncEnabled,
    bool? offlineModeEnabled,
    bool? biometricEnabled,
    bool? dataBackupEnabled,
    int? syncIntervalMinutes,
    String? receiptImageQuality,
    String? defaultExportFormat,
    String? defaultInvoiceTemplate,
    Map<String, dynamic>? taxSettings,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? chatIntegrations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SettingsModel(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      offlineModeEnabled: offlineModeEnabled ?? this.offlineModeEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      dataBackupEnabled: dataBackupEnabled ?? this.dataBackupEnabled,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      receiptImageQuality: receiptImageQuality ?? this.receiptImageQuality,
      defaultExportFormat: defaultExportFormat ?? this.defaultExportFormat,
      defaultInvoiceTemplate:
          defaultInvoiceTemplate ?? this.defaultInvoiceTemplate,
      taxSettings: taxSettings ?? this.taxSettings,
      businessInfo: businessInfo ?? this.businessInfo,
      chatIntegrations: chatIntegrations ?? this.chatIntegrations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'defaultCurrency': defaultCurrency,
      'defaultCategory': defaultCategory,
      'notificationsEnabled': notificationsEnabled,
      'autoSyncEnabled': autoSyncEnabled,
      'offlineModeEnabled': offlineModeEnabled,
      'biometricEnabled': biometricEnabled,
      'dataBackupEnabled': dataBackupEnabled,
      'syncIntervalMinutes': syncIntervalMinutes,
      'receiptImageQuality': receiptImageQuality,
      'defaultExportFormat': defaultExportFormat,
      'defaultInvoiceTemplate': defaultInvoiceTemplate,
      'taxSettings': taxSettings,
      'businessInfo': businessInfo,
      'chatIntegrations': chatIntegrations,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      theme: json['theme'] ?? 'system',
      language: json['language'] ?? 'en',
      defaultCurrency: json['defaultCurrency'] ?? 'USD',
      defaultCategory: json['defaultCategory'] ?? 'General',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      autoSyncEnabled: json['autoSyncEnabled'] ?? true,
      offlineModeEnabled: json['offlineModeEnabled'] ?? true,
      biometricEnabled: json['biometricEnabled'] ?? false,
      dataBackupEnabled: json['dataBackupEnabled'] ?? true,
      syncIntervalMinutes: json['syncIntervalMinutes'] ?? 30,
      receiptImageQuality: json['receiptImageQuality'] ?? 'high',
      defaultExportFormat: json['defaultExportFormat'] ?? 'pdf',
      defaultInvoiceTemplate: json['defaultInvoiceTemplate'] ?? 'default',
      taxSettings: Map<String, dynamic>.from(json['taxSettings'] ?? {}),
      businessInfo: Map<String, dynamic>.from(json['businessInfo'] ?? {}),
      chatIntegrations: Map<String, dynamic>.from(
        json['chatIntegrations'] ?? {},
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  SettingsEntity toEntity() {
    return SettingsEntity(
      theme: theme,
      language: language,
      defaultCurrency: defaultCurrency,
      defaultCategory: defaultCategory,
      notificationsEnabled: notificationsEnabled,
      autoSyncEnabled: autoSyncEnabled,
      offlineModeEnabled: offlineModeEnabled,
      biometricEnabled: biometricEnabled,
      dataBackupEnabled: dataBackupEnabled,
      syncIntervalMinutes: syncIntervalMinutes,
      receiptImageQuality: receiptImageQuality,
      defaultExportFormat: defaultExportFormat,
      defaultInvoiceTemplate: defaultInvoiceTemplate,
      taxSettings: taxSettings,
      businessInfo: businessInfo,
      chatIntegrations: chatIntegrations,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      theme: entity.theme,
      language: entity.language,
      defaultCurrency: entity.defaultCurrency,
      defaultCategory: entity.defaultCategory,
      notificationsEnabled: entity.notificationsEnabled,
      autoSyncEnabled: entity.autoSyncEnabled,
      offlineModeEnabled: entity.offlineModeEnabled,
      biometricEnabled: entity.biometricEnabled,
      dataBackupEnabled: entity.dataBackupEnabled,
      syncIntervalMinutes: entity.syncIntervalMinutes,
      receiptImageQuality: entity.receiptImageQuality,
      defaultExportFormat: entity.defaultExportFormat,
      defaultInvoiceTemplate: entity.defaultInvoiceTemplate,
      taxSettings: entity.taxSettings,
      businessInfo: entity.businessInfo,
      chatIntegrations: entity.chatIntegrations,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SettingsModel(theme: $theme, language: $language, currency: $defaultCurrency, '
        'category: $defaultCategory, notifications: $notificationsEnabled, '
        'autoSync: $autoSyncEnabled, offline: $offlineModeEnabled, '
        'biometric: $biometricEnabled, backup: $dataBackupEnabled, '
        'syncInterval: $syncIntervalMinutes, quality: $receiptImageQuality, '
        'exportFormat: $defaultExportFormat, template: $defaultInvoiceTemplate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SettingsModel &&
        other.theme == theme &&
        other.language == language &&
        other.defaultCurrency == defaultCurrency &&
        other.defaultCategory == defaultCategory &&
        other.notificationsEnabled == notificationsEnabled &&
        other.autoSyncEnabled == autoSyncEnabled &&
        other.offlineModeEnabled == offlineModeEnabled &&
        other.biometricEnabled == biometricEnabled &&
        other.dataBackupEnabled == dataBackupEnabled &&
        other.syncIntervalMinutes == syncIntervalMinutes &&
        other.receiptImageQuality == receiptImageQuality &&
        other.defaultExportFormat == defaultExportFormat &&
        other.defaultInvoiceTemplate == defaultInvoiceTemplate;
  }

  @override
  int get hashCode {
    return theme.hashCode ^
        language.hashCode ^
        defaultCurrency.hashCode ^
        defaultCategory.hashCode ^
        notificationsEnabled.hashCode ^
        autoSyncEnabled.hashCode ^
        offlineModeEnabled.hashCode ^
        biometricEnabled.hashCode ^
        dataBackupEnabled.hashCode ^
        syncIntervalMinutes.hashCode ^
        receiptImageQuality.hashCode ^
        defaultExportFormat.hashCode ^
        defaultInvoiceTemplate.hashCode;
  }
}
