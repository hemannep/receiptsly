// lib/domain/repositories/i_auth_repository.dart
import 'dart:async';
import '../entities/user_entity.dart';

/// Authentication repository interface defining all authentication operations
/// This interface is implemented by the data layer and used by use cases
abstract class IAuthRepository {
  /// Stream of authentication state changes
  /// Returns the current user entity when authenticated, null when not
  Stream<UserEntity?> get authStateChanges;

  /// Get the currently authenticated user
  /// Returns null if no user is authenticated
  Future<UserEntity?> getCurrentUser();

  /// Register a new user with email and password
  /// [email] - User's email address
  /// [password] - User's password
  /// [businessData] - Additional business profile data
  /// Returns [AuthResult] with success status and user data
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required BusinessProfileData businessData,
  });

  /// Sign in user with email and password
  /// [email] - User's email address
  /// [password] - User's password
  /// Returns [AuthResult] with success status and user data
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in user with Google OAuth
  /// Returns [AuthResult] with success status and user data
  Future<AuthResult> signInWithGoogle();

  /// Sign in user with Apple OAuth (iOS only)
  /// Returns [AuthResult] with success status and user data
  Future<AuthResult> signInWithApple();

  /// Start phone number verification process
  /// [phoneNumber] - Phone number in international format
  /// [onCodeSent] - Callback when verification code is sent
  /// [onVerificationCompleted] - Callback when auto-verification succeeds
  /// [onVerificationFailed] - Callback when verification fails
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(UserEntity user) onVerificationCompleted,
    required Function(String error) onVerificationFailed,
  });

  /// Complete phone number verification with SMS code
  /// [verificationId] - ID received from verifyPhoneNumber
  /// [smsCode] - 6-digit code received via SMS
  /// Returns [AuthResult] with success status
  Future<AuthResult> confirmPhoneVerification({
    required String verificationId,
    required String smsCode,
  });

  /// Send password reset email
  /// [email] - User's email address
  /// Throws [AuthException] if email is not found
  Future<void> sendPasswordResetEmail(String email);

  /// Send email verification to current user
  /// Throws [AuthException] if no user is signed in
  Future<void> sendEmailVerification();

  /// Check if email verification is required for current user
  /// Returns true if user exists and email is not verified
  Future<bool> isEmailVerificationRequired();

  /// Refresh current user's authentication token
  /// Returns updated [UserEntity] or null if refresh failed
  Future<UserEntity?> refreshUser();

  /// Update user's password
  /// [currentPassword] - User's current password for verification
  /// [newPassword] - New password to set
  /// Throws [AuthException] if current password is incorrect
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Update user's email address
  /// [newEmail] - New email address
  /// [password] - Current password for verification
  /// Throws [AuthException] if password is incorrect
  Future<void> updateEmail({
    required String newEmail,
    required String password,
  });

  /// Link phone number to current user account
  /// [phoneNumber] - Phone number to link
  /// [verificationId] - Verification ID from phone verification
  /// [smsCode] - SMS verification code
  Future<AuthResult> linkPhoneNumber({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  });

  /// Unlink phone number from current user account
  Future<void> unlinkPhoneNumber();

  /// Link Google account to current user
  Future<AuthResult> linkGoogleAccount();

  /// Unlink Google account from current user
  Future<void> unlinkGoogleAccount();

  /// Update user profile data
  /// [userData] - Updated user profile data
  /// Returns updated [UserEntity]
  Future<UserEntity> updateUserProfile(UserProfileUpdate userData);

  /// Update user business profile
  /// [businessData] - Updated business profile data
  /// Returns updated [UserEntity]
  Future<UserEntity> updateBusinessProfile(BusinessProfileData businessData);

  /// Update user preferences
  /// [preferences] - Updated user preferences
  /// Returns updated [UserEntity]
  Future<UserEntity> updateUserPreferences(UserPreferences preferences);

  /// Connect chat integration
  /// [platform] - Chat platform (whatsapp, telegram)
  /// [integrationData] - Platform-specific integration data
  /// Returns updated [UserEntity]
  Future<UserEntity> connectChatIntegration({
    required String platform,
    required Map<String, dynamic> integrationData,
  });

  /// Disconnect chat integration
  /// [platform] - Chat platform to disconnect
  /// Returns updated [UserEntity]
  Future<UserEntity> disconnectChatIntegration(String platform);

  /// Update user subscription
  /// [subscription] - New subscription data
  /// Returns updated [UserEntity]
  Future<UserEntity> updateSubscription(Subscription subscription);

  /// Update user statistics
  /// [stats] - Updated user statistics
  /// Returns updated [UserEntity]
  Future<UserEntity> updateUserStats(UserStats stats);

  /// Delete user account and all associated data
  /// [password] - Current password for verification
  /// This operation is irreversible
  Future<void> deleteAccount(String password);

  /// Sign out the current user
  /// Clears all local authentication data
  Future<void> signOut();

  /// Check if user with email already exists
  /// [email] - Email to check
  /// Returns true if user exists
  Future<bool> checkEmailExists(String email);

  /// Check if phone number is already linked to an account
  /// [phoneNumber] - Phone number to check
  /// Returns true if phone number is linked
  Future<bool> checkPhoneExists(String phoneNumber);

  /// Get user by email (admin function)
  /// [email] - Email to search for
  /// Returns [UserEntity] or null if not found
  Future<UserEntity?> getUserByEmail(String email);

  /// Get user by phone number (admin function)
  /// [phoneNumber] - Phone number to search for
  /// Returns [UserEntity] or null if not found
  Future<UserEntity?> getUserByPhoneNumber(String phoneNumber);

  /// Validate authentication token
  /// [token] - Token to validate
  /// Returns true if token is valid
  Future<bool> validateToken(String token);

  /// Get user's authentication providers
  /// Returns list of linked providers (email, google, apple, phone)
  Future<List<String>> getLinkedProviders();

  /// Re-authenticate user with credentials
  /// Required before sensitive operations like password change or account deletion
  /// [email] - User's email
  /// [password] - User's current password
  Future<void> reauthenticate({
    required String email,
    required String password,
  });

  /// Check if reauthentication is required
  /// Returns true if user needs to reauthenticate for sensitive operations
  Future<bool> isReauthenticationRequired();
}

/// Result of authentication operations
class AuthResult {
  final bool success;
  final UserEntity? user;
  final String? errorMessage;
  final AuthErrorCode? errorCode;
  final Map<String, dynamic>? additionalData;

  const AuthResult({
    required this.success,
    this.user,
    this.errorMessage,
    this.errorCode,
    this.additionalData,
  });

  /// Create successful auth result
  factory AuthResult.success({
    UserEntity? user,
    Map<String, dynamic>? additionalData,
  }) {
    return AuthResult(
      success: true,
      user: user,
      additionalData: additionalData,
    );
  }

  /// Create failed auth result
  factory AuthResult.failure({
    required String errorMessage,
    AuthErrorCode? errorCode,
    Map<String, dynamic>? additionalData,
  }) {
    return AuthResult(
      success: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
      additionalData: additionalData,
    );
  }

  @override
  String toString() {
    return 'AuthResult(success: $success, errorMessage: $errorMessage, errorCode: $errorCode)';
  }
}

/// Business profile data for user registration and updates
class BusinessProfileData {
  final String businessName;
  final BusinessType businessType;
  final String? businessAddress;
  final String? taxId;
  final String country;
  final String currency;
  final String? website;
  final String? logo;

  const BusinessProfileData({
    required this.businessName,
    required this.businessType,
    this.businessAddress,
    this.taxId,
    required this.country,
    required this.currency,
    this.website,
    this.logo,
  });

  /// Convert to map for API calls
  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'businessType': businessType.toString().split('.').last,
      'businessAddress': businessAddress,
      'taxId': taxId,
      'country': country,
      'currency': currency,
      'website': website,
      'logo': logo,
    };
  }

  /// Create from map
  factory BusinessProfileData.fromMap(Map<String, dynamic> map) {
    return BusinessProfileData(
      businessName: map['businessName'] ?? '',
      businessType: BusinessType.values.firstWhere(
        (e) => e.toString().split('.').last == map['businessType'],
        orElse: () => BusinessType.freelancer,
      ),
      businessAddress: map['businessAddress'],
      taxId: map['taxId'],
      country: map['country'] ?? '',
      currency: map['currency'] ?? 'USD',
      website: map['website'],
      logo: map['logo'],
    );
  }

  BusinessProfileData copyWith({
    String? businessName,
    BusinessType? businessType,
    String? businessAddress,
    String? taxId,
    String? country,
    String? currency,
    String? website,
    String? logo,
  }) {
    return BusinessProfileData(
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      businessAddress: businessAddress ?? this.businessAddress,
      taxId: taxId ?? this.taxId,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      website: website ?? this.website,
      logo: logo ?? this.logo,
    );
  }
}

/// User profile update data
class UserProfileUpdate {
  final String? name;
  final String? phoneNumber;
  final String? profileImageUrl;

  const UserProfileUpdate({this.name, this.phoneNumber, this.profileImageUrl});

  /// Check if update contains any data
  bool get hasUpdates {
    return name != null || phoneNumber != null || profileImageUrl != null;
  }

  /// Convert to map for API calls
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (phoneNumber != null) map['phoneNumber'] = phoneNumber;
    if (profileImageUrl != null) map['profileImageUrl'] = profileImageUrl;
    return map;
  }

  UserProfileUpdate copyWith({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) {
    return UserProfileUpdate(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

/// Authentication error codes
enum AuthErrorCode {
  // Email/Password errors
  emailAlreadyInUse,
  invalidEmail,
  weakPassword,
  userNotFound,
  wrongPassword,
  userDisabled,

  // Phone verification errors
  invalidPhoneNumber,
  invalidVerificationCode,
  invalidVerificationId,
  quotaExceeded,

  // OAuth errors
  accountExistsWithDifferentCredential,
  credentialAlreadyInUse,
  operationNotAllowed,

  // Network and general errors
  networkRequestFailed,
  tooManyRequests,
  operationNotSupported,
  internalError,

  // Custom business logic errors
  emailVerificationRequired,
  phoneVerificationRequired,
  subscriptionExpired,
  accountSuspended,
  reauthenticationRequired,

  // Unknown error
  unknown,
}

/// Authentication exceptions
class AuthException implements Exception {
  final String message;
  final AuthErrorCode code;
  final dynamic originalException;

  const AuthException({
    required this.message,
    required this.code,
    this.originalException,
  });

  @override
  String toString() {
    return 'AuthException: $message (code: $code)';
  }

  /// Create from Firebase Auth exception
  factory AuthException.fromFirebaseAuth(dynamic firebaseException) {
    final code = firebaseException.code as String?;
    final message =
        firebaseException.message as String? ?? 'Authentication failed';

    final authErrorCode = _mapFirebaseErrorCode(code);

    return AuthException(
      message: message,
      code: authErrorCode,
      originalException: firebaseException,
    );
  }

  /// Create custom auth exception
  factory AuthException.custom({
    required String message,
    required AuthErrorCode code,
  }) {
    return AuthException(message: message, code: code);
  }

  /// Map Firebase error codes to our enum
  static AuthErrorCode _mapFirebaseErrorCode(String? firebaseCode) {
    switch (firebaseCode) {
      case 'email-already-in-use':
        return AuthErrorCode.emailAlreadyInUse;
      case 'invalid-email':
        return AuthErrorCode.invalidEmail;
      case 'weak-password':
        return AuthErrorCode.weakPassword;
      case 'user-not-found':
        return AuthErrorCode.userNotFound;
      case 'wrong-password':
        return AuthErrorCode.wrongPassword;
      case 'user-disabled':
        return AuthErrorCode.userDisabled;
      case 'invalid-phone-number':
        return AuthErrorCode.invalidPhoneNumber;
      case 'invalid-verification-code':
        return AuthErrorCode.invalidVerificationCode;
      case 'invalid-verification-id':
        return AuthErrorCode.invalidVerificationId;
      case 'quota-exceeded':
        return AuthErrorCode.quotaExceeded;
      case 'account-exists-with-different-credential':
        return AuthErrorCode.accountExistsWithDifferentCredential;
      case 'credential-already-in-use':
        return AuthErrorCode.credentialAlreadyInUse;
      case 'operation-not-allowed':
        return AuthErrorCode.operationNotAllowed;
      case 'network-request-failed':
        return AuthErrorCode.networkRequestFailed;
      case 'too-many-requests':
        return AuthErrorCode.tooManyRequests;
      default:
        return AuthErrorCode.unknown;
    }
  }
}
