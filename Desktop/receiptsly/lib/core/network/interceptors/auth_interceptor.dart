// lib/core/network/interceptors/auth_interceptor.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../constants/storage_keys.dart';
import '../../errors/exceptions.dart';

/// Authentication interceptor that handles token injection and refresh
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio(); // Separate Dio instance for token refresh

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

  AuthInterceptor() {
    _initializeTokens();
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Skip authentication for certain endpoints
      if (_shouldSkipAuth(options)) {
        handler.next(options);
        return;
      }

      // Wait if token refresh is in progress
      if (_isRefreshing) {
        _pendingRequests.add(options);
        await _waitForTokenRefresh();

        // Retry the request with new token
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
        return;
      }

      // Check if token exists and is valid
      if (_accessToken == null || _isTokenExpired()) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          throw UnauthorizedException('Authentication required');
        }
      }

      // Add token to request
      if (_accessToken != null) {
        options.headers['Authorization'] = 'Bearer $_accessToken';
      }

      handler.next(options);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      try {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry the original request with new token
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $_accessToken';

          final response = await _dio.fetch(requestOptions);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        debugPrint('Token refresh failed: $e');
      }

      // If refresh failed, clear tokens and redirect to login
      await _clearTokens();
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: UnauthorizedException('Session expired'),
          type: DioExceptionType.unknown,
        ),
      );
      return;
    }

    handler.next(err);
  }

  /// Initialize tokens from secure storage
  Future<void> _initializeTokens() async {
    try {
      _accessToken = await _secureStorage.read(
        key: StorageKeys.secureAccessToken,
      );
      _refreshToken = await _secureStorage.read(
        key: StorageKeys.secureRefreshToken,
      );

      if (_accessToken != null) {
        _tokenExpiry = _getTokenExpiry(_accessToken!);
      }
    } catch (e) {
      debugPrint('Failed to initialize tokens: $e');
    }
  }

  /// Check if endpoint should skip authentication
  bool _shouldSkipAuth(RequestOptions options) {
    final path = options.path.toLowerCase();

    // List of endpoints that don't require authentication
    final publicEndpoints = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
      '/auth/forgot-password',
      '/auth/reset-password',
      '/auth/verify-email',
      '/public',
      '/health',
    ];

    return publicEndpoints.any((endpoint) => path.contains(endpoint)) ||
        options.extra['skipAuth'] == true;
  }

  /// Check if current token is expired
  bool _isTokenExpired() {
    if (_tokenExpiry == null || _accessToken == null) return true;

    // Add 5 minute buffer to prevent edge cases
    final buffer = DateTime.now().add(const Duration(minutes: 5));
    return _tokenExpiry!.isBefore(buffer);
  }

  /// Get token expiry from JWT
  DateTime? _getTokenExpiry(String token) {
    try {
      if (JwtDecoder.isExpired(token)) return DateTime.now();
      return JwtDecoder.getExpirationDate(token);
    } catch (e) {
      debugPrint('Failed to decode token expiry: $e');
      return null;
    }
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshAccessToken() async {
    if (_isRefreshing) {
      await _waitForTokenRefresh();
      return _accessToken != null;
    }

    if (_refreshToken == null) {
      return false;
    }

    _isRefreshing = true;

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': _refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'] ?? _refreshToken;

        if (_accessToken != null) {
          _tokenExpiry = _getTokenExpiry(_accessToken!);

          // Store new tokens
          await _storeTokens(_accessToken!, _refreshToken!);

          // Process pending requests
          await _processPendingRequests();

          return true;
        }
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await _clearTokens();
    } finally {
      _isRefreshing = false;
    }

    return false;
  }

  /// Wait for token refresh to complete
  Future<void> _waitForTokenRefresh() async {
    while (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Process requests that were queued during token refresh
  Future<void> _processPendingRequests() async {
    final requests = List<RequestOptions>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final request in requests) {
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }
    }
  }

  /// Store tokens securely
  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    try {
      await Future.wait([
        _secureStorage.write(key: StorageKeys.accessToken, value: accessToken),
        _secureStorage.write(
          key: StorageKeys.refreshToken,
          value: refreshToken,
        ),
      ]);
    } catch (e) {
      debugPrint('Failed to store tokens: $e');
    }
  }

  /// Clear stored tokens
  Future<void> _clearTokens() async {
    try {
      _accessToken = null;
      _refreshToken = null;
      _tokenExpiry = null;

      await Future.wait([
        _secureStorage.delete(key: StorageKeys.accessToken),
        _secureStorage.delete(key: StorageKeys.refreshToken),
      ]);
    } catch (e) {
      debugPrint('Failed to clear tokens: $e');
    }
  }

  /// Set new authentication tokens
  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = _getTokenExpiry(accessToken);

    await _storeTokens(accessToken, refreshToken);
  }

  /// Clear authentication tokens
  Future<void> clearTokens() async {
    await _clearTokens();
  }

  /// Get current access token
  String? get accessToken => _accessToken;

  /// Get current refresh token
  String? get refreshToken => _refreshToken;

  /// Check if user is authenticated
  bool get isAuthenticated => _accessToken != null && !_isTokenExpired();

  /// Get token payload (decoded JWT)
  Map<String, dynamic>? get tokenPayload {
    if (_accessToken == null) return null;

    try {
      return JwtDecoder.decode(_accessToken!);
    } catch (e) {
      debugPrint('Failed to decode token payload: $e');
      return null;
    }
  }

  /// Get user ID from token
  String? get userId {
    final payload = tokenPayload;
    return payload?['sub'] ?? payload?['user_id'] ?? payload?['id'];
  }

  /// Get user email from token
  String? get userEmail {
    final payload = tokenPayload;
    return payload?['email'];
  }

  /// Get user roles from token
  List<String> get userRoles {
    final payload = tokenPayload;
    final roles = payload?['roles'];

    if (roles is List) {
      return roles.cast<String>();
    } else if (roles is String) {
      return [roles];
    }

    return [];
  }

  /// Check if user has specific role
  bool hasRole(String role) {
    return userRoles.contains(role);
  }

  /// Check if user has any of the specified roles
  bool hasAnyRole(List<String> roles) {
    return roles.any((role) => userRoles.contains(role));
  }

  /// Get token time remaining
  Duration? get tokenTimeRemaining {
    if (_tokenExpiry == null) return null;

    final now = DateTime.now();
    if (_tokenExpiry!.isBefore(now)) return null;

    return _tokenExpiry!.difference(now);
  }

  /// Check if token will expire soon (within specified duration)
  bool willExpireSoon([Duration threshold = const Duration(minutes: 10)]) {
    final remaining = tokenTimeRemaining;
    if (remaining == null) return true;

    return remaining <= threshold;
  }

  /// Get token expiry timestamp
  int? get tokenExpiryTimestamp {
    return _tokenExpiry?.millisecondsSinceEpoch;
  }
}

/// Authentication state provider
class AuthState {
  final bool isAuthenticated;
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final String? userEmail;
  final List<String> userRoles;
  final DateTime? tokenExpiry;

  const AuthState({
    required this.isAuthenticated,
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.userEmail,
    this.userRoles = const [],
    this.tokenExpiry,
  });

  factory AuthState.unauthenticated() {
    return const AuthState(isAuthenticated: false);
  }

  factory AuthState.authenticated({
    required String accessToken,
    required String refreshToken,
    String? userId,
    String? userEmail,
    List<String> userRoles = const [],
    DateTime? tokenExpiry,
  }) {
    return AuthState(
      isAuthenticated: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      userEmail: userEmail,
      userRoles: userRoles,
      tokenExpiry: tokenExpiry,
    );
  }

  AuthState copyWith({
    bool? isAuthenticated,
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? userEmail,
    List<String>? userRoles,
    DateTime? tokenExpiry,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userRoles: userRoles ?? this.userRoles,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthState &&
        other.isAuthenticated == isAuthenticated &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.userId == userId &&
        other.userEmail == userEmail &&
        listEquals(other.userRoles, userRoles) &&
        other.tokenExpiry == tokenExpiry;
  }

  @override
  int get hashCode {
    return Object.hash(
      isAuthenticated,
      accessToken,
      refreshToken,
      userId,
      userEmail,
      userRoles,
      tokenExpiry,
    );
  }

  @override
  String toString() {
    return 'AuthState(isAuthenticated: $isAuthenticated, userId: $userId, userEmail: $userEmail)';
  }
}

// Riverpod providers
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor();
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((
  ref,
) {
  return AuthStateNotifier(ref.watch(authInterceptorProvider));
});

/// Auth state notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthInterceptor _authInterceptor;

  AuthStateNotifier(this._authInterceptor)
    : super(AuthState.unauthenticated()) {
    _initializeAuthState();
  }

  /// Initialize auth state from stored tokens
  Future<void> _initializeAuthState() async {
    if (_authInterceptor.isAuthenticated) {
      state = AuthState.authenticated(
        accessToken: _authInterceptor.accessToken!,
        refreshToken: _authInterceptor.refreshToken!,
        userId: _authInterceptor.userId,
        userEmail: _authInterceptor.userEmail,
        userRoles: _authInterceptor.userRoles,
        tokenExpiry: _authInterceptor._tokenExpiry,
      );
    }
  }

  /// Set authentication tokens
  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _authInterceptor.setTokens(accessToken, refreshToken);

    state = AuthState.authenticated(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: _authInterceptor.userId,
      userEmail: _authInterceptor.userEmail,
      userRoles: _authInterceptor.userRoles,
      tokenExpiry: _authInterceptor._tokenExpiry,
    );
  }

  /// Clear authentication
  Future<void> clearAuth() async {
    await _authInterceptor.clearTokens();
    state = AuthState.unauthenticated();
  }

  /// Check if user has specific role
  bool hasRole(String role) {
    return state.userRoles.contains(role);
  }

  /// Check if user has any of the specified roles
  bool hasAnyRole(List<String> roles) {
    return roles.any((role) => state.userRoles.contains(role));
  }
}
