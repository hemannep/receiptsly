// lib/data/repositories/auth_repository.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/models/user/user_model.dart';
import '../../domain/datasources/local/user_local_datasource.dart';
import '../../domain/datasources/remote/firebase/auth_remote_datasource.dart';

class AuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final UserLocalDatasource _localDatasource;
  final AuthRemoteDatasource _remoteDatasource;
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _preferences;

  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
    required UserLocalDatasource localDatasource,
    required AuthRemoteDatasource remoteDatasource,
    required FlutterSecureStorage secureStorage,
    required SharedPreferences preferences,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn = googleSignIn,
       _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource,
       _secureStorage = secureStorage,
       _preferences = preferences;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user != null) {
        try {
          // Try to get user data from cache first
          final cachedUser = await _localDatasource.getCachedUser(user.uid);
          if (cachedUser != null) {
            return cachedUser.toEntity();
          }

          // If not cached, fetch from remote
          final userData = await _remoteDatasource.getUserData(user.uid);
          if (userData != null) {
            // Cache the user data
            await _localDatasource.cacheUser(userData);
            return userData.toEntity();
          }
        } catch (e) {
          // Return basic user entity if data fetch fails
          return UserEntity(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? '',
            businessName: '',
            businessType: 'freelancer',
            country: '',
            currency: 'USD',
            subscription: const SubscriptionEntity(
              plan: 'free',
              validUntil: null,
              receiptCount: 0,
              monthlyLimit: 50,
            ),
            preferences: const UserPreferencesEntity(
              defaultCategory: 'General',
              autoSync: true,
              offlineMode: true,
              notifications: true,
            ),
            chatIntegrations: const ChatIntegrationsEntity(
              whatsapp: ChatIntegrationEntity(connected: false),
              telegram: ChatIntegrationEntity(connected: false),
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }
      return null;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String businessName,
    required String businessType,
    required String country,
    required String currency,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return Left(AuthFailure('Failed to create user account'));
      }

      final user = userCredential.user!;

      // Update display name
      await user.updateDisplayName(name);

      // Create user document
      final userData = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        businessName: businessName,
        businessType: businessType,
        country: country,
        currency: currency,
        subscription: const SubscriptionModel(
          plan: 'free',
          validUntil: null,
          receiptCount: 0,
          monthlyLimit: 50,
        ),
        preferences: const UserPreferencesModel(
          defaultCategory: 'General',
          autoSync: true,
          offlineMode: true,
          notifications: true,
        ),
        chatIntegrations: const ChatIntegrationsModel(
          whatsapp: ChatIntegrationModel(connected: false),
          telegram: ChatIntegrationModel(connected: false),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _remoteDatasource.createUser(userData);

      // Cache locally
      await _localDatasource.cacheUser(userData);

      // Send email verification
      await user.sendEmailVerification();

      // Store authentication state
      await _storeAuthState(user.uid, email);

      return Right(userData.toEntity());
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_handleFirebaseAuthError(e)));
    } catch (e) {
      return Left(AuthFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return Left(AuthFailure('Failed to sign in'));
      }

      final user = userCredential.user!;

      // Get user data
      final userData = await _remoteDatasource.getUserData(user.uid);
      if (userData == null) {
        return Left(AuthFailure('User data not found'));
      }

      // Cache user data
      await _localDatasource.cacheUser(userData);

      // Store authentication state
      await _storeAuthState(user.uid, email);

      // Update last login time
      await _remoteDatasource.updateLastLogin(user.uid);

      return Right(userData.toEntity());
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_handleFirebaseAuthError(e)));
    } catch (e) {
      return Left(AuthFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return Left(AuthFailure('Google sign in was cancelled'));
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        return Left(AuthFailure('Failed to sign in with Google'));
      }

      final user = userCredential.user!;
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      UserModel userData;

      if (isNewUser) {
        // Create new user document
        userData = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          businessName: '',
          businessType: 'freelancer',
          country: '',
          currency: 'USD',
          subscription: const SubscriptionModel(
            plan: 'free',
            validUntil: null,
            receiptCount: 0,
            monthlyLimit: 50,
          ),
          preferences: const UserPreferencesModel(
            defaultCategory: 'General',
            autoSync: true,
            offlineMode: true,
            notifications: true,
          ),
          chatIntegrations: const ChatIntegrationsModel(
            whatsapp: ChatIntegrationModel(connected: false),
            telegram: ChatIntegrationModel(connected: false),
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save to Firestore
        await _remoteDatasource.createUser(userData);
      } else {
        // Get existing user data
        final existingUserData = await _remoteDatasource.getUserData(user.uid);
        if (existingUserData == null) {
          return Left(AuthFailure('User data not found'));
        }
        userData = existingUserData;

        // Update last login
        await _remoteDatasource.updateLastLogin(user.uid);
      }

      // Cache user data
      await _localDatasource.cacheUser(userData);

      // Store authentication state
      await _storeAuthState(user.uid, user.email ?? '');

      return Right(userData.toEntity());
    } catch (e) {
      return Left(AuthFailure('Google sign in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      // Clear local data
      if (currentUser != null) {
        await _localDatasource.clearUserCache(currentUser.uid);
      }

      // Clear authentication state
      await _clearAuthState();

      // Sign out from all providers
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);

      return const Right(null);
    } catch (e) {
      return Left(AuthFailure('Failed to sign out: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_handleFirebaseAuthError(e)));
    } catch (e) {
      return Left(
        AuthFailure('Failed to send password reset email: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(AuthFailure('No authenticated user found'));
      }

      await user.updatePassword(newPassword);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_handleFirebaseAuthError(e)));
    } catch (e) {
      return Left(AuthFailure('Failed to update password: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(AuthFailure('No authenticated user found'));
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }

      return const Right(null);
    } catch (e) {
      return Left(
        AuthFailure('Failed to send verification email: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? businessName,
    String? businessType,
    String? country,
    String? currency,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(AuthFailure('No authenticated user found'));
      }

      // Get current user data
      final currentUserData = await _remoteDatasource.getUserData(user.uid);
      if (currentUserData == null) {
        return Left(AuthFailure('User data not found'));
      }

      // Update Firebase Auth profile if name changed
      if (name != null && name != user.displayName) {
        await user.updateDisplayName(name);
      }

      // Create updated user data
      final updatedUserData = currentUserData.copyWith(
        name: name,
        businessName: businessName,
        businessType: businessType,
        country: country,
        currency: currency,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _remoteDatasource.updateUser(updatedUserData);

      // Update local cache
      await _localDatasource.cacheUser(updatedUserData);

      return Right(updatedUserData.toEntity());
    } catch (e) {
      return Left(AuthFailure('Failed to update profile: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Right(null);
      }

      // Try cache first
      final cachedUser = await _localDatasource.getCachedUser(user.uid);
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }

      // Fetch from remote
      final userData = await _remoteDatasource.getUserData(user.uid);
      if (userData != null) {
        await _localDatasource.cacheUser(userData);
        return Right(userData.toEntity());
      }

      return const Right(null);
    } catch (e) {
      return Left(AuthFailure('Failed to get current user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(AuthFailure('No authenticated user found'));
      }

      // Reload user to get latest verification status
      await user.reload();

      return Right(user.emailVerified);
    } catch (e) {
      return Left(
        AuthFailure('Failed to check email verification: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(AuthFailure('No authenticated user found'));
      }

      final uid = user.uid;

      // Clear local data
      await _localDatasource.clearUserCache(uid);
      await _clearAuthState();

      // Delete user data from Firestore (this should trigger cloud function for cleanup)
      await _remoteDatasource.deleteUser(uid);

      // Delete Firebase Auth account
      await user.delete();

      return const Right(null);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return Left(
          AuthFailure('Please sign in again before deleting your account'),
        );
      }
      return Left(AuthFailure(_handleFirebaseAuthError(e)));
    } catch (e) {
      return Left(AuthFailure('Failed to delete account: ${e.toString()}'));
    }
  }

  // Private helper methods
  Future<void> _storeAuthState(String uid, String email) async {
    await _preferences.setString('user_uid', uid);
    await _preferences.setString('user_email', email);
    await _preferences.setBool('is_logged_in', true);
    await _secureStorage.write(key: 'auth_token', value: uid);
  }

  Future<void> _clearAuthState() async {
    await _preferences.remove('user_uid');
    await _preferences.remove('user_email');
    await _preferences.setBool('is_logged_in', false);
    await _secureStorage.delete(key: 'auth_token');
  }

  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
