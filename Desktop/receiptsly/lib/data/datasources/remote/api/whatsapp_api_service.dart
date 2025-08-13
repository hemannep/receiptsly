import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';

class WhatsAppApiService {
  final Dio _dio;
  final String _accessToken;

  WhatsAppApiService({required String accessToken, Dio? dio})
    : _accessToken = accessToken,
      _dio = dio ?? Dio();

  // Send text message
  Future<Map<String, dynamic>> sendTextMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        'https://graph.facebook.com/v17.0/YOUR_PHONE_NUMBER_ID/messages',
        data: {
          'messaging_product': 'whatsapp',
          'to': phoneNumber,
          'type': 'text',
          'text': {'body': message},
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      throw RemoteDataException('WhatsApp API error: ${e.message}');
    } catch (e) {
      throw RemoteDataException('WhatsApp message send failed: $e');
    }
  }

  // Send template message
  Future<Map<String, dynamic>> sendTemplateMessage({
    required String phoneNumber,
    required String templateName,
    required String languageCode,
    List<String>? parameters,
  }) async {
    try {
      final response = await _dio.post(
        'https://graph.facebook.com/v17.0/YOUR_PHONE_NUMBER_ID/messages',
        data: {
          'messaging_product': 'whatsapp',
          'to': phoneNumber,
          'type': 'template',
          'template': {
            'name': templateName,
            'language': {'code': languageCode},
            if (parameters != null && parameters.isNotEmpty)
              'components': [
                {
                  'type': 'body',
                  'parameters': parameters
                      .map((p) => {'type': 'text', 'text': p})
                      .toList(),
                },
              ],
          },
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      throw RemoteDataException('WhatsApp template error: ${e.message}');
    } catch (e) {
      throw RemoteDataException('WhatsApp template send failed: $e');
    }
  }
}
