// lib/services/firebase/auth_service.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:receiptsly/core/network/interceptors/auth_interceptor.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../local/secure_storage_service.dart';
import 'firestore_service.dart';

/// Service for handling Firebase Authentication
/// Manages user authentication, session management, and security features
class AuthService {
  static AuthService? _instance;
  late FirebaseAuth _auth;
  late GoogleSignIn _googleSignIn;
  late SecureStorageService _secureStorage;
  late FirestoreService _firestoreService;

  User? _currentUser;
  String? _idToken;
  Timer? _tokenRefreshTimer;
  StreamSubscription<User?>? _authStateSubscription;

  // Auth state stream controller
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  // Singleton pattern
  AuthService._();

  static AuthService getInstance() {
    _instance ??= AuthService._();
    return _instance!;
  }

  /// Initialize the auth service
  Future<void> initialize() async {
    try {
      _auth = FirebaseAuth.instance;
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      _secureStorage = SecureStorageService.getInstance();
      _firestoreService = FirestoreService.getInstance();

      // Setup auth state listener
      _setupAuthStateListener();

      // Check for stored credentials
      await _checkStoredCredentials();

      debugPrint('AuthService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
      rethrow;
    }
  }

  /// Setup auth state listener
  void _setupAuthStateListener() {
    _authStateSubscription = _auth.authStateChanges().listen(
      (User? user) async {
        await _handleAuthStateChange(user);
      },
      onError: (error) {
        debugPrint('Auth state change error: $error');
        _authStateController.add(AuthState.error(error.toString()));
      },
    );
  }

  /// Handle auth state changes
  Future<void> _handleAuthStateChange(User? user) async {
    try {
      _currentUser = user;

      if (user != null) {
        // User signed in
        await _onUserSignedIn(user);
        _authStateController.add(AuthState.authenticated(user));
      } else {
        // User signed out
        await _onUserSignedOut();
        _authStateController.add(AuthState.unauthenticated());
      }
    } catch (e) {
      debugPrint('Error handling auth state change: $e');
      _authStateController.add(AuthState.error(e.toString()));
    }
  }

  /// Handle user signed in
  Future<void> _onUserSignedIn(User user) async {
    try {
      // Get ID token
      _idToken = await user.getIdToken();

      // Setup token refresh timer
      _setupTokenRefreshTimer();

      // Store user credentials securely
      await _storeUserCredentials(user);

      // Update last sign in time
      await _updateLastSignInTime(user.uid);

      debugPrint('User signed in: ${user.uid}');
    } catch (e) {
      debugPrint('Error in onUserSignedIn: $e');
    }
  }

  /// Handle user signed out
  Future<void> _onUserSignedOut() async {
    try {
      // Cancel token refresh timer
      _tokenRefreshTimer?.cancel();
      _tokenRefreshTimer = null;

      // Clear stored tokens
      _idToken = null;

      // Clear secure storage
      await _clearStoredCredentials();

      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Error in onUserSignedOut: $e');
    }
  }

  /// Setup token refresh timer
  void _setupTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    
    // Refresh token every 45 minutes (tokens expire in 1 hour)
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 45),
      (_) => _refreshIdToken(),
    );
  }

  /// Refresh ID token
  Future<void> _refreshIdToken() async {
    try {
      if (_currentUser != null) {
        _idToken = await _currentUser!.getIdToken(true);
        debugPrint('ID token refreshed');
      }
    } catch (e) {
      debugPrint('Error refreshing ID token: $e');
    }
  }

  // Authentication Methods

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required Map<String, dynamic> businessData,
  }) async {
    try {
      _authStateController.add(AuthState.loading());

      // Validate input
      final validation = _validateEmailPassword(email, password);
      if (!validation.isValid) {
        return AuthResult.failure(validation.error!);
      }

      // Create user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.failure('Failed to create user');
      }

      // Update display name
      await user.updateDisplayName(name);

      // Send email verification
      await user.sendEmailVerification();

      // Create user profile in Firestore
      await _createUserProfile(user, businessData);

      return AuthResult.success(user, 'Account created successfully. Please verify your email.');
    } on FirebaseAuthException catch (e) {
      final message = _getAuthErrorMessage(e);
      _authStateController.add(AuthState.error(message));
      return AuthResult.failure(message);
    } catch (e) {
      const message = 'An unexpected error occurred during sign up';
      _authStateController.add(AuthState.error(message));
      return AuthResult.failure(message);
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _authStateController.add(AuthState.loading());

      // Validate input
      final validation = _validateEmailPassword(email, password);
      if (!validation.isValid) {
        return AuthResult.failure(validation.error!);
      }

      // Sign in
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.failure('Failed to sign in');
      }

      return AuthResult.success(user, 'Signed in successfully');
    } on FirebaseAuthException catch (e) {
      final message = _getAuthErrorMessage(e);
      _authStateController.add(AuthState.error(message));
      return AuthResult.failure(message);
    } catch (e) {
      const message = 'An unexpected error occurred during sign in';
      _authStateController.add(AuthState.error(message));
      return AuthResult.failure(message);
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      _authStateController.add(AuthState.loading());

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        return AuthResult.failure('Failed to sign in with Google');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        await _createUserProfile(user, {
          'name': user.displayName ?? 'Google User',
          'authProvider': 'google',
        });
      }

      return AuthResult.success(user, 'Signed in with Google successfully');
    } on FirebaseAuthException catch (e) {
      final message = _getAuthErrorMessage(e);
      _authStateController.add(AuthState.error(message));
      return AuthResult.failure(message);
    } catch (e) {
      final message = 'Google sign in failed: ${e.toString()}';
      _authStateController.add(AuthState.error(message));
      return AuthResult.failure(message);
    }
  }

  /// Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    try {
      _authStateController.add(AuthState.loading());

      // Generate nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credential from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create OAuth credential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user == null) {
        return AuthResult.failure('Failed to sign in with Apple');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        final displayName = appleCredential.givenName != null && appleCredential.familyName != null
            ? '${appleCredential.givenName} ${appleCredential.familyName}'
            : 'Apple User';

        await user.updateDisplayName(displayName);
        await _createUserProfile(user, {
          'name': displayName,
          'authProvider': 'apple',
        });
      }

      return AuthResult.success(user, 'Signed in with Apple successfully');
    } on FirebaseAuthException catch (e) {
      final message = _getAuthErrorMessage(e);
      _authStateController.add(AuthState.error(message));
      return AuthResult.failure(message);
    } catch (e) {
      final message = 'Apple sign in failed: ${e.toString()}';
      _authStateController.add(AuthState.error(message));
      return AuthResult.failure(message);
    }
  }

  /// Phone authentication - Send OTP
  Future<AuthResult> sendPhoneOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
  }) async {
    try {
      _authStateController.add(AuthState.loading());

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          final userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            _authStateController.add(AuthState.authenticated(userCredential.user!));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          final message = _getAuthErrorMessage(e);
          _authStateController.add(AuthState.error(message));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
          _authStateController.add(AuthState.codeSent());
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout for verification ID: $verificationId');
        },
        timeout: const Duration(seconds: 60),
      );

      return AuthResult.success(null, 'OTP sent successfully');
    } catch (e) {
      final message = 'Failed to send OTP: ${e.toString()}';
      _authStateController.add(AuthState.error(message));
      return AuthResult.failure(message);
    }
  }

  /// Verify phone OTP
  Future<AuthResult> verifyPhoneOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      _authStateController.add(AuthState.loading());

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        return AuthResult.failure('Failed to verify OTP');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        await _createUserProfile(user, {
          'name': 'Phone User',
          'authProvider': 'phone',
        });
      }

      return AuthResult.success(user, 'Phone verified successfully');
    } on FirebaseAuthException catch (e) {
      final message = _getAuthErrorMessage(e);
      _authStateController.add(AuthState.error(message));
      return AuthResult.failure(message);
    } catch (e) {
      final message = 'Failed to verify OTP: ${e.toString()}';
      _authStateController.add(AuthState.error(message));
      return AuthResult.failure(message);
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null, 'Password reset email sent');
    } on FirebaseAuthException catch (e) {
      final message = _getAuthErrorMessage(e);
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('Failed to send password reset email');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from all providers
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);

      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error during sign out: $e');
    }
  }

  // User Profile Management

  /// Create user profile
  Future<void> _createUserProfile(User user, Map<String, dynamic> additionalData) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'name': additionalData['name'] ?? user.displayName ?? 'User',
  /// Create user profile
  Future<void> _createUserProfile(User user, Map<String, dynamic> additionalData) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'name': additionalData['name'] ?? user.displayName ?? 'User',
        'phoneNumber': user.phoneNumber,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'authProvider': additionalData['authProvider'] ?? 'email',
        'businessName': additionalData['businessName'] ?? '',
        'businessType': additionalData['businessType'] ?? 'freelancer',
        'country': additionalData['country'] ?? '',
        'currency': additionalData['currency'] ?? 'USD',
        'subscription': {
          'plan': 'free',
          'validUntil': null,
          'receiptCount': 0,
          'monthlyLimit': 50,
          'features': ['basic_ocr', 'receipt_storage', 'basic_reporting'],
        },
        'preferences': {
          'defaultCategory': 'General',
          'autoSync': true,
          'offlineMode': true,
          'notifications': true,
          'theme': 'system',
          'language': 'en',
          'currency': additionalData['currency'] ?? 'USD',
        },
        'chatIntegrations': {
          'whatsapp': {'connected': false, 'phoneNumber': null},
          'telegram': {'connected': false, 'username': null},
        },
        'security': {
          'twoFactorEnabled': false,
          'biometricEnabled': false,
          'lastPasswordChange': FieldValue.serverTimestamp(),
          'securityQuestions': [],
        },
        'analytics': {
          'totalReceipts': 0,
          'totalInvoices': 0,
          'totalExpenses': 0,
          'totalIncome': 0,
          'lastActiveDate': FieldValue.serverTimestamp(),
        },
        'isActive': true,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestoreService.createUserProfile(user.uid, userData);
      debugPrint('User profile created for: ${user.uid}');
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<AuthResult> updateUserProfile({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('No user signed in');
      }

      // Update Firebase Auth profile
      if (displayName != null || photoURL != null) {
        await _currentUser!.updateProfile(
          displayName: displayName,
          photoURL: photoURL,
        );
        await _currentUser!.reload();
        _currentUser = _auth.currentUser;
      }

      // Update Firestore profile
      if (additionalData != null) {
        await _firestoreService.updateUserProfile(_currentUser!.uid, additionalData);
      }

      return AuthResult.success(_currentUser, 'Profile updated successfully');
    } catch (e) {
      return AuthResult.failure('Failed to update profile: ${e.toString()}');
    }
  }

  /// Update email
  Future<AuthResult> updateEmail(String newEmail, String password) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('No user signed in');
      }

      // Re-authenticate first
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: password,
      );
      await _currentUser!.reauthenticateWithCredential(credential);

      // Update email
      await _currentUser!.updateEmail(newEmail);
      
      // Send verification email
      await _currentUser!.sendEmailVerification();

      // Update Firestore
      await _firestoreService.updateUserProfile(_currentUser!.uid, {
        'email': newEmail,
        'emailVerified': false,
      });

      return AuthResult.success(_currentUser, 'Email updated. Please verify your new email.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Failed to update email');
    }
  }

  /// Update password
  Future<AuthResult> updatePassword(String currentPassword, String newPassword) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('No user signed in');
      }

      // Validate new password
      if (newPassword.length < 6) {
        return AuthResult.failure('Password must be at least 6 characters');
      }

      // Re-authenticate first
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: currentPassword,
      );
      await _currentUser!.reauthenticateWithCredential(credential);

      // Update password
      await _currentUser!.updatePassword(newPassword);

      // Update Firestore
      await _firestoreService.updateUserProfile(_currentUser!.uid, {
        'security.lastPasswordChange': FieldValue.serverTimestamp(),
      });

      return AuthResult.success(_currentUser, 'Password updated successfully');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Failed to update password');
    }
  }

  /// Delete account
  Future<AuthResult> deleteAccount(String password) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('No user signed in');
      }

      // Re-authenticate first
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: password,
      );
      await _currentUser!.reauthenticateWithCredential(credential);

      final userId = _currentUser!.uid;

      // Soft delete in Firestore first
      await _firestoreService.updateUserProfile(userId, {
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // Delete Firebase Auth account
      await _currentUser!.delete();

      return AuthResult.success(null, 'Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Failed to delete account');
    }
  }

  // Email Verification

  /// Send email verification
  Future<AuthResult> sendEmailVerification() async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('No user signed in');
      }

      if (_currentUser!.emailVerified) {
        return AuthResult.failure('Email is already verified');
      }

      await _currentUser!.sendEmailVerification();
      return AuthResult.success(_currentUser, 'Verification email sent');
    } catch (e) {
      return AuthResult.failure('Failed to send verification email');
    }
  }

  /// Check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      if (_currentUser == null) return false;

      await _currentUser!.reload();
      _currentUser = _auth.currentUser;
      
      if (_currentUser!.emailVerified) {
        // Update Firestore
        await _firestoreService.updateUserProfile(_currentUser!.uid, {
          'emailVerified': true,
        });
      }

      return _currentUser!.emailVerified;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  // Security Features

  /// Enable two-factor authentication
  Future<AuthResult> enableTwoFactorAuth() async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('No user signed in');
      }

      // Implementation depends on your 2FA method
      // This is a placeholder for 2FA setup
      
      await _firestoreService.updateUserProfile(_currentUser!.uid, {
        'security.twoFactorEnabled': true,
      });

      return AuthResult.success(_currentUser, 'Two-factor authentication enabled');
    } catch (e) {
      return AuthResult.failure('Failed to enable 2FA');
    }
  }

  /// Link additional auth provider
  Future<AuthResult> linkAuthProvider(AuthCredential credential) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('No user signed in');
      }

      await _currentUser!.linkWithCredential(credential);
      return AuthResult.success(_currentUser, 'Provider linked successfully');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Failed to link provider');
    }
  }

  /// Unlink auth provider
  Future<AuthResult> unlinkAuthProvider(String providerId) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('No user signed in');
      }

      await _currentUser!.unlink(providerId);
      return AuthResult.success(_currentUser, 'Provider unlinked successfully');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Failed to unlink provider');
    }
  }

  // Token Management

  /// Get current ID token
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      if (_currentUser == null) return null;
      return await _currentUser!.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('Error getting ID token: $e');
      return null;
    }
  }

  /// Get current user claims
  Future<Map<String, dynamic>?> getUserClaims() async {
    try {
      if (_currentUser == null) return null;
      final idTokenResult = await _currentUser!.getIdTokenResult();
      return idTokenResult.claims;
    } catch (e) {
      debugPrint('Error getting user claims: $e');
      return null;
    }
  }

  // Storage Management

  /// Store user credentials securely
  Future<void> _storeUserCredentials(User user) async {
    try {
      await _secureStorage.storeUserCredentials(
        email: user.email ?? '',
        userId: user.uid,
      );

      if (_idToken != null) {
        await _secureStorage.storeAuthToken(_idToken!);
      }
    } catch (e) {
      debugPrint('Error storing user credentials: $e');
    }
  }

  /// Check stored credentials
  Future<void> _checkStoredCredentials() async {
    try {
      final credentials = await _secureStorage.getUserCredentials();
      if (credentials != null && _auth.currentUser != null) {
        debugPrint('Found stored credentials for user: ${credentials['userId']}');
      }
    } catch (e) {
      debugPrint('Error checking stored credentials: $e');
    }
  }

  /// Clear stored credentials
  Future<void> _clearStoredCredentials() async {
    try {
      await _secureStorage.delete(SecureStorageService.keyAuthToken);
      await _secureStorage.delete(SecureStorageService.keyRefreshToken);
      await _secureStorage.delete(SecureStorageService.keyUserCredentials);
    } catch (e) {
      debugPrint('Error clearing stored credentials: $e');
    }
  }

  /// Update last sign in time
  Future<void> _updateLastSignInTime(String userId) async {
    try {
      await _firestoreService.updateUserProfile(userId, {
        'analytics.lastActiveDate': FieldValue.serverTimestamp(),
        'lastSignInTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating last sign in time: $e');
    }
  }

  // Validation and Helpers

  /// Validate email and password
  ValidationResult _validateEmailPassword(String email, String password) {
    if (email.isEmpty) {
      return ValidationResult(false, 'Email is required');
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}
        ).hasMatch(email)) {
      return ValidationResult(false, 'Please enter a valid email address');
    }

    if (password.isEmpty) {
      return ValidationResult(false, 'Password is required');
    }

    if (password.length < 6) {
      return ValidationResult(false, 'Password must be at least 6 characters');
    }

    return ValidationResult(true);
  }

  /// Get auth error message
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists for this email';
      case 'invalid-email':
        return 'The email address is invalid';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Invalid verification ID';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account';
      case 'requires-recent-login':
        return 'Please sign in again to continue';
      default:
        return e.message ?? 'An authentication error occurred';
    }
  }

  /// Generate nonce for Apple sign in
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// SHA256 hash of string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Getters

  /// Current user
  User? get currentUser => _currentUser;

  /// Is user signed in
  bool get isSignedIn => _currentUser != null;

  /// Is email verified
  bool get isEmailVerified => _currentUser?.emailVerified ?? false;

  /// User ID
  String? get userId => _currentUser?.uid;

  /// User email
  String? get userEmail => _currentUser?.email;

  /// Auth state stream
  Stream<AuthState> get authStateStream => _authStateController.stream;

  /// Current ID token
  String? get idToken => _idToken;

  // Public Methods

  /// Refresh current user
  Future<void> refreshUser() async {
    try {
      await _currentUser?.reload();
      _currentUser = _auth.currentUser;
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  /// Check if user has custom claims
  Future<bool> hasCustomClaim(String claim) async {
    try {
      final claims = await getUserClaims();
      return claims?.containsKey(claim) ?? false;
    } catch (e) {
      debugPrint('Error checking custom claim: $e');
      return false;
    }
  }

  /// Get user provider data
  List<UserInfo> getUserProviders() {
    return _currentUser?.providerData ?? [];
  }

  /// Check if user is anonymous
  bool get isAnonymous => _currentUser?.isAnonymous ?? false;

  /// Dispose resources
  void dispose() {
    _authStateSubscription?.cancel();
    _tokenRefreshTimer?.cancel();
    _authStateController.close();
    _instance = null;
  }
}

/// Auth result class
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String message;

  AuthResult._(this.isSuccess, this.user, this.message);

  factory AuthResult.success(User? user, String message) {
    return AuthResult._(true, user, message);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(false, null, message);
  }
}

/// Auth state class
class AuthState {
  final AuthStateType type;
  final User? user;
  final String? error;

  AuthState._(this.type, this.user, this.error);

  factory AuthState.loading() => AuthState._(AuthStateType.loading, null, null);
  factory AuthState.authenticated(User user) => AuthState._(AuthStateType.authenticated, user, null);
  factory AuthState.unauthenticated() => AuthState._(AuthStateType.unauthenticated, null, null);
  factory AuthState.error(String error) => AuthState._(AuthStateType.error, null, error);
  factory AuthState.codeSent() => AuthState._(AuthStateType.codeSent, null, null);
}

/// Auth state types
enum AuthStateType {
  loading,
  authenticated,
  unauthenticated,
  error,
  codeSent,
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult(this.isValid, [this.error]);
}