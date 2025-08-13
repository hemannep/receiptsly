import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';

class StripeApiService {
  final Dio _dio;
  final String _secretKey;

  StripeApiService({required String secretKey, Dio? dio})
    : _secretKey = secretKey,
      _dio = dio ?? Dio();

  // Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String currency,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _dio.post(
        'https://api.stripe.com/v1/payment_intents',
        data: {
          'amount': amount,
          'currency': currency,
          if (customerId != null) 'customer': customerId,
          if (metadata != null) 'metadata': metadata,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_secretKey',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      throw RemoteDataException('Stripe payment intent error: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Payment intent creation failed: $e');
    }
  }

  // Create customer
  Future<Map<String, dynamic>> createCustomer({
    required String email,
    String? name,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _dio.post(
        'https://api.stripe.com/v1/customers',
        data: {
          'email': email,
          if (name != null) 'name': name,
          if (metadata != null) 'metadata': metadata,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_secretKey',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      throw RemoteDataException('Stripe customer creation error: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Customer creation failed: $e');
    }
  }

  // Create subscription
  Future<Map<String, dynamic>> createSubscription({
    required String customerId,
    required String priceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _dio.post(
        'https://api.stripe.com/v1/subscriptions',
        data: {
          'customer': customerId,
          'items[0][price]': priceId,
          if (metadata != null) 'metadata': metadata,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_secretKey',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      throw RemoteDataException('Stripe subscription error: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Subscription creation failed: $e');
    }
  }
}
