import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../entities/user_entity.dart';
import '../../repositories/i_auth_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/validators.dart';

class LoginUseCase {
  final IAuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    // Validate input parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(ValidationFailure(validationResult));
    }

    try {
      // Attempt login with email and password
      final result = await _authRepository.signInWithEmail(
        email: params.email,
        password: params.password,
      );

      return result.fold((failure) => Left(failure), (user) async {
        // Check if email is verified for non-Google logins
        if (!user.isEmailVerified && !user.email!.contains('gmail.com')) {
          return Left(
            AuthFailure('Please verify your email before logging in.'),
          );
        }

        // Update last login timestamp
        await _authRepository.updateLastLogin(user.uid);

        // Fetch complete user profile
        final userProfileResult = await _authRepository.getUserProfile(
          user.uid,
        );

        return userProfileResult.fold(
          (failure) => Left(failure),
          (userEntity) => Right(userEntity),
        );
      });
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseAuthError(e)));
    } catch (e) {
      return Left(NetworkFailure('Login failed: ${e.toString()}'));
    }
  }

  String? _validateParams(LoginParams params) {
    if (!Validators.isValidEmail(params.email)) {
      return 'Please enter a valid email address';
    }

    if (params.password.isEmpty) {
      return 'Password cannot be empty';
    }

    if (params.password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Login failed: ${e.message}';
    }
  }
}

class LoginParams {
  final String email;
  final String password;
  final bool rememberMe;

  LoginParams({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });
}
