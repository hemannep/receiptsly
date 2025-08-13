// lib/core/network/network_info.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connectivity information provider
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
  Future<NetworkStatus> get networkStatus;
  Future<bool> hasInternetAccess();
  Future<ConnectionType> get connectionType;
}

/// Implementation of NetworkInfo
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl(this._connectivity);

  @override
  Future<bool> get isConnected async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return _isConnectionActive(connectivityResult as ConnectivityResult);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((result) {
      return _isConnectionActive(result as ConnectivityResult);
    });
  }

  @override
  Future<NetworkStatus> get networkStatus async {
    final hasConnection = await isConnected;
    if (!hasConnection) {
      return NetworkStatus.offline;
    }

    final hasInternet = await hasInternetAccess();
    return hasInternet ? NetworkStatus.online : NetworkStatus.noInternet;
  }

  @override
  Future<bool> hasInternetAccess() async {
    try {
      // Try to lookup Google's DNS server
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  @override
  Future<ConnectionType> get connectionType async {
    final connectivityResult = await _connectivity.checkConnectivity();

    switch (connectivityResult) {
      case ConnectivityResult.wifi:
        return ConnectionType.wifi;
      case ConnectivityResult.mobile:
        return ConnectionType.mobile;
      case ConnectivityResult.ethernet:
        return ConnectionType.ethernet;
      case ConnectivityResult.bluetooth:
        return ConnectionType.bluetooth;
      case ConnectivityResult.vpn:
        return ConnectionType.vpn;
      case ConnectivityResult.other:
        return ConnectionType.other;
      case ConnectivityResult.none:
      default:
        return ConnectionType.none;
    }
  }

  /// Helper method to determine if connection is active
  bool _isConnectionActive(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }
}

/// Network status enumeration
enum NetworkStatus { online, offline, noInternet }

/// Connection type enumeration
enum ConnectionType { wifi, mobile, ethernet, bluetooth, vpn, other, none }

/// Network monitoring service
class NetworkMonitoringService {
  static NetworkMonitoringService? _instance;
  static NetworkMonitoringService get instance =>
      _instance ??= NetworkMonitoringService._();

  NetworkMonitoringService._();

  final StreamController<NetworkStatus> _networkStatusController =
      StreamController<NetworkStatus>.broadcast();

  StreamSubscription<bool>? _connectivitySubscription;
  NetworkStatus _currentStatus = NetworkStatus.offline;

  Stream<NetworkStatus> get networkStatusStream =>
      _networkStatusController.stream;
  NetworkStatus get currentStatus => _currentStatus;

  /// Initialize network monitoring
  void initialize(NetworkInfo networkInfo) {
    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((
      isConnected,
    ) async {
      if (isConnected) {
        final hasInternet = await networkInfo.hasInternetAccess();
        _updateNetworkStatus(
          hasInternet ? NetworkStatus.online : NetworkStatus.noInternet,
        );
      } else {
        _updateNetworkStatus(NetworkStatus.offline);
      }
    });

    // Check initial status
    _checkInitialStatus(networkInfo);
  }

  /// Check initial network status
  Future<void> _checkInitialStatus(NetworkInfo networkInfo) async {
    final status = await networkInfo.networkStatus;
    _updateNetworkStatus(status);
  }

  /// Update network status and notify listeners
  void _updateNetworkStatus(NetworkStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _networkStatusController.add(status);
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _networkStatusController.close();
  }
}

/// Network exception class
class NetworkException implements Exception {
  final String message;
  final NetworkErrorType type;
  final int? statusCode;
  final dynamic originalError;

  const NetworkException({
    required this.message,
    required this.type,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() =>
      'NetworkException: $message (Type: $type, Status: $statusCode)';
}

/// Network error types
enum NetworkErrorType {
  noConnection,
  timeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  unknown,
}

/// Network utility class
class NetworkUtils {
  /// Check if error is related to network connectivity
  static bool isNetworkError(dynamic error) {
    if (error is NetworkException) {
      return error.type == NetworkErrorType.noConnection;
    }

    if (error is SocketException) {
      return true;
    }

    return false;
  }

  /// Get user-friendly network error message
  static String getNetworkErrorMessage(NetworkException error) {
    switch (error.type) {
      case NetworkErrorType.noConnection:
        return 'No internet connection. Please check your network settings.';
      case NetworkErrorType.timeout:
        return 'Request timed out. Please try again.';
      case NetworkErrorType.badRequest:
        return 'Invalid request. Please check your input.';
      case NetworkErrorType.unauthorized:
        return 'You are not authorized to perform this action.';
      case NetworkErrorType.forbidden:
        return 'Access denied. You don\'t have permission for this action.';
      case NetworkErrorType.notFound:
        return 'Requested resource not found.';
      case NetworkErrorType.serverError:
        return 'Server error occurred. Please try again later.';
      case NetworkErrorType.unknown:
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Convert HTTP status code to NetworkErrorType
  static NetworkErrorType getErrorTypeFromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return NetworkErrorType.badRequest;
      case 401:
        return NetworkErrorType.unauthorized;
      case 403:
        return NetworkErrorType.forbidden;
      case 404:
        return NetworkErrorType.notFound;
      case >= 500:
        return NetworkErrorType.serverError;
      default:
        return NetworkErrorType.unknown;
    }
  }
}

// Riverpod providers
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(ref.watch(connectivityProvider));
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.networkStatus.asStream().asyncExpand((
    initialStatus,
  ) async* {
    yield initialStatus;
    yield* NetworkMonitoringService.instance.networkStatusStream;
  });
});

final connectionTypeProvider = FutureProvider<ConnectionType>((ref) {
  return ref.watch(networkInfoProvider).connectionType;
});

final isConnectedProvider = StreamProvider<bool>((ref) {
  return ref.watch(networkInfoProvider).onConnectivityChanged;
});
