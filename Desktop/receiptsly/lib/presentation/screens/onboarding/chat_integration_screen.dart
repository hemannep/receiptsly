// lib/presentation/screens/onboarding/chat_integration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../presentation/providers/onboarding_provider.dart';
import '../../../presentation/providers/chat_integration_provider.dart';
import '../../../presentation/widgets/common/app_button.dart';
import '../../../presentation/widgets/common/app_loader.dart';
import '../../../presentation/widgets/common/app_snackbar.dart';
import 'widgets/progress_indicator.dart';

class ChatIntegrationScreen extends ConsumerStatefulWidget {
  const ChatIntegrationScreen({super.key});

  @override
  ConsumerState<ChatIntegrationScreen> createState() =>
      _ChatIntegrationScreenState();
}

class _ChatIntegrationScreenState extends ConsumerState<ChatIntegrationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _whatsappQRCode;
  String? _telegramBotLink;
  bool _whatsappConnected = false;
  bool _telegramConnected = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeChatIntegrations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeChatIntegrations() async {
    setState(() => _isLoading = true);

    try {
      final chatProvider = ref.read(chatIntegrationProvider.notifier);

      // Initialize WhatsApp QR code
      _whatsappQRCode = await chatProvider.generateWhatsAppQR();

      // Initialize Telegram bot link
      _telegramBotLink = await chatProvider.getTelegramBotLink();

      // Check existing connections
      final connections = await chatProvider.getConnectionStatus();
      _whatsappConnected = connections['whatsapp'] ?? false;
      _telegramConnected = connections['telegram'] ?? false;
    } catch (e) {
      _showErrorMessage('Failed to initialize chat integrations');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _connectWhatsApp() async {
    setState(() => _isLoading = true);

    try {
      final chatProvider = ref.read(chatIntegrationProvider.notifier);
      final success = await chatProvider.connectWhatsApp();

      if (success) {
        setState(() => _whatsappConnected = true);
        _showSuccessMessage('WhatsApp connected successfully!');
      } else {
        _showErrorMessage('Failed to connect WhatsApp');
      }
    } catch (e) {
      _showErrorMessage('WhatsApp connection failed');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _connectTelegram() async {
    setState(() => _isLoading = true);

    try {
      final chatProvider = ref.read(chatIntegrationProvider.notifier);
      final success = await chatProvider.connectTelegram();

      if (success) {
        setState(() => _telegramConnected = true);
        _showSuccessMessage('Telegram connected successfully!');
      } else {
        _showErrorMessage('Failed to connect Telegram');
      }
    } catch (e) {
      _showErrorMessage('Telegram connection failed');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final onboardingNotifier = ref.read(onboardingProvider.notifier);
      await onboardingNotifier.completeOnboarding();

      if (mounted) {
        _showSuccessMessage('Setup completed successfully!');
        context.go('/dashboard');
      }
    } catch (e) {
      _showErrorMessage('Failed to complete setup');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    AppSnackbar.showError(context, message);
  }

  void _showSuccessMessage(String message) {
    AppSnackbar.showSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
        title: Text(
          'Chat Integration',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OnboardingProgressIndicator(
                currentPage: 3,
                totalPages: 3,
                showLabels: true,
                labels: const ['Welcome', 'Business', 'Chat Setup'],
              ),
            ),

            const SizedBox(height: 32),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect Your Chat Apps',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send receipts directly from WhatsApp or Telegram for instant processing.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicator: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          AssetPaths.whatsappIcon,
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.chat,
                              size: 20,
                              color: AppColors.success,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('WhatsApp'),
                        if (_whatsappConnected) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          AssetPaths.telegramIcon,
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.telegram,
                              size: 20,
                              color: AppColors.info,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('Telegram'),
                        if (_telegramConnected) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildWhatsAppTab(), _buildTelegramTab()],
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      variant: ButtonVariant.outlined,
                      onPressed: _isLoading ? null : _completeOnboarding,
                      child: const Text('Skip for Now'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      onPressed: _isLoading ? null : _completeOnboarding,
                      child: _isLoading
                          ? const AppLoader(color: Colors.white)
                          : const Text('Get Started'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Connection Status
          if (_whatsappConnected) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WhatsApp Connected!',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You can now send receipts directly via WhatsApp',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            // QR Code Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    'Scan QR Code',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open WhatsApp and scan this QR code to connect',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  if (_whatsappQRCode != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: QrImageView(
                        data: _whatsappQRCode!,
                        version: QrVersions.auto,
                        size: 200.0,
                        foregroundColor: Colors.black,
                      ),
                    )
                  else
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(child: AppLoader()),
                    ),

                  const SizedBox(height: 24),

                  AppButton(
                    variant: ButtonVariant.outlined,
                    onPressed: _isLoading ? null : _initializeChatIntegrations,
                    child: const Text('Refresh QR Code'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // How to Connect Steps
          _buildHowToConnect(
            platform: 'WhatsApp',
            steps: [
              'Open WhatsApp on your phone',
              'Tap the three dots (⋮) in the top right',
              'Select "Linked Devices"',
              'Tap "Link a Device"',
              'Scan the QR code above',
            ],
            icon: Icons.qr_code_scanner,
          ),

          const SizedBox(height: 24),

          // Benefits Section
          _buildBenefitsSection([
            'Send receipts instantly while on the go',
            'No need to switch between apps',
            'Automatic OCR processing',
            'Works offline - syncs when connected',
          ]),
        ],
      ),
    );
  }

  Widget _buildTelegramTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Connection Status
          if (_telegramConnected) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Telegram Connected!',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You can now send receipts via our Telegram bot',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            // Bot Connection Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 48,
                    color: AppColors.info,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connect to Receiptsly Bot',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a chat with our Telegram bot to send receipts',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  AppButton(
                    onPressed: _isLoading ? null : _connectTelegram,
                    child: _isLoading
                        ? const AppLoader(color: Colors.white)
                        : const Text('Open Telegram Bot'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // How to Connect Steps
          _buildHowToConnect(
            platform: 'Telegram',
            steps: [
              'Tap "Open Telegram Bot" above',
              'This will open Telegram app',
              'Tap "START" to begin the conversation',
              'Send a test message to verify connection',
              'You\'re ready to send receipts!',
            ],
            icon: Icons.chat_bubble_outline,
          ),

          const SizedBox(height: 24),

          // Benefits Section
          _buildBenefitsSection([
            'Send receipts from any device',
            'Get instant processing confirmations',
            'Edit receipt details via chat commands',
            'View monthly summaries and reports',
          ]),
        ],
      ),
    );
  }

  Widget _buildHowToConnect({
    required String platform,
    required List<String> steps,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'How to Connect $platform',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(List<String> benefits) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_outline, color: AppColors.warning, size: 24),
              const SizedBox(width: 12),
              Text(
                'Benefits',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...benefits
              .map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
