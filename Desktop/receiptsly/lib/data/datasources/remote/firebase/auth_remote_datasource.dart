// lib/data/datasources/remote/firebase/auth_remote_datasource.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../../../../core/errors/exceptions.dart';
import '../../../models/user/user_model.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn =
           googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']),
       _firestore = firestore ?? FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String businessName,
    String businessType = 'freelancer',
    String country = '',
    String currency = 'USD',
  }) async {
    try {
      // Create user account
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(name);

        // Create user profile in Firestore
        await _createUserProfile(
          userCredential.user!,
          name: name,
          businessName: businessName,
          businessType: businessType,
          country: country,
          currency: currency,
        );

        // Send email verification
        await sendEmailVerification();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to sign up: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      if (userCredential.user != null) {
        await _updateLastLogin(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to sign in: $e');
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw RemoteDataException('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(
          userCredential.user!,
          name: googleUser.displayName ?? '',
          businessName: '',
          businessType: 'freelancer',
        );
      } else {
        // Update last login time
        await _updateLastLogin(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to sign in with Google: $e');
    }
  }

  // Sign in with Apple (iOS only)
  Future<UserCredential> signInWithApple() async {
    try {
      // Generate a cryptographically secure random nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credential for the currently signed in Apple account
      final appleCredential = AppleAuthProvider.credential(
        idToken: 'apple_id_token', // This would come from Sign in with Apple
        rawNonce: rawNonce,
      );

      // Sign in with Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(
        appleCredential,
      );

      // Handle new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(
          userCredential.user!,
          name: userCredential.user!.displayName ?? '',
          businessName: '',
          businessType: 'freelancer',
        );
      } else {
        await _updateLastLogin(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to sign in with Apple: $e');
    }
  }

  // Phone authentication - send verification code
  Future<String> sendPhoneVerificationCode({
    required String phoneNumber,
    int timeoutSeconds = 60,
  }) async {
    try {
      String verificationId = '';

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: Duration(seconds: timeoutSeconds),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw RemoteDataException(_mapFirebaseAuthError(e));
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
      );

      return verificationId;
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to send verification code: $e');
    }
  }

  // Verify phone number with code
  Future<UserCredential> verifyPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      // Handle new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(
          userCredential.user!,
          name: '',
          businessName: '',
          businessType: 'freelancer',
        );
      } else {
        await _updateLastLogin(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to verify phone number: $e');
    }
  }

  // Link phone number to existing account
  Future<User> linkPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw RemoteDataException('No user is currently signed in');
      }

      final userCredential = await currentUser.linkWithCredential(credential);
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to link phone number: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to send email verification: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to send password reset email: $e');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw RemoteDataException('No user is currently signed in');
      }
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to update password: $e');
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateEmail(newEmail);
        await sendEmailVerification();
      } else {
        throw RemoteDataException('No user is currently signed in');
      }
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to update email: $e');
    }
  }

  // Re-authenticate user
  Future<void> reauthenticate({
    String? email,
    String? password,
    bool useGoogle = false,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw RemoteDataException('No user is currently signed in');
      }

      AuthCredential credential;

      if (useGoogle) {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw RemoteDataException('Google re-authentication was cancelled');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
      } else if (email != null && password != null) {
        credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
      } else {
        throw RemoteDataException('Invalid re-authentication parameters');
      }

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to re-authenticate: $e');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Delete user profile from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete Firebase Auth account
        await user.delete();
      } else {
        throw RemoteDataException('No user is currently signed in');
      }
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to delete account: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw RemoteDataException('Failed to sign out: $e');
    }
  }

  // Check if email is available
  Future<bool> isEmailAvailable(String email) async {
    try {
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
      return methods.isEmpty;
    } on FirebaseAuthException catch (e) {
      throw RemoteDataException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw RemoteDataException('Failed to check email availability: $e');
    }
  }

  // Get ID token
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        return await user.getIdToken(forceRefresh);
      }
      return null;
    } catch (e) {
      throw RemoteDataException('Failed to get ID token: $e');
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      throw RemoteDataException('Failed to refresh user: $e');
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(
    User user, {
    required String name,
    required String businessName,
    required String businessType,
    String country = '',
    String currency = 'USD',
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);

      final userData = {
        'uid': user.uid,
        'email': user.email,
        'name': name,
        'businessName': businessName,
        'businessType': businessType,
        'country': country,
        'currency': currency,
        'phoneNumber': user.phoneNumber,
        'emailVerified': user.emailVerified,
        'photoURL': user.photoURL,
        'subscription': {
          'plan': 'free',
          'validUntil': null,
          'receiptCount': 0,
          'monthlyLimit': 50,
        },
        'preferences': {
          'defaultCategory': 'General',
          'autoSync': true,
          'offlineMode': true,
          'notifications': true,
          'theme': 'light',
          'currency': currency,
          'language': 'en',
        },
        'chatIntegrations': {
          'whatsapp': {'connected': false},
          'telegram': {'connected': false},
        },
        'stats': {
          'totalReceipts': 0,
          'totalInvoices': 0,
          'totalExpenses': 0.0,
          'totalRevenue': 0.0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      await userDoc.set(userData);

      // Create default categories for the user
      await _createDefaultCategories(user.uid);
    } catch (e) {
      throw RemoteDataException('Failed to create user profile: $e');
    }
  }

  // Create default categories
  Future<void> _createDefaultCategories(String userId) async {
    try {
      final batch = _firestore.batch();
      final categoriesRef = _firestore.collection('categories');

      final defaultCategories = [
        {'name': 'Office Supplies', 'color': '#2196F3', 'icon': 'office'},
        {'name': 'Food & Dining', 'color': '#FF9800', 'icon': 'restaurant'},
        {
          'name': 'Transportation',
          'color': '#4CAF50',
          'icon': 'directions_car',
        },
        {
          'name': 'Software & Technology',
          'color': '#9C27B0',
          'icon': 'computer',
        },
        {
          'name': 'Marketing & Advertising',
          'color': '#E91E63',
          'icon': 'campaign',
        },
        {
          'name': 'Travel & Accommodation',
          'color': '#00BCD4',
          'icon': 'flight',
        },
        {
          'name': 'Professional Services',
          'color': '#795548',
          'icon': 'business',
        },
        {
          'name': 'Equipment & Supplies',
          'color': '#607D8B',
          'icon': 'hardware',
        },
        {
          'name': 'Utilities',
          'color': '#FFC107',
          'icon': 'electrical_services',
        },
        {'name': 'General', 'color': '#757575', 'icon': 'category'},
      ];

      for (final category in defaultCategories) {
        final categoryDoc = categoriesRef.doc();
        batch.set(categoryDoc, {
          ...category,
          'userId': userId,
          'isDefault': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw RemoteDataException('Failed to create default categories: $e');
    }
  }

  // Update last login time
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw error for last login update failure
      print('Failed to update last login: $e');
    }
  }

  // Generate cryptographically secure nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // Generate SHA256 hash
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Map Firebase Auth errors to user-friendly messages
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please request a new code.';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      case 'provider-already-linked':
        return 'This account is already linked with this provider.';
      case 'no-such-provider':
        return 'This account is not linked with this provider.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}
