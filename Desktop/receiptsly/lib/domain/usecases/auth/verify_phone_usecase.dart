import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repositories/i_auth_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/validators.dart';

class VerifyPhoneUseCase {
  final IAuthRepository _authRepository;

  VerifyPhoneUseCase(this._authRepository);

  Future<Either<Failure, PhoneVerificationResult>> call(
    VerifyPhoneParams params,
  ) async {
    // Validate phone number
    if (!Validators.isValidPhoneNumber(params.phoneNumber)) {
      return Left(ValidationFailure('Please enter a valid phone number'));
    }

    try {
      final result = await _authRepository.verifyPhoneNumber(
        phoneNumber: params.phoneNumber,
        timeout: params.timeout,
        forceResendingToken: params.resendToken,
      );

      return result.fold(
        (failure) => Left(failure),
        (verificationResult) => Right(verificationResult),
      );
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseAuthError(e)));
    } catch (e) {
      return Left(NetworkFailure('Phone verification failed: ${e.toString()}'));
    }
  }

  Future<Either<Failure, UserCredential>> verifyCode(
    VerifyCodeParams params,
  ) async {
    // Validate verification code
    if (params.verificationCode.length != 6) {
      return Left(ValidationFailure('Verification code must be 6 digits'));
    }

    if (!RegExp(r'^\d{6}$').hasMatch(params.verificationCode)) {
      return Left(
        ValidationFailure('Verification code must contain only numbers'),
      );
    }

    try {
      final result = await _authRepository.verifyPhoneCode(
        verificationId: params.verificationId,
        verificationCode: params.verificationCode,
      );

      return result.fold((failure) => Left(failure), (userCredential) async {
        // Update user profile with verified phone number
        if (userCredential.user != null) {
          await _authRepository.updatePhoneNumber(
            userCredential.user!.uid,
            userCredential.user!.phoneNumber!,
          );
        }
        return Right(userCredential);
      });
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseAuthError(e)));
    } catch (e) {
      return Left(NetworkFailure('Code verification failed: ${e.toString()}'));
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Invalid verification ID';
      case 'credential-already-in-use':
        return 'This phone number is already associated with another account';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Phone verification failed: ${e.message}';
    }
  }
}

class VerifyPhoneParams {
  final String phoneNumber;
  final Duration timeout;
  final int? resendToken;

  VerifyPhoneParams({
    required this.phoneNumber,
    this.timeout = const Duration(seconds: 60),
    this.resendToken,
  });
}

class VerifyCodeParams {
  final String verificationId;
  final String verificationCode;

  VerifyCodeParams({
    required this.verificationId,
    required this.verificationCode,
  });
}

class PhoneVerificationResult {
  final String verificationId;
  final int? resendToken;
  final bool autoVerified;

  PhoneVerificationResult({
    required this.verificationId,
    this.resendToken,
    this.autoVerified = false,
  });
}
