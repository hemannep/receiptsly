import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:image/image.dart' as img;
import '../../entities/receipt_entity.dart';
import '../../repositories/i_receipt_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/file_utils.dart';
import '../../../services/local/local_storage_service.dart';

class CaptureReceiptUseCase {
  final IReceiptRepository _receiptRepository;
  final LocalStorageService _localStorageService;

  CaptureReceiptUseCase(this._receiptRepository, this._localStorageService);

  Future<Either<Failure, ReceiptEntity>> call(
    CaptureReceiptParams params,
  ) async {
    try {
      // Validate image file
      final validationResult = await _validateImageFile(params.imageFile);
      if (validationResult != null) {
        return Left(ValidationFailure(validationResult));
      }

      // Process and optimize image
      final processedImage = await _processImage(params.imageFile);

      // Create receipt entity with initial data
      final receiptEntity = ReceiptEntity(
        id: _generateReceiptId(),
        userId: params.userId,
        source: params.source,
        imageLocalPath: processedImage.path,
        imageUrl: null, // Will be set after upload
        status: ReceiptStatus.captured,
        capturedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: ReceiptMetadataEntity(
          imageSize: await processedImage.length(),
          imageFormat: _getImageFormat(processedImage.path),
          deviceInfo: await _getDeviceInfo(),
          location: params.location,
        ),
      );

      // Save to local database immediately
      final localSaveResult = await _receiptRepository.saveToLocal(
        receiptEntity,
      );

      return localSaveResult.fold((failure) => Left(failure), (
        savedReceipt,
      ) async {
        // Queue for upload and OCR processing (offline-first)
        await _receiptRepository.queueForUpload(savedReceipt.id);
        await _receiptRepository.queueForOCR(savedReceipt.id);

        // Attempt immediate processing if online
        _processInBackground(savedReceipt);

        return Right(savedReceipt);
      });
    } catch (e) {
      return Left(CaptureFailure('Failed to capture receipt: ${e.toString()}'));
    }
  }

  Future<String?> _validateImageFile(File imageFile) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        return 'Image file does not exist';
      }

      // Check file size (max 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        return 'Image file too large. Maximum size is 10MB';
      }

      // Check if it's a valid image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return 'Invalid image format';
      }

      // Check minimum dimensions
      if (image.width < 100 || image.height < 100) {
        return 'Image too small. Minimum size is 100x100 pixels';
      }

      return null;
    } catch (e) {
      return 'Failed to validate image: ${e.toString()}';
    }
  }

  Future<File> _processImage(File originalFile) async {
    try {
      final bytes = await originalFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) throw Exception('Failed to decode image');

      // Resize if too large (max 2048x2048)
      if (image.width > 2048 || image.height > 2048) {
        final ratio = (image.width > image.height)
            ? 2048 / image.width
            : 2048 / image.height;

        image = img.copyResize(
          image,
          width: (image.width * ratio).round(),
          height: (image.height * ratio).round(),
        );
      }

      // Enhance for OCR
      image = _enhanceForOCR(image);

      // Save processed image
      final processedFile = await _localStorageService.saveProcessedImage(
        img.encodeJpg(image, quality: 85),
        _generateImageFileName(),
      );

      return processedFile;
    } catch (e) {
      // If processing fails, return original file
      return originalFile;
    }
  }

  img.Image _enhanceForOCR(img.Image image) {
    // Convert to grayscale for better OCR
    image = img.grayscale(image);

    // Increase contrast
    image = img.adjustColor(image, contrast: 1.3);

    // Slight sharpening
    image = img.convolution(image, [0, -1, 0, -1, 5, -1, 0, -1, 0]);

    return image;
  }

  void _processInBackground(ReceiptEntity receipt) async {
    try {
      // Check if online
      final isOnline = await _receiptRepository.isOnline();
      if (!isOnline) return;

      // Upload image
      await _receiptRepository.uploadImage(receipt.id);

      // Process OCR
      await _receiptRepository.processOCR(receipt.id);
    } catch (e) {
      // Silent failure - will be retried later
      print('Background processing failed: $e');
    }
  }

  String _generateReceiptId() {
    return 'receipt_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  String _generateImageFileName() {
    return 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (index) => chars[DateTime.now().millisecond % chars.length],
    ).join();
  }

  String _getImageFormat(String path) {
    return path.split('.').last.toLowerCase();
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // Implementation would use device_info_plus package
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
    };
  }
}

class CaptureReceiptParams {
  final File imageFile;
  final String userId;
  final ReceiptSource source;
  final LocationData? location;

  CaptureReceiptParams({
    required this.imageFile,
    required this.userId,
    required this.source,
    this.location,
  });
}

enum ReceiptSource { camera, gallery, whatsapp, telegram, email }

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;

  LocationData({required this.latitude, required this.longitude, this.address});
}
