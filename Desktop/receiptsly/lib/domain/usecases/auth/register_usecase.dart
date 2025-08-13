import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../entities/user_entity.dart';
import '../../repositories/i_auth_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/validators.dart';

class RegisterUseCase {
  final IAuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  Future<Either<Failure, UserEntity>> call(RegisterParams params) async {
    // Validate input parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(ValidationFailure(validationResult));
    }

    try {
      // Check if email is already registered
      final emailExistsResult = await _authRepository.checkEmailExists(
        params.email,
      );
      if (emailExistsResult) {
        return Left(AuthFailure('An account with this email already exists'));
      }

      // Create user account
      final createResult = await _authRepository.createUserWithEmail(
        email: params.email,
        password: params.password,
      );

      return createResult.fold((failure) => Left(failure), (user) async {
        try {
          // Create user profile in Firestore
          final userEntity = UserEntity(
            uid: user.uid,
            email: params.email,
            name: params.name,
            businessName: params.businessName,
            businessType: params.businessType,
            country: params.country,
            currency: params.currency,
            phoneNumber: params.phoneNumber,
            isEmailVerified: false,
            subscription: SubscriptionEntity.free(),
            preferences: UserPreferencesEntity.defaultPreferences(),
            chatIntegrations: ChatIntegrationsEntity.empty(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final profileResult = await _authRepository.createUserProfile(
            userEntity,
          );

          return profileResult.fold(
            (failure) async {
              // Cleanup: delete the auth user if profile creation fails
              await user.delete();
              return Left(failure);
            },
            (_) async {
              // Send email verification
              await _authRepository.sendEmailVerification();

              // Create default expense categories
              await _authRepository.createDefaultCategories(user.uid);

              return Right(userEntity);
            },
          );
        } catch (e) {
          // Cleanup: delete the auth user if any step fails
          await user.delete();
          return Left(
            DatabaseFailure('Failed to create user profile: ${e.toString()}'),
          );
        }
      });
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseAuthError(e)));
    } catch (e) {
      return Left(NetworkFailure('Registration failed: ${e.toString()}'));
    }
  }

  String? _validateParams(RegisterParams params) {
    if (params.name.isEmpty || params.name.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (!Validators.isValidEmail(params.email)) {
      return 'Please enter a valid email address';
    }

    if (!Validators.isValidPassword(params.password)) {
      return 'Password must be at least 8 characters with uppercase, lowercase, and number';
    }

    if (params.password != params.confirmPassword) {
      return 'Passwords do not match';
    }

    if (params.businessName.isEmpty) {
      return 'Business name is required';
    }

    if (params.phoneNumber != null &&
        !Validators.isValidPhoneNumber(params.phoneNumber!)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Registration failed: ${e.message}';
    }
  }
}

class RegisterParams {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String businessName;
  final String businessType;
  final String country;
  final String currency;
  final String? phoneNumber;

  RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.businessName,
    required this.businessType,
    required this.country,
    required this.currency,
    this.phoneNumber,
  });
}
