// lib/services/firebase/storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Service for handling Firebase Storage operations
/// Manages file uploads, downloads, and storage organization
class StorageService {
  static StorageService? _instance;
  late FirebaseStorage _storage;

  // Storage paths
  static const String receiptsPath = 'receipts';
  static const String invoicesPath = 'invoices';
  static const String avatarsPath = 'avatars';
  static const String thumbnailsPath = 'thumbnails';
  static const String tempPath = 'temp';
  static const String backupsPath = 'backups';

  // File size limits (in bytes)
  static const int maxReceiptSize = 10 * 1024 * 1024; // 10MB
  static const int maxAvatarSize = 2 * 1024 * 1024; // 2MB
  static const int maxInvoiceSize = 5 * 1024 * 1024; // 5MB

  // Thumbnail settings
  static const int thumbnailWidth = 300;
  static const int thumbnailHeight = 300;
  static const int thumbnailQuality = 80;

  // Singleton pattern
  StorageService._();

  static StorageService getInstance() {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// Initialize the storage service
  Future<void> initialize() async {
    try {
      _storage = FirebaseStorage.instance;
      
      // Configure storage settings
      await _configureStorage();
      
      debugPrint('StorageService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing StorageService: $e');
      rethrow;
    }
  }

  /// Configure storage settings
  Future<void> _configureStorage() async {
    try {
      // Set maximum operation timeout
      _storage.setMaxOperationRetryTime(const Duration(seconds: 30));
      _storage.setMaxUploadRetryTime(const Duration(seconds: 120));
      _storage.setMaxDownloadRetryTime(const Duration(seconds: 60));
      
      debugPrint('Storage configured with timeout settings');
    } catch (e) {
      debugPrint('Error configuring storage: $e');
    }
  }

  // Receipt Storage Operations

  /// Upload receipt image
  Future<UploadResult> uploadReceiptImage(
    String userId,
    File imageFile, {
    String? receiptId,
    Function(double)? onProgress,
  }) async {
    try {
      // Validate file
      final validation = await _validateImageFile(imageFile, maxReceiptSize);
      if (!validation.isValid) {
        return UploadResult.failure(validation.error!);
      }

      receiptId ??= _generateFileId();
      final fileName = '${receiptId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$receiptsPath/$userId/$fileName';

      // Optimize image before upload
      final optimizedFile = await _optimizeImage(imageFile);

      // Create thumbnail
      final thumbnailFile = await _createThumbnail(optimizedFile);
      final thumbnailPath = '$receiptsPath/$userId/thumbnails/${receiptId}_thumb.jpg';

      // Upload both original and thumbnail
      final uploadTasks = await Future.wait([
        _uploadFile(optimizedFile, filePath, onProgress: onProgress),
        _uploadFile(thumbnailFile, thumbnailPath),
      ]);

      if (uploadTasks.every((result) => result.isSuccess)) {
        // Clean up temporary files
        await _cleanupTempFiles([optimizedFile, thumbnailFile]);

        return UploadResult.success(
          originalUrl: uploadTasks[0].downloadUrl!,
          thumbnailUrl: uploadTasks[1].downloadUrl!,
          fileName: fileName,
          filePath: filePath,
          thumbnailPath: thumbnailPath,
          fileSize: await optimizedFile.length(),
        );
      } else {
        return UploadResult.failure('Failed to upload receipt image');
      }
    } catch (e) {
      debugPrint('Error uploading receipt image: $e');
      return UploadResult.failure('Upload failed: ${e.toString()}');
    }
  }

  /// Delete receipt image
  Future<bool> deleteReceiptImage(String filePath, {String? thumbnailPath}) async {
    try {
      final deleteTasks = <Future<bool>>[];
      
      // Delete original file
      deleteTasks.add(_deleteFile(filePath));
      
      // Delete thumbnail if exists
      if (thumbnailPath != null) {
        deleteTasks.add(_deleteFile(thumbnailPath));
      }

      final results = await Future.wait(deleteTasks);
      final success = results.every((result) => result);
      
      if (success) {
        debugPrint('Receipt image deleted: $filePath');
      }
      
      return success;
    } catch (e) {
      debugPrint('Error deleting receipt image: $e');
      return false;
    }
  }

  // Avatar Storage Operations

  /// Upload user avatar
  Future<UploadResult> uploadAvatar(
    String userId,
    File imageFile, {
    Function(double)? onProgress,
  }) async {
    try {
      // Validate file
      final validation = await _validateImageFile(imageFile, maxAvatarSize);
      if (!validation.isValid) {
        return UploadResult.failure(validation.error!);
      }

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$avatarsPath/$userId/$fileName';

      // Resize avatar to standard size
      final resizedFile = await _resizeImage(
        imageFile,
        width: 200,
        height: 200,
        quality: 90,
      );

      // Upload avatar
      final uploadResult = await _uploadFile(resizedFile, filePath, onProgress: onProgress);

      // Clean up temp file
      await _cleanupTempFiles([resizedFile]);

      if (uploadResult.isSuccess) {
        return UploadResult.success(
          originalUrl: uploadResult.downloadUrl!,
          fileName: fileName,
          filePath: filePath,
          fileSize: await resizedFile.length(),
        );
      } else {
        return UploadResult.failure('Failed to upload avatar');
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return UploadResult.failure('Upload failed: ${e.toString()}');
    }
  }

  /// Delete user avatar
  Future<bool> deleteAvatar(String filePath) async {
    return await _deleteFile(filePath);
  }

  // Invoice Storage Operations

  /// Upload invoice PDF
  Future<UploadResult> uploadInvoicePDF(
    String userId,
    File pdfFile, {
    String? invoiceId,
    Function(double)? onProgress,
  }) async {
    try {
      // Validate PDF file
      final validation = await _validatePDFFile(pdfFile, maxInvoiceSize);
      if (!validation.isValid) {
        return UploadResult.failure(validation.error!);
      }

      invoiceId ??= _generateFileId();
      final fileName = '${invoiceId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '$invoicesPath/$userId/$fileName';

      // Upload PDF
      final uploadResult = await _uploadFile(pdfFile, filePath, onProgress: onProgress);

      if (uploadResult.isSuccess) {
        return UploadResult.success(
          originalUrl: uploadResult.downloadUrl!,
          fileName: fileName,
          filePath: filePath,
          fileSize: await pdfFile.length(),
        );
      } else {
        return UploadResult.failure('Failed to upload invoice PDF');
      }
    } catch (e) {
      debugPrint('Error uploading invoice PDF: $e');
      return UploadResult.failure('Upload failed: ${e.toString()}');
    }
  }

  /// Delete invoice PDF
  Future<bool> deleteInvoicePDF(String filePath) async {
    return await _deleteFile(filePath);
  }

  // Backup Operations

  /// Upload backup file
  Future<UploadResult> uploadBackup(
    String userId,
    File backupFile, {
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = '$backupsPath/$userId/$fileName';

      final uploadResult = await _uploadFile(backupFile, filePath, onProgress: onProgress);

      if (uploadResult.isSuccess) {
        return UploadResult.success(
          originalUrl: uploadResult.downloadUrl!,
          fileName: fileName,
          filePath: filePath,
          fileSize: await backupFile.length(),
        );
      } else {
        return UploadResult.failure('Failed to upload backup');
      }
    } catch (e) {
      debugPrint('Error uploading backup: $e');
      return UploadResult.failure('Upload failed: ${e.toString()}');
    }
  }

  /// List user backups
  Future<List<StorageItem>> listUserBackups(String userId) async {
    try {
      return await _listFiles('$backupsPath/$userId/');
    } catch (e) {
      debugPrint('Error listing user backups: $e');
      return [];
    }
  }

  // Generic File Operations

  /// Upload file
  Future<UploadResult> _uploadFile(
    File file,
    String filePath, {
    Function(double)? onProgress,
    Map<String, String>? metadata,
  }) async {
    try {
      final ref = _storage.ref().child(filePath);
      
      // Set metadata
      final settableMetadata = SettableMetadata(
        contentType: _getContentType(file.path),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalFileName': path.basename(file.path),
          ...?metadata,
        },
      );

      // Start upload
      final uploadTask = ref.putFile(file, settableMetadata);

      // Listen to progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for completion
      final snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        return UploadResult.success(
          originalUrl: downloadUrl,
          fileName: path.basename(filePath),
          filePath: filePath,
          fileSize: snapshot.totalBytes,
        );
      } else {
        return UploadResult.failure('Upload failed with state: ${snapshot.state}');
      }
    } on FirebaseException catch (e) {
      return UploadResult.failure('Firebase error: ${e.message}');
    } catch (e) {
      return UploadResult.failure('Upload error: ${e.toString()}');
    }
  }

  /// Download file
  Future<DownloadResult> downloadFile(String filePath, {String? localPath}) async {
    try {
      final ref = _storage.ref().child(filePath);
      
      if (localPath != null) {
        // Download to specific path
        final file = File(localPath);
        await ref.writeToFile(file);
        return DownloadResult.success(file);
      } else {
        // Download to memory
        final data = await ref.getData();
        if (data != null) {
          return DownloadResult.success(null, data: data);
        } else {
          return DownloadResult.failure('No data received');
        }
      }
    } on FirebaseException catch (e) {
      return DownloadResult.failure('Firebase error: ${e.message}');
    } catch (e) {
      return DownloadResult.failure('Download error: ${e.toString()}');
    }
  }

  /// Delete file
  Future<bool> _deleteFile(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      await ref.delete();
      debugPrint('File deleted: $filePath');
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error deleting file: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// List files in directory
  Future<List<StorageItem>> _listFiles(String directoryPath) async {
    try {
      final ref = _storage.ref().child(directoryPath);
      final result = await ref.