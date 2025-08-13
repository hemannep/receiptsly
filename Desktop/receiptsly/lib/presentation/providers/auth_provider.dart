import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase/auth_service.dart';
import '../../data/models/user/user_model.dart';
import '../../core/errors/failures.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

// User Profile Provider
final userProfileProvider = StreamProvider.family<UserModel?, String>((
  ref,
  userId,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return null;
        return UserModel.fromJson({'id': snapshot.id, ...snapshot.data()!});
      });
});

// Auth State Notifier
class AuthStateNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen(
      (user) => state = AsyncValue.data(user),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
  }

  // Sign Up
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String businessName,
    required String businessType,
    String? country,
    String? currency,
  }) async {
    state = const AsyncValue.loading();

    try {
      final result = await _authService.signUpWithEmail(
        email: email,
        password: password,
        businessData: {
          'name': name,
          'businessName': businessName,
          'businessType': businessType,
          'country': country ?? 'US',
          'currency': currency ?? 'USD',
        },
      );

      if (result.success) {
        state = AsyncValue.data(result.user);
      } else {
        state = AsyncValue.error(
          AuthFailure(result.message ?? 'Sign up failed'),
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Sign In
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();

    try {
      final result = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (result.success) {
        state = AsyncValue.data(result.user);
      } else {
        state = AsyncValue.error(
          AuthFailure(result.message ?? 'Sign in failed'),
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Google Sign In
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      final result = await _authService.signInWithGoogle();

      if (result.success) {
        state = AsyncValue.data(result.user);
      } else {
        state = AsyncValue.error(
          AuthFailure(result.message ?? 'Google sign in failed'),
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _authService.sendPasswordReset(email);
    } catch (error) {
      throw AuthFailure('Failed to send password reset email');
    }
  }
}

// Auth State Notifier Provider
final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<User?>>((ref) {
      return AuthStateNotifier(ref.watch(authServiceProvider));
    });

// Is Authenticated Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});
