// lib/core/network/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:receiptsly/core/network/dio_client.dart';

import '../config/environment.dart';
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart' as exceptions;
import 'network_info.dart' hide NetworkException;
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? meta;
  final List<String>? errors;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.meta,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      message: json['message'],
      statusCode: json['statusCode'],
      meta: json['meta'],
      errors: json['errors']?.cast<String>(),
    );
  }

  factory ApiResponse.success({
    T? data,
    String? message,
    int? statusCode,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
      meta: meta,
    );
  }

  factory ApiResponse.error({
    String? message,
    int? statusCode,
    List<String>? errors,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }
}

/// Paginated response wrapper
class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final items =
        (json['data'] as List?)
            ?.map((item) => fromJsonT(item as Map<String, dynamic>))
            .toList() ??
        [];

    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    return PaginatedResponse<T>(
      data: items,
      currentPage: meta['currentPage'] ?? 1,
      totalPages: meta['totalPages'] ?? 1,
      totalItems: meta['totalItems'] ?? 0,
      itemsPerPage: meta['itemsPerPage'] ?? 10,
      hasNextPage: meta['hasNextPage'] ?? false,
      hasPreviousPage: meta['hasPreviousPage'] ?? false,
    );
  }
}

/// HTTP method enumeration
enum HttpMethod { get, post, put, patch, delete }

/// Request configuration
class RequestConfig {
  final Map<String, dynamic>? headers;
  final Duration? timeout;
  final bool requiresAuth;
  final bool enableLogging;
  final ResponseType responseType;
  final String? contentType;

  const RequestConfig({
    this.headers,
    this.timeout,
    this.requiresAuth = true,
    this.enableLogging = true,
    this.responseType = ResponseType.json,
    this.contentType = 'application/json',
  });
}

/// Main API client class
abstract class ApiClient {
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
  });

  Future<ApiResponse<T>> upload<T>(
    String endpoint, {
    required File file,
    Map<String, dynamic>? data,
    String fileFieldName = 'file',
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
    ProgressCallback? onSendProgress,
  });

  Future<ApiResponse<T>> download<T>(
    String endpoint,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    ProgressCallback? onReceiveProgress,
  });

  Future<PaginatedResponse<T>> getPaginated<T>(
    String endpoint, {
    int page = 1,
    int limit = 10,
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    required T Function(Map<String, dynamic>) fromJson,
  });

  void setAuthToken(String token);
  void clearAuthToken();
  void updateBaseUrl(String baseUrl);
  void addGlobalHeader(String key, String value);
  void removeGlobalHeader(String key);
}

/// Implementation of ApiClient using Dio
class DioApiClient implements ApiClient {
  final Dio _dio;
  final NetworkInfo _networkInfo;

  DioApiClient(this._dio, this._networkInfo);

  @override
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _makeRequest<T>(
      HttpMethod.get,
      endpoint,
      queryParameters: queryParameters,
      config: config,
      fromJson: fromJson,
    );
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _makeRequest<T>(
      HttpMethod.post,
      endpoint,
      data: data,
      queryParameters: queryParameters,
      config: config,
      fromJson: fromJson,
    );
  }

  @override
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _makeRequest<T>(
      HttpMethod.put,
      endpoint,
      data: data,
      queryParameters: queryParameters,
      config: config,
      fromJson: fromJson,
    );
  }

  @override
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _makeRequest<T>(
      HttpMethod.patch,
      endpoint,
      data: data,
      queryParameters: queryParameters,
      config: config,
      fromJson: fromJson,
    );
  }

  @override
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _makeRequest<T>(
      HttpMethod.delete,
      endpoint,
      queryParameters: queryParameters,
      config: config,
      fromJson: fromJson,
    );
  }

  @override
  Future<ApiResponse<T>> upload<T>(
    String endpoint, {
    required File file,
    Map<String, dynamic>? data,
    String fileFieldName = 'file',
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
    ProgressCallback? onSendProgress,
  }) async {
    await _checkNetworkConnectivity();

    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        fileFieldName: await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        ...?data,
      });

      final options = _buildOptions(config);
      options.headers?['Content-Type'] = 'multipart/form-data';

      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: formData,
        options: options,
        onSendProgress: onSendProgress,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ApiResponse<T>> download<T>(
    String endpoint,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _checkNetworkConnectivity();

    try {
      final options = _buildOptions(config);

      await _dio.download(
        endpoint,
        savePath,
        queryParameters: queryParameters,
        options: options,
        onReceiveProgress: onReceiveProgress,
      );

      return ApiResponse<T>.success(
        message: 'File downloaded successfully',
        statusCode: 200,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<PaginatedResponse<T>> getPaginated<T>(
    String endpoint, {
    int page = 1,
    int limit = 10,
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final params = {'page': page, 'limit': limit, ...?queryParameters};

    final response = await get<Map<String, dynamic>>(
      endpoint,
      queryParameters: params,
      config: config,
    );

    if (!response.success || response.data == null) {
      throw exceptions.ServerException(
        response.message ?? 'Failed to fetch paginated data',
        null,
        response.statusCode,
      );
    }
    return PaginatedResponse.fromJson(response.data!, fromJson);
  }

  @override
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  @override
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  @override
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  @override
  void addGlobalHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  @override
  void removeGlobalHeader(String key) {
    _dio.options.headers.remove(key);
  }

  /// Make HTTP request
  Future<ApiResponse<T>> _makeRequest<T>(
    HttpMethod method,
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    RequestConfig? config,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    await _checkNetworkConnectivity();

    try {
      final options = _buildOptions(config);
      Response<Map<String, dynamic>> response;

      switch (method) {
        case HttpMethod.get:
          response = await _dio.get<Map<String, dynamic>>(
            endpoint,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case HttpMethod.post:
          response = await _dio.post<Map<String, dynamic>>(
            endpoint,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case HttpMethod.put:
          response = await _dio.put<Map<String, dynamic>>(
            endpoint,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case HttpMethod.patch:
          response = await _dio.patch<Map<String, dynamic>>(
            endpoint,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case HttpMethod.delete:
          response = await _dio.delete<Map<String, dynamic>>(
            endpoint,
            queryParameters: queryParameters,
            options: options,
          );
          break;
      }

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Build request options
  Options _buildOptions(RequestConfig? config) {
    final options = Options(
      headers: config?.headers,
      sendTimeout: config?.timeout,
      receiveTimeout: config?.timeout,
      responseType: config?.responseType ?? ResponseType.json,
      contentType: config?.contentType,
    );

    return options;
  }

  /// Handle API response
  ApiResponse<T> _handleResponse<T>(
    Response<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final responseData = response.data;

    if (responseData == null) {
      return ApiResponse<T>.success(
        statusCode: response.statusCode,
        message: 'Request successful',
      );
    }

    // If the response contains the expected API format
    if (responseData.containsKey('success')) {
      return ApiResponse.fromJson(responseData, fromJson);
    }

    // If the response is direct data
    return ApiResponse<T>.success(
      data: fromJson != null ? fromJson(responseData) : responseData as T?,
      statusCode: response.statusCode,
      message: 'Request successful',
    );
  }

  /// Handle API errors
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return exceptions.ConnectionTimeoutException(
            'Request timeout. Please try again.',
          );

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = _extractErrorMessage(error.response?.data);

          return exceptions.ServerException(
            message ?? 'Server error occurred',
            null,
            statusCode,
          );

        case DioExceptionType.cancel:
          return exceptions.DataException('Request was cancelled');

        case DioExceptionType.connectionError:
          return exceptions.NoInternetException('Network connection error');

        default:
          return exceptions.NetworkException(
            error.message ?? 'Unknown network error',
          );
      }
    }

    if (error is SocketException) {
      return exceptions.NoInternetException('No internet connection');
    }

    return exceptions.ServerException(error.toString());
  }

  /// Extract error message from response
  String? _extractErrorMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData['message'] ??
          responseData['error'] ??
          responseData['errors']?.first;
    }
    return null;
  }

  /// Check network connectivity before making request
  Future<void> _checkNetworkConnectivity() async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      throw exceptions.NoInternetException('No internet connection');
    }
  }
}

// Riverpod providers
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return DioApiClient(dio, networkInfo);
});
