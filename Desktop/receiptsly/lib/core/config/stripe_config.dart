// lib/core/config/stripe_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'environment.dart';
import 'app_config.dart';

/// Stripe payment configuration for Receiptsly
/// Manages environment-specific Stripe settings and payment processing
class StripeConfig {
  static StripeConfig? _instance;
  static StripeConfig get instance => _instance ??= StripeConfig._internal();

  StripeConfig._internal();

  bool _isInitialized = false;

  // Environment-specific Stripe keys
  static const Map<Environment, Map<String, String>> _stripeKeys = {
    Environment.development: {
      'publishableKey': 'pk_test_51DevYourDevPublishableKeyHere',
      'secretKey': 'sk_test_51DevYourDevSecretKeyHere',
      'webhookSecret': 'whsec_DevYourWebhookSecretHere',
    },
    Environment.staging: {
      'publishableKey': 'pk_test_51StagingYourStagingPublishableKeyHere',
      'secretKey': 'sk_test_51StagingYourStagingSecretKeyHere',
      'webhookSecret': 'whsec_StagingYourWebhookSecretHere',
    },
    Environment.production: {
      'publishableKey': 'pk_live_YourProductionPublishableKeyHere',
      'secretKey': 'sk_live_YourProductionSecretKeyHere',
      'webhookSecret': 'whsec_YourProductionWebhookSecretHere',
    },
  };

  // Subscription plans configuration
  static const Map<String, Map<String, dynamic>> _subscriptionPlans = {
    'free': {
      'name': 'Free Plan',
      'priceId': null,
      'amount': 0,
      'currency': 'usd',
      'interval': 'month',
      'features': [
        '50 receipts per month',
        '10 invoices per month',
        '5 clients',
        'Basic OCR',
        'PDF export',
      ],
    },
    'basic': {
      'name': 'Basic Plan',
      'priceId': 'price_basic_monthly',
      'amount': 999, // $9.99 in cents
      'currency': 'usd',
      'interval': 'month',
      'features': [
        '500 receipts per month',
        'Unlimited invoices',
        '25 clients',
        'Advanced OCR',
        'Multiple export formats',
        'WhatsApp/Telegram integration',
        'Priority support',
      ],
    },
    'premium': {
      'name': 'Premium Plan',
      'priceId': 'price_premium_monthly',
      'amount': 1999, // $19.99 in cents
      'currency': 'usd',
      'interval': 'month',
      'features': [
        'Unlimited receipts',
        'Unlimited invoices',
        'Unlimited clients',
        'AI-powered categorization',
        'Advanced reporting',
        'API access',
        'Custom integrations',
        'Dedicated support',
      ],
    },
  };

  // Payment method types
  static const List<String> _supportedPaymentMethods = [
    'card',
    'apple_pay',
    'google_pay',
  ];

  // Currency configuration
  static const Map<String, Map<String, dynamic>> _currencyConfig = {
    'usd': {
      'symbol':
          r'$', // Using raw string (r'') to treat $ literally, or just '$'
      'name': 'US Dollar',
      'locale': 'en_US',
      'decimalDigits': 2,
    },
    'eur': {
      'symbol': '€',
      'name': 'Euro',
      'locale': 'en_EU',
      'decimalDigits': 2,
    },
    'gbp': {
      'symbol': '£',
      'name': 'British Pound',
      'locale': 'en_GB',
      'decimalDigits': 2,
    },
    'cad': {
      'symbol': r'C$', // or 'C\$'
      'name': 'Canadian Dollar',
      'locale': 'en_CA',
      'decimalDigits': 2,
    },
    'aud': {
      'symbol': r'A$', // or 'A\$'
      'name': 'Australian Dollar',
      'locale': 'en_AU',
      'decimalDigits': 2,
    },
  };

  // Payment configuration
  static const Map<String, dynamic> _paymentConfig = {
    'allowsDelayedPaymentMethods': true,
    'appearance': {
      'colorPrimary': '#007AFF',
      'colorBackground': '#FFFFFF',
      'colorComponentBackground': '#F7F7F7',
      'colorComponentBorder': '#E1E1E1',
      'colorComponentDivider': '#E1E1E1',
      'colorComponentText': '#000000',
      'colorText': '#000000',
      'colorTextSecondary': '#6D6D6D',
      'borderRadius': 8,
      'fontFamily': 'SF Pro Display',
    },
    'defaultBillingDetails': {
      'name': '',
      'email': '',
      'phone': '',
      'address': {'country': 'US', 'postalCode': ''},
    },
  };

  /// Initialize Stripe with environment-specific configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final environment = AppConfig.instance.environment;
      final keys = _stripeKeys[environment];

      if (keys == null || keys['publishableKey'] == null) {
        throw Exception(
          'Stripe keys not found for environment: ${environment.name}',
        );
      }

      // Initialize Stripe
      Stripe.publishableKey = keys['publishableKey']!;

      // Configure Stripe settings
      await _configureStripe();

      _isInitialized = true;

      if (kDebugMode) {
        print('💳 Stripe initialized for ${environment.name}');
        print(
          '🔑 Using publishable key: ${keys['publishableKey']!.substring(0, 12)}...',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Stripe initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Configure Stripe settings and appearance
  Future<void> _configureStripe() async {
    try {
      // Set merchant identifier for Apple Pay
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        Stripe.merchantIdentifier = 'merchant.com.receiptsly.app';
      }

      // Configure payment sheet appearance
      await Stripe.instance.applySettings();

      if (kDebugMode) {
        print('⚙️ Stripe settings applied');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Stripe configuration failed: $e');
      }
      rethrow;
    }
  }

  /// Create payment intent for one-time payments
  Future<PaymentIntent> createPaymentIntent({
    required int amount,
    required String currency,
    String? customerId,
    String? description,
    Map<String, String>? metadata,
  }) async {
    _ensureInitialized();

    try {
      // This would typically call your backend API
      // For demo purposes, showing the structure
      final paymentIntent = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      if (kDebugMode) {
        print(
          '💰 Payment intent created for ${_formatAmount(amount, currency)}',
        );
      }

      return PaymentIntent(
        id: paymentIntent.id,
        amount: amount,
        currency: currency,
        status: PaymentIntentsStatus.RequiresPaymentMethod,
        created: (DateTime.now().millisecondsSinceEpoch ~/ 1000)
            .toString(), // current timestamp in seconds
        clientSecret:
            paymentIntent.clientSecret ??
            '', // or generate one if not available
        livemode: false, // or true if in production
        captureMethod: 'automatic', // or 'manual'
        confirmationMethod: 'automatic', // or 'manual'
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Payment intent creation failed: $e');
      }
      rethrow;
    }
  }

  /// Create subscription for recurring payments
  Future<String> createSubscription({
    required String customerId,
    required String priceId,
    Map<String, String>? metadata,
  }) async {
    _ensureInitialized();

    try {
      // This would typically call your backend API
      // For demo purposes, showing the structure

      if (kDebugMode) {
        print('🔄 Subscription created for customer: $customerId');
      }

      return 'sub_test_subscription_id';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Subscription creation failed: $e');
      }
      rethrow;
    }
  }

  /// Present payment sheet for checkout
  Future<PaymentSheetPaymentOption?> presentPaymentSheet({
    required String clientSecret,
    String? customerId,
    String? customerEphemeralKeySecret,
  }) async {
    _ensureInitialized();

    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          customerId: customerId,
          customerEphemeralKeySecret: customerEphemeralKeySecret,
          merchantDisplayName: 'Receiptsly',
          allowsDelayedPaymentMethods:
              _paymentConfig['allowsDelayedPaymentMethods'],
          style: ThemeMode.system,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(
                int.parse(
                      _paymentConfig['appearance']['colorPrimary'].substring(1),
                      radix: 16,
                    ) +
                    0xFF000000,
              ),
              background: Color(
                int.parse(
                      _paymentConfig['appearance']['colorBackground'].substring(
                        1,
                      ),
                      radix: 16,
                    ) +
                    0xFF000000,
              ),
              componentBackground: Color(
                int.parse(
                      _paymentConfig['appearance']['colorComponentBackground']
                          .substring(1),
                      radix: 16,
                    ) +
                    0xFF000000,
              ),
            ),
            shapes: const PaymentSheetShape(borderRadius: 8, borderWidth: 1),
          ),
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      if (kDebugMode) {
        print('✅ Payment completed successfully');
      }

      return null; // Success
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        if (kDebugMode) {
          print('❌ Payment cancelled by user');
        }
        return null;
      } else {
        if (kDebugMode) {
          print('❌ Payment failed: ${e.error.message}');
        }
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Payment sheet presentation failed: $e');
      }
      rethrow;
    }
  }

  /// Check if Apple Pay is supported
  Future<bool> isApplePaySupported() async {
    try {
      return await Stripe.instance.isApplePaySupported();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Apple Pay check failed: $e');
      }
      return false;
    }
  }

  /// Check if Google Pay is supported
  Future<bool> isGooglePaySupported() async {
    try {
      return await Stripe.instance.isGooglePaySupported();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google Pay check failed: $e');
      }
      return false;
    }
  }

  /// Present Apple Pay payment sheet
  Future<void> presentApplePay({
    required List<ApplePayCartSummaryItem> cartItems,
    required String country,
    required String currency,
  }) async {
    _ensureInitialized();

    try {
      await Stripe.instance.presentApplePay(
        params: ApplePayPresentParams(
          cartItems: cartItems,
          country: country,
          currency: currency,
        ),
      );

      if (kDebugMode) {
        print('🍎 Apple Pay payment completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Apple Pay payment failed: $e');
      }
      rethrow;
    }
  }

  /// Present Google Pay payment sheet
  Future<void> presentGooglePay({
    required String clientSecret,
    required String country,
    required String currency,
    required int amount,
  }) async {
    _ensureInitialized();

    try {
      await Stripe.instance.initGooglePay(
        GooglePayInitParams(
          testEnv: !AppConfig.instance.isProduction,
          existingPaymentMethodRequired: false,
          merchantName: 'Receiptsly',
          countryCode: country,
        ),
      );

      await Stripe.instance.presentGooglePay(
        PresentGooglePayParams(
          clientSecret: clientSecret,
          forSetupIntent: false,
        ),
      );

      if (kDebugMode) {
        print('🤖 Google Pay payment completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google Pay payment failed: $e');
      }
      rethrow;
    }
  }

  // Getters
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception(
        'Stripe not initialized. Call StripeConfig.instance.initialize() first.',
      );
    }
  }

  /// Get publishable key for current environment
  String? get publishableKey {
    final environment = AppConfig.instance.environment;
    return _stripeKeys[environment]?['publishableKey'];
  }

  /// Get webhook secret for current environment
  String? get webhookSecret {
    final environment = AppConfig.instance.environment;
    return _stripeKeys[environment]?['webhookSecret'];
  }

  /// Get subscription plans
  Map<String, Map<String, dynamic>> get subscriptionPlans => _subscriptionPlans;

  /// Get supported payment methods
  List<String> get supportedPaymentMethods => _supportedPaymentMethods;

  /// Get currency configuration
  Map<String, Map<String, dynamic>> get currencyConfig => _currencyConfig;

  /// Get plan details by plan ID
  Map<String, dynamic>? getPlanDetails(String planId) {
    return _subscriptionPlans[planId];
  }

  /// Get plan price in cents
  int getPlanPrice(String planId) {
    return _subscriptionPlans[planId]?['amount'] ?? 0;
  }

  /// Get plan features
  List<String> getPlanFeatures(String planId) {
    return List<String>.from(_subscriptionPlans[planId]?['features'] ?? []);
  }

  /// Format amount for display
  String formatAmount(int amountInCents, String currency) {
    return _formatAmount(amountInCents, currency);
  }

  String _formatAmount(int amountInCents, String currency) {
    final config = _currencyConfig[currency.toLowerCase()];
    if (config == null) return '$amountInCents';

    final symbol = config['symbol'] as String;
    final decimalDigits = config['decimalDigits'] as int;
    final amount = amountInCents / (100 * decimalDigits);

    return '$symbol${amount.toStringAsFixed(decimalDigits)}';
  }

  /// Get currency symbol
  String getCurrencySymbol(String currency) {
    return _currencyConfig[currency.toLowerCase()]?['symbol'] ??
        currency.toUpperCase();
  }

  /// Validate payment amount
  bool isValidAmount(int amountInCents, String currency) {
    // Minimum charge amounts by currency (in cents)
    const minimumAmounts = {
      'usd': 50, // $0.50
      'eur': 50, // €0.50
      'gbp': 30, // £0.30
      'cad': 50, // C$0.50
      'aud': 50, // A$0.50
    };

    final minimum = minimumAmounts[currency.toLowerCase()] ?? 50;
    return amountInCents >= minimum;
  }

  /// Check if currency is supported
  bool isCurrencySupported(String currency) {
    return _currencyConfig.containsKey(currency.toLowerCase());
  }

  /// Check if Stripe is initialized
  bool get isInitialized => _isInitialized;

  /// Get environment-specific test mode status
  bool get isTestMode => !AppConfig.instance.isProduction;
}
