// lib/presentation/providers/onboarding_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firebase/firestore_service.dart';
import '../../services/local/local_storage_service.dart';

// Onboarding State
class OnboardingState {
  final bool isCompleted;
  final int currentStep;
  final Map<String, dynamic> businessInfo;
  final Map<String, dynamic> taxSettings;
  final Map<String, dynamic> chatIntegrations;
  final bool isLoading;
  final String? errorMessage;

  const OnboardingState({
    this.isCompleted = false,
    this.currentStep = 0,
    this.businessInfo = const {},
    this.taxSettings = const {},
    this.chatIntegrations = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  OnboardingState copyWith({
    bool? isCompleted,
    int? currentStep,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? taxSettings,
    Map<String, dynamic>? chatIntegrations,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OnboardingState(
      isCompleted: isCompleted ?? this.isCompleted,
      currentStep: currentStep ?? this.currentStep,
      businessInfo: businessInfo ?? this.businessInfo,
      taxSettings: taxSettings ?? this.taxSettings,
      chatIntegrations: chatIntegrations ?? this.chatIntegrations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Onboarding Notifier
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;

  OnboardingNotifier(this._firestoreService, this._localStorageService)
    : super(const OnboardingState()) {
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    try {
      // Check if onboarding is completed
      final isCompleted =
          await _localStorageService.getBool('onboarding_completed') ?? false;

      if (isCompleted) {
        state = state.copyWith(isCompleted: true);
        return;
      }

      // Load saved progress
      final currentStep =
          await _localStorageService.getInt('onboarding_step') ?? 0;
      final businessInfo =
          await _localStorageService.getMap('business_info') ?? {};
      final taxSettings =
          await _localStorageService.getMap('tax_settings') ?? {};
      final chatIntegrations =
          await _localStorageService.getMap('chat_integrations') ?? {};

      state = state.copyWith(
        currentStep: currentStep,
        businessInfo: businessInfo,
        taxSettings: taxSettings,
        chatIntegrations: chatIntegrations,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load onboarding state');
    }
  }

  Future<void> saveBusinessInfo(Map<String, dynamic> businessInfo) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Save locally
      await _localStorageService.setMap('business_info', businessInfo);
      await _localStorageService.setInt('onboarding_step', 1);

      // Save to Firestore
      await _firestoreService.updateUserProfile(businessInfo);

      state = state.copyWith(
        businessInfo: businessInfo,
        currentStep: 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save business information',
      );
      throw e;
    }
  }

  Future<void> saveTaxSettings(Map<String, dynamic> taxSettings) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Save locally
      await _localStorageService.setMap('tax_settings', taxSettings);
      await _localStorageService.setInt('onboarding_step', 2);

      // Save to Firestore
      await _firestoreService.updateUserProfile({'taxSettings': taxSettings});

      state = state.copyWith(
        taxSettings: taxSettings,
        currentStep: 2,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save tax settings',
      );
      throw e;
    }
  }

  Future<void> saveChatIntegrations(
    Map<String, dynamic> chatIntegrations,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Save locally
      await _localStorageService.setMap('chat_integrations', chatIntegrations);
      await _localStorageService.setInt('onboarding_step', 3);

      // Save to Firestore
      await _firestoreService.updateUserProfile({
        'chatIntegrations': chatIntegrations,
      });

      state = state.copyWith(
        chatIntegrations: chatIntegrations,
        currentStep: 3,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save chat integrations',
      );
      throw e;
    }
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Mark as completed locally
      await _localStorageService.setBool('onboarding_completed', true);
      await _localStorageService.setInt('onboarding_step', 3);

      // Update user profile
      await _firestoreService.updateUserProfile({
        'onboardingCompleted': true,
        'onboardingCompletedAt': DateTime.now().toIso8601String(),
      });

      // Clear temporary onboarding data
      await _localStorageService.remove('business_info');
      await _localStorageService.remove('tax_settings');
      await _localStorageService.remove('chat_integrations');
      await _localStorageService.remove('onboarding_step');

      state = state.copyWith(isCompleted: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to complete onboarding',
      );
      throw e;
    }
  }

  Future<void> resetOnboarding() async {
    try {
      // Clear all onboarding data
      await _localStorageService.setBool('onboarding_completed', false);
      await _localStorageService.remove('business_info');
      await _localStorageService.remove('tax_settings');
      await _localStorageService.remove('chat_integrations');
      await _localStorageService.remove('onboarding_step');

      state = const OnboardingState();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reset onboarding');
    }
  }

  void setCurrentStep(int step) {
    state = state.copyWith(currentStep: step);
    _localStorageService.setInt('onboarding_step', step);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Chat Integration Provider
class ChatIntegrationNotifier extends StateNotifier<Map<String, dynamic>> {
  final FirestoreService _firestoreService;

  ChatIntegrationNotifier(this._firestoreService) : super({});

  Future<String?> generateWhatsAppQR() async {
    try {
      // This would typically call a Firebase function or API
      // For now, return a placeholder
      return 'whatsapp_qr_code_placeholder';
    } catch (e) {
      return null;
    }
  }

  Future<String?> getTelegramBotLink() async {
    try {
      // This would return the actual Telegram bot link
      return 'https://t.me/receiptsly_bot';
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, bool>> getConnectionStatus() async {
    try {
      // Check current connection status from Firestore
      return {'whatsapp': false, 'telegram': false};
    } catch (e) {
      return {'whatsapp': false, 'telegram': false};
    }
  }

  Future<bool> connectWhatsApp() async {
    try {
      // Implement WhatsApp connection logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> connectTelegram() async {
    try {
      // Implement Telegram connection logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Providers
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);
final localStorageServiceProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService(),
);

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier(
        ref.watch(firestoreServiceProvider),
        ref.watch(localStorageServiceProvider),
      );
    });

final chatIntegrationProvider =
    StateNotifierProvider<ChatIntegrationNotifier, Map<String, dynamic>>((ref) {
      return ChatIntegrationNotifier(ref.watch(firestoreServiceProvider));
    });

final isOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider).isCompleted;
});

final onboardingCurrentStepProvider = Provider<int>((ref) {
  return ref.watch(onboardingProvider).currentStep;
});
