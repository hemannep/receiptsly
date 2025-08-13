// lib/presentation/screens/auth/phone_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/widgets/common/app_button.dart';
import '../../../presentation/widgets/common/app_text_field.dart';
import '../../../presentation/widgets/common/app_loader.dart';
import '../../../presentation/widgets/common/app_snackbar.dart';
import 'widgets/auth_header.dart';
import 'widgets/otp_input_field.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final String? phoneNumber;

  const PhoneVerificationScreen({super.key, this.phoneNumber});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isVerifying = false;
  bool _otpSent = false;
  String? _verificationId;
  int _resendTimeout = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!;
      _sendOTP();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_otpSent && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        onCodeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          _startResendTimer();
          _showSuccessMessage('OTP sent successfully');
        },
        onError: (error) {
          setState(() => _isLoading = false);
          _showErrorMessage(error);
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to send OTP');
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      _showErrorMessage('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final result = await authNotifier.verifyOTP(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );

      if (result.success) {
        if (mounted) {
          context.go('/onboarding');
        }
      } else {
        _showErrorMessage(result.message ?? 'OTP verification failed');
      }
    } catch (e) {
      _showErrorMessage('Invalid OTP. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _startResendTimer() {
    _resendTimeout = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimeout == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendTimeout--;
        });
      }
    });
  }

  Future<void> _resendOTP() async {
    _otpController.clear();
    await _sendOTP();
  }

  void _editPhoneNumber() {
    setState(() {
      _otpSent = false;
      _verificationId = null;
      _otpController.clear();
    });
    _resendTimer?.cancel();
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
          onPressed: (_isLoading || _isVerifying) ? null : () => context.pop(),
        ),
        actions: [
          if (_otpSent)
            TextButton(
              onPressed: (_isLoading || _isVerifying) ? null : _editPhoneNumber,
              child: Text(
                'Edit',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Header
                AuthHeader(
                  title: _otpSent
                      ? 'Verify Phone Number'
                      : 'Phone Verification',
                  subtitle: _otpSent
                      ? 'Enter the 6-digit code sent to ${_phoneController.text}'
                      : 'We need to verify your phone number for security',
                ),

                const SizedBox(height: 48),

                if (!_otpSent) ...[
                  // Phone Number Input
                  AppTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.phone_outlined,
                    validator: Validators.phoneNumber,
                    enabled: !_isLoading,
                    onSubmitted: (_) => _sendOTP(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'We\'ll send you a 6-digit verification code via SMS',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Send OTP Button
                  AppButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    child: _isLoading
                        ? const AppLoader(color: Colors.white)
                        : const Text('Send Verification Code'),
                  ),
                ] else ...[
                  // OTP Input
                  OTPInputField(
                    controller: _otpController,
                    length: 6,
                    onCompleted: (otp) {
                      if (otp.length == 6) {
                        _verifyOTP();
                      }
                    },
                    enabled: !_isVerifying,
                  ),

                  const SizedBox(height: 24),

                  // Resend Timer/Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Didn\'t receive the code? ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_resendTimeout > 0)
                        Text(
                          'Resend in ${_resendTimeout}s',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        TextButton(
                          onPressed: (_isLoading || _isVerifying)
                              ? null
                              : _resendOTP,
                          child: Text(
                            'Resend Code',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Verify Button
                  AppButton(
                    onPressed: (_isVerifying || _otpController.text.length != 6)
                        ? null
                        : _verifyOTP,
                    child: _isVerifying
                        ? const AppLoader(color: Colors.white)
                        : const Text('Verify Code'),
                  ),

                  const SizedBox(height: 24),

                  // Help Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: AppColors.warning,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Trouble receiving SMS?',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check if your phone number is correct and try again. You can also skip this step and verify later.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            context.go('/onboarding');
                          },
                          child: Text(
                            'Skip for Now',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
