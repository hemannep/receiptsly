// lib/services/payment/paypal_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import '../../core/config/environment.dart';
import '../../core/utils/logger.dart';
import '../../core/errors/exceptions.dart';

/// PayPal payment service for alternative payment processing
class PayPalService {
  final String _clientId;
  final String _clientSecret;
  final String _webhookId;
  final bool _isProduction;
  final http.Client _httpClient;
  final Logger _logger;
  
  String? _accessToken;
  DateTime? _tokenExpiry;
  
  late final String _baseUrl;
  
  PayPalService({
    required String clientId,
    required String clientSecret,
    required String webhookId,
    required bool isProduction,
    required http.Client httpClient,
    required Logger logger,
  }) : _clientId = clientId,
       _clientSecret = clientSecret,
       _webhookId = webhookId,
       _isProduction = isProduction,
       _httpClient = httpClient,
       _logger = logger {
    
    _baseUrl = _isProduction
        ? 'https://api-m.paypal.com'
        : 'https://api-m.sandbox.paypal.com';
  }

  /// Get access token for API authentication
  Future<String> _getAccessToken() async {
    // Return cached token if still valid
    if (_accessToken != null && 
        _tokenExpiry != null && 
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    try {
      _logger.info('Requesting new PayPal access token');
      
      final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
      
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/v1/oauth2/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      );

      if (response.statusCode != 200) {
        throw PayPalException('Failed to get access token: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['access_token'] as String;
      
      final expiresIn = data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); // 1 min buffer
      
      _logger.info('PayPal access token obtained successfully');
      return _accessToken!;
      
    } catch (e) {
      _logger.error('Failed to get PayPal access token: $e');
      throw PayPalException('Authentication failed: ${e.toString()}');
    }
  }

  /// Create a payment order
  Future<PayPalOrder> createOrder({
    required double amount,
    required String currency,
    required String returnUrl,
    required String cancelUrl,
    String? description,
    Map<String, String>? customId,
  }) async {
    try {
      _logger.info('Creating PayPal order for amount: $amount $currency');
      
      final token = await