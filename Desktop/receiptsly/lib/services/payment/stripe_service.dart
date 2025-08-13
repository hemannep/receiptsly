// lib/services/payment/stripe_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/environment.dart';
import '../../core/utils/logger.dart';
import '../../core/errors/exceptions.dart';
import '../../data/models/user/user_model.dart';

/// Stripe payment service for handling subscriptions and payments
class StripeService {
  final String _publishableKey;
  final String _secretKey;
  final String _webhookSecret;
  final http.Client _httpClient;
  final Logger _logger;
  
  static const String _baseUrl = 'https://api.stripe.com/v1';
  bool _isInitialized = false;

  StripeService({
    required String publishableKey,
    required String secretKey,
    required String webhookSecret,
    required http.Client httpClient,
    required Logger logger,
  }) : _publishableKey = publishableKey,
       _secretKey = secretKey,
       _webhookSecret = webhookSecret,
       _httpClient = httpClient,
       _logger = logger;

  /// Initialize Stripe SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      Stripe.publishableKey = _publishableKey;
      Stripe.merchantIdentifier = 'merchant.com.receiptsly.app';
      Stripe.urlScheme = 'receiptsly';
      
      await Stripe.instance.applySettings();
      _isInitialized = true;
      _logger.info('Stripe initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize Stripe: $e');
      throw PaymentException('Failed to initialize payment system');
    }
  }

  /// Create customer in Stripe
  Future<StripeCustomer> createCustomer({
    required String email,
    required String name,
    Map<String, String>? metadata,
  }) async {
    try {
      _logger.info('Creating Stripe customer for email: $email');
      
      final response = await _makeStripeRequest(
        'POST',
        '/customers',
        data: {
          'email': email,
          'name': name,
          'metadata': metadata ?? {},
        },
      );
      
      return StripeCustomer.fromJson(response);
    } catch (e) {
      _logger.error('Failed to create Stripe customer: $e');
      throw PaymentException('Failed to create customer account');
    }
  }

  /// Get customer by ID
  Future<StripeCustomer> getCustomer(String customerId) async {
    try {
      final response = await _makeStripeRequest('GET', '/customers/$customerId');
      return StripeCustomer.fromJson(response);
    } catch (e) {
      _logger.error('Failed to get Stripe customer: $e');
      throw PaymentException('Failed to retrieve customer information');
    }
  }

  /// Update customer
  Future<StripeCustomer> updateCustomer(
    String customerId, {
    String? email,
    String? name,
    Map<String, String>? metadata,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (email != null) data['email'] = email;
      if (name != null) data['name'] = name;
      if (metadata != null) data['metadata'] = metadata;
      
      final response = await _makeStripeRequest(
        'POST',
        '/customers/$customerId',
        data: data,
      );
      
      return StripeCustomer.fromJson(response);
    } catch (e) {
      _logger.error('Failed to update Stripe customer: $e');
      throw PaymentException('Failed to update customer information');
    }
  }

  /// Create subscription checkout session
  Future<CheckoutSession> createSubscriptionCheckout({
    required String customerId,
    required String priceId,
    required String successUrl,
    required String cancelUrl,
    Map<String, String>? metadata,
  }) async {
    try {
      _logger.info('Creating subscription checkout for customer: $customerId');
      
      final response = await _makeStripeRequest(
        'POST',
        '/checkout/sessions',
        data: {
          'customer': customerId,
          'payment_method_types': ['card'],
          'line