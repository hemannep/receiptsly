import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/constants/api_endpoints.dart';

class OCRApiService {
  final Dio _dio;

  OCRApiService({Dio? dio}) : _dio = dio ?? Dio();

  // Process receipt with Google Cloud Vision API
  Future<Map<String, dynamic>> processReceiptWithVision(
    Uint8List imageBytes,
    String apiKey,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.googleVisionApi}?key=$apiKey',
        data: {
          'requests': [
            {
              'image': {'content': base64Encode(imageBytes)},
              'features': [
                {'type': 'TEXT_DETECTION'},
                {'type': 'DOCUMENT_TEXT_DETECTION'},
              ],
            },
          ],
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw RemoteDataException(
          'OCR API request failed: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw RemoteDataException('OCR API error: ${e.message}');
    } catch (e) {
      throw RemoteDataException('OCR processing failed: $e');
    }
  }

  // Process receipt with Azure Cognitive Services
  Future<Map<String, dynamic>> processReceiptWithAzure(
    Uint8List imageBytes,
    String endpoint,
    String apiKey,
  ) async {
    try {
      final response = await _dio.post(
        '$endpoint/vision/v3.2/read/analyze',
        data: imageBytes,
        options: Options(
          headers: {
            'Ocp-Apim-Subscription-Key': apiKey,
            'Content-Type': 'application/octet-stream',
          },
        ),
      );

      if (response.statusCode == 202) {
        final operationLocation = response.headers['operation-location']?.first;
        if (operationLocation != null) {
          return await _pollAzureResult(operationLocation, apiKey);
        }
      }

      throw RemoteDataException(
        'Azure OCR request failed: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw RemoteDataException('Azure OCR error: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Azure OCR processing failed: $e');
    }
  }

  // Poll Azure OCR result
  Future<Map<String, dynamic>> _pollAzureResult(
    String operationLocation,
    String apiKey,
  ) async {
    int attempts = 0;
    const maxAttempts = 10;
    const delay = Duration(seconds: 2);

    while (attempts < maxAttempts) {
      try {
        final response = await _dio.get(
          operationLocation,
          options: Options(headers: {'Ocp-Apim-Subscription-Key': apiKey}),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data['status'] == 'succeeded') {
            return data;
          } else if (data['status'] == 'failed') {
            throw RemoteDataException('Azure OCR processing failed');
          }
        }

        attempts++;
        await Future.delayed(delay);
      } on DioException catch (e) {
        throw RemoteDataException('Azure OCR polling error: ${e.message}');
      }
    }

    throw RemoteDataException('Azure OCR processing timeout');
  }

  // Process receipt with AWS Textract
  Future<Map<String, dynamic>> processReceiptWithTextract(
    Uint8List imageBytes,
    String accessKey,
    String secretKey,
    String region,
  ) async {
    try {
      // Note: This is a simplified example. In production, you'd use AWS SDK
      // or implement proper AWS signature v4 authentication

      final response = await _dio.post(
        'https://textract.$region.amazonaws.com/',
        data: {
          'Document': {'Bytes': base64Encode(imageBytes)},
          'FeatureTypes': ['TABLES', 'FORMS'],
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-amz-json-1.1',
            'X-Amz-Target': 'Textract.AnalyzeDocument',
            'Authorization': 'AWS4-HMAC-SHA256 ...', // Implement AWS auth
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw RemoteDataException(
          'Textract API request failed: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw RemoteDataException('Textract API error: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Textract processing failed: $e');
    }
  }

  // Helper method to encode image to base64
  String base64Encode(Uint8List bytes) {
    return base64.encode(bytes);
  }
}
