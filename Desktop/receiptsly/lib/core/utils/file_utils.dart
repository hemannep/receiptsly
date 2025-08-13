// lib/core/utils/file_utils.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';

/// Comprehensive file utilities for Receiptsly app
/// Handles file operations, image processing, validation, and management
class FileUtils {
  // File size constants
  static const int _1KB = 1024;
  static const int _1MB = 1024 * 1024;
  static const int _1GB = 1024 * 1024 * 1024;

  // Maximum file sizes for different types
  static const int maxImageSize = 10 * _1MB; // 10MB
  static const int maxDocumentSize = 5 * _1MB; // 5MB
  static const int maxVideoSize = 50 * _1MB; // 50MB

  // Supported file extensions
  static const List<String> imageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
    '.tiff',
    '.ico',
  ];

  static const List<String> documentExtensions = [
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
    '.rtf',
    '.odt',
  ];

  static const List<String> spreadsheetExtensions = [
    '.xls',
    '.xlsx',
    '.csv',
    '.ods',
  ];

  static const List<String> videoExtensions = [
    '.mp4',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.mkv',
  ];

  // File validation methods
  static bool isValidImageFile(File file) {
    if (!file.existsSync()) return false;

    final extension = path.extension(file.path).toLowerCase();
    return imageExtensions.contains(extension);
  }

  static bool isValidDocumentFile(File file) {
    if (!file.existsSync()) return false;

    final extension = path.extension(file.path).toLowerCase();
    return documentExtensions.contains(extension) ||
        spreadsheetExtensions.contains(extension);
  }

  static bool isValidFileSize(File file, int maxSize) {
    if (!file.existsSync()) return false;

    final fileSize = file.lengthSync();
    return fileSize <= maxSize;
  }

  static String? validateImageFile(File file) {
    if (!file.existsSync()) {
      return 'File does not exist';
    }

    if (!isValidImageFile(file)) {
      return 'Invalid image format. Supported formats: ${imageExtensions.join(', ')}';
    }

    if (!isValidFileSize(file, maxImageSize)) {
      return 'Image file size cannot exceed ${formatFileSize(maxImageSize)}';
    }

    return null;
  }

  static String? validateDocumentFile(File file) {
    if (!file.existsSync()) {
      return 'File does not exist';
    }

    if (!isValidDocumentFile(file)) {
      return 'Invalid document format. Supported formats: ${documentExtensions.join(', ')}';
    }

    if (!isValidFileSize(file, maxDocumentSize)) {
      return 'Document file size cannot exceed ${formatFileSize(maxDocumentSize)}';
    }

    return null;
  }

  // File size formatting
  static String formatFileSize(int bytes) {
    if (bytes < 0) return '0 B';

    if (bytes < _1KB) {
      return '$bytes B';
    } else if (bytes < _1MB) {
      return '${(bytes / _1KB).toStringAsFixed(1)} KB';
    } else if (bytes < _1GB) {
      return '${(bytes / _1MB).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / _1GB).toStringAsFixed(1)} GB';
    }
  }

  static int parseFileSize(String sizeString) {
    final regex = RegExp(r'([\d.]+)\s*([KMGT]?B)', caseSensitive: false);
    final match = regex.firstMatch(sizeString.trim());

    if (match == null) return 0;

    final value = double.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = match.group(2)?.toUpperCase() ?? 'B';

    switch (unit) {
      case 'KB':
        return (value * _1KB).round();
      case 'MB':
        return (value * _1MB).round();
      case 'GB':
        return (value * _1GB).round();
      case 'TB':
        return (value * _1GB * 1024).round();
      default:
        return value.round();
    }
  }

  // File path utilities
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  static String getFileDirectory(String filePath) {
    return path.dirname(filePath);
  }

  static String generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = getFileExtension(originalName);
    final nameWithoutExt = getFileNameWithoutExtension(originalName);

    return '${nameWithoutExt}_$timestamp$extension';
  }

  static String sanitizeFileName(String fileName) {
    // Remove or replace invalid characters
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  // Directory utilities
  static Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  static Future<Directory> getAppCacheDirectory() async {
    return await getTemporaryDirectory();
  }

  static Future<Directory> getReceiptsDirectory() async {
    final appDir = await getAppDocumentsDirectory();
    final receiptsDir = Directory(path.join(appDir.path, 'receipts'));

    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    return receiptsDir;
  }

  static Future<Directory> getInvoicesDirectory() async {
    final appDir = await getAppDocumentsDirectory();
    final invoicesDir = Directory(path.join(appDir.path, 'invoices'));

    if (!await invoicesDir.exists()) {
      await invoicesDir.create(recursive: true);
    }

    return invoicesDir;
  }

  static Future<Directory> getBackupDirectory() async {
    final appDir = await getAppDocumentsDirectory();
    final backupDir = Directory(path.join(appDir.path, 'backups'));

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  static Future<Directory> getTempDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final appTempDir = Directory(path.join(tempDir.path, 'receiptsly_temp'));

    if (!await appTempDir.exists()) {
      await appTempDir.create(recursive: true);
    }

    return appTempDir;
  }

  // File operations
  static Future<File> copyFile(File sourceFile, String destinationPath) async {
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', sourceFile.path);
    }

    final destFile = File(destinationPath);
    final destDir = Directory(path.dirname(destinationPath));

    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    return await sourceFile.copy(destinationPath);
  }

  static Future<File> moveFile(File sourceFile, String destinationPath) async {
    final copiedFile = await copyFile(sourceFile, destinationPath);
    await sourceFile.delete();
    return copiedFile;
  }

  static Future<void> deleteFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> deleteDirectory(
    Directory directory, {
    bool recursive = false,
  }) async {
    if (await directory.exists()) {
      await directory.delete(recursive: recursive);
    }
  }

  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  static Future<DateTime> getFileModifiedDate(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final stat = await file.stat();
      return stat.modified;
    }
    throw FileSystemException('File does not exist', filePath);
  }

  // Image processing utilities
  static Future<File> compressImage(
    File imageFile, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
  }) async {
    if (!await imageFile.exists()) {
      throw FileSystemException('Image file does not exist', imageFile.path);
    }

    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Unable to decode image');
    }

    // Resize if dimensions are specified
    if (maxWidth != null || maxHeight != null) {
      image = _resizeImage(image, maxWidth, maxHeight);
    }

    // Compress image
    final compressedBytes = img.encodeJpg(image, quality: quality);

    // Save compressed image to temp directory
    final tempDir = await getTempDirectory();
    final fileName = generateUniqueFileName(getFileName(imageFile.path));
    final compressedFile = File(path.join(tempDir.path, fileName));

    await compressedFile.writeAsBytes(compressedBytes);
    return compressedFile;
  }

  static img.Image _resizeImage(
    img.Image image,
    int? maxWidth,
    int? maxHeight,
  ) {
    if (maxWidth == null && maxHeight == null) return image;

    final originalWidth = image.width;
    final originalHeight = image.height;

    int newWidth = originalWidth;
    int newHeight = originalHeight;

    if (maxWidth != null && originalWidth > maxWidth) {
      newWidth = maxWidth;
      newHeight = (originalHeight * maxWidth / originalWidth).round();
    }

    if (maxHeight != null && newHeight > maxHeight) {
      newHeight = maxHeight;
      newWidth = (originalWidth * maxHeight / originalHeight).round();
    }

    return img.copyResize(image, width: newWidth, height: newHeight);
  }

  static Future<Map<String, dynamic>> getImageMetadata(File imageFile) async {
    if (!await imageFile.exists()) {
      throw FileSystemException('Image file does not exist', imageFile.path);
    }

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Unable to decode image');
    }

    final fileSize = await imageFile.length();
    final modifiedDate = await getFileModifiedDate(imageFile.path);

    return {
      'width': image.width,
      'height': image.height,
      'fileSize': fileSize,
      'fileSizeFormatted': formatFileSize(fileSize),
      'format': getFileExtension(imageFile.path),
      'fileName': getFileName(imageFile.path),
      'modifiedDate': modifiedDate,
      'aspectRatio': image.width / image.height,
    };
  }

  static Future<Uint8List> imageToBytes(
    File imageFile, {
    String format = 'jpg',
    int quality = 85,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Unable to decode image');
    }

    switch (format.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
      case 'png':
        return Uint8List.fromList(img.encodePng(image));
      case 'webp':
        // WebP encoding is not supported by the image package; fallback to PNG
        return Uint8List.fromList(img.encodePng(image));
      default:
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }
  }

  // File hashing and checksum
  static Future<String> generateFileHash(
    File file, {
    String algorithm = 'md5',
  }) async {
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', file.path);
    }

    final bytes = await file.readAsBytes();

    switch (algorithm.toLowerCase()) {
      case 'md5':
        return md5.convert(bytes).toString();
      case 'sha1':
        return sha1.convert(bytes).toString();
      case 'sha256':
        return sha256.convert(bytes).toString();
      default:
        return md5.convert(bytes).toString();
    }
  }

  static Future<bool> compareFiles(File file1, File file2) async {
    if (!await file1.exists() || !await file2.exists()) {
      return false;
    }

    // Quick size comparison
    final size1 = await file1.length();
    final size2 = await file2.length();

    if (size1 != size2) return false;

    // Compare file hashes
    final hash1 = await generateFileHash(file1);
    final hash2 = await generateFileHash(file2);

    return hash1 == hash2;
  }

  // Backup and restore utilities
  static Future<File> createBackup(String filePath, {String? backupDir}) async {
    final sourceFile = File(filePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', filePath);
    }

    final backupDirectory = backupDir != null
        ? Directory(backupDir)
        : await getBackupDirectory();

    if (!await backupDirectory.exists()) {
      await backupDirectory.create(recursive: true);
    }

    final fileName = getFileName(filePath);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFileName =
        '${getFileNameWithoutExtension(fileName)}_backup_$timestamp${getFileExtension(fileName)}';
    final backupPath = path.join(backupDirectory.path, backupFileName);

    return await copyFile(sourceFile, backupPath);
  }

  static Future<List<File>> listBackups(String originalFileName) async {
    final backupDir = await getBackupDirectory();
    if (!await backupDir.exists()) return [];

    final nameWithoutExt = getFileNameWithoutExtension(originalFileName);
    final extension = getFileExtension(originalFileName);

    final files = await backupDir.list().toList();
    final backups = <File>[];

    for (final entity in files) {
      if (entity is File) {
        final fileName = getFileName(entity.path);
        if (fileName.startsWith('${nameWithoutExt}_backup_') &&
            fileName.endsWith(extension)) {
          backups.add(entity);
        }
      }
    }

    // Sort by modification date (newest first)
    backups.sort(
      (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );
    return backups;
  }

  static Future<void> restoreFromBackup(
    File backupFile,
    String originalPath,
  ) async {
    if (!await backupFile.exists()) {
      throw FileSystemException('Backup file does not exist', backupFile.path);
    }

    await copyFile(backupFile, originalPath);
  }

  static Future<void> cleanupOldBackups({int keepCount = 5}) async {
    final backupDir = await getBackupDirectory();
    if (!await backupDir.exists()) return;

    final files = await backupDir.list().toList();
    final backupFiles = files.whereType<File>().toList();

    // Group backups by original file name
    final backupGroups = <String, List<File>>{};

    for (final file in backupFiles) {
      final fileName = getFileName(file.path);
      final match = RegExp(
        r'(.+)_backup_\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}',
      ).firstMatch(fileName);

      if (match != null) {
        final originalName = match.group(1)!;
        backupGroups[originalName] ??= [];
        backupGroups[originalName]!.add(file);
      }
    }

    // Keep only the latest backups for each file
    for (final group in backupGroups.values) {
      group.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      if (group.length > keepCount) {
        final filesToDelete = group.skip(keepCount);
        for (final file in filesToDelete) {
          await file.delete();
        }
      }
    }
  }

  // File compression and archiving
  static Future<void> cleanupTempFiles({Duration? olderThan}) async {
    final tempDir = await getTempDirectory();
    if (!await tempDir.exists()) return;

    final cutoffTime = olderThan != null
        ? DateTime.now().subtract(olderThan)
        : DateTime.now().subtract(const Duration(hours: 24));

    final files = await tempDir.list(recursive: true).toList();

    for (final entity in files) {
      if (entity is File) {
        final modifiedTime = await getFileModifiedDate(entity.path);
        if (modifiedTime.isBefore(cutoffTime)) {
          await entity.delete();
        }
      }
    }
  }

  // File sharing and export utilities
  static Future<String> prepareFileForSharing(
    File file, {
    String? customName,
  }) async {
    final shareDir = Directory(
      path.join((await getTempDirectory()).path, 'share'),
    );
    if (!await shareDir.exists()) {
      await shareDir.create(recursive: true);
    }

    final fileName = customName ?? getFileName(file.path);
    final sanitizedName = sanitizeFileName(fileName);
    final sharePath = path.join(shareDir.path, sanitizedName);

    await copyFile(file, sharePath);
    return sharePath;
  }

  static Future<Map<String, dynamic>> analyzeDirectory(
    Directory directory,
  ) async {
    if (!await directory.exists()) {
      return {
        'totalFiles': 0,
        'totalSize': 0,
        'fileTypes': <String, int>{},
        'largestFile': null,
        'oldestFile': null,
        'newestFile': null,
      };
    }

    final files = await directory
        .list(recursive: true)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();

    int totalSize = 0;
    final fileTypes = <String, int>{};
    File? largestFile;
    File? oldestFile;
    File? newestFile;
    int largestSize = 0;
    DateTime? oldestDate;
    DateTime? newestDate;

    for (final file in files) {
      try {
        final size = await file.length();
        final modifiedDate = await getFileModifiedDate(file.path);
        final extension = getFileExtension(file.path);

        totalSize += size;
        fileTypes[extension] = (fileTypes[extension] ?? 0) + 1;

        if (size > largestSize) {
          largestSize = size;
          largestFile = file;
        }

        if (oldestDate == null || modifiedDate.isBefore(oldestDate)) {
          oldestDate = modifiedDate;
          oldestFile = file;
        }

        if (newestDate == null || modifiedDate.isAfter(newestDate)) {
          newestDate = modifiedDate;
          newestFile = file;
        }
      } catch (e) {
        // Skip files that can't be accessed
        continue;
      }
    }

    return {
      'totalFiles': files.length,
      'totalSize': totalSize,
      'totalSizeFormatted': formatFileSize(totalSize),
      'fileTypes': fileTypes,
      'largestFile': largestFile?.path,
      'largestFileSize': largestSize,
      'largestFileSizeFormatted': formatFileSize(largestSize),
      'oldestFile': oldestFile?.path,
      'oldestFileDate': oldestDate,
      'newestFile': newestFile?.path,
      'newestFileDate': newestDate,
    };
  }

  // Security and encryption utilities
  static Future<File> secureDelete(File file) async {
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', file.path);
    }

    // Overwrite file with random data before deletion
    final fileSize = await file.length();
    final randomBytes = List.generate(
      fileSize,
      (index) => DateTime.now().millisecondsSinceEpoch % 256,
    );

    await file.writeAsBytes(randomBytes);
    await file.delete();

    return file;
  }

  static Future<bool> isFileEncrypted(File file) async {
    if (!await file.exists()) return false;

    try {
      // Read first few bytes to check for encryption signatures
      final bytes = await file.openRead(0, 16).first;

      // Check for common encryption file signatures
      final signatures = [
        [0x50, 0x4B, 0x03, 0x04], // ZIP/encrypted ZIP
        [0x37, 0x7A, 0xBC, 0xAF], // 7z
        [0x52, 0x61, 0x72, 0x21], // RAR
      ];

      for (final signature in signatures) {
        if (bytes.length >= signature.length) {
          bool matches = true;
          for (int i = 0; i < signature.length; i++) {
            if (bytes[i] != signature[i]) {
              matches = false;
              break;
            }
          }
          if (matches) return true;
        }
      }

      // Check for high entropy (possible encryption)
      return _hasHighEntropy(bytes);
    } catch (e) {
      return false;
    }
  }

  static bool _hasHighEntropy(List<int> bytes) {
    if (bytes.length < 16) return false;

    final frequency = List.filled(256, 0);
    for (final byte in bytes) {
      frequency[byte]++;
    }

    double entropy = 0.0;
    for (final count in frequency) {
      if (count > 0) {
        final probability = count / bytes.length;
        entropy -= probability * (log(probability) / log(2));
      }
    }

    // High entropy threshold (encrypted data usually has entropy > 7.5)
    return entropy > 7.0;
  }

  // File monitoring and watching
  static Future<Stream<FileSystemEvent>> watchFile(String filePath) async {
    final file = File(filePath);
    final directory = Directory(path.dirname(filePath));

    if (!await directory.exists()) {
      throw FileSystemException('Directory does not exist', directory.path);
    }

    return directory
        .watch(events: FileSystemEvent.all)
        .where((event) => event.path == filePath);
  }

  static Future<Stream<FileSystemEvent>> watchDirectory(
    String directoryPath,
  ) async {
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      throw FileSystemException('Directory does not exist', directoryPath);
    }

    return directory.watch(recursive: true);
  }

  // File type detection
  static String detectFileType(File file) {
    final extension = getFileExtension(file.path);

    if (imageExtensions.contains(extension)) {
      return 'image';
    } else if (documentExtensions.contains(extension)) {
      return 'document';
    } else if (spreadsheetExtensions.contains(extension)) {
      return 'spreadsheet';
    } else if (videoExtensions.contains(extension)) {
      return 'video';
    } else {
      return 'unknown';
    }
  }

  static Future<String> detectMimeType(File file) async {
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', file.path);
    }

    final extension = getFileExtension(file.path);

    const mimeTypes = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.pdf': 'application/pdf',
      '.txt': 'text/plain',
      '.csv': 'text/csv',
      '.json': 'application/json',
      '.xml': 'application/xml',
      '.zip': 'application/zip',
      '.mp4': 'video/mp4',
      '.avi': 'video/avi',
      '.mov': 'video/quicktime',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  // Performance utilities
  static Future<Map<String, dynamic>> getFilePerformanceMetrics(
    String filePath,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', filePath);
    }

    final stopwatch = Stopwatch()..start();

    // Test read speed
    final readStart = stopwatch.elapsedMicroseconds;
    final bytes = await file.readAsBytes();
    final readTime = stopwatch.elapsedMicroseconds - readStart;

    // Test write speed (to temp file)
    final tempDir = await getTempDirectory();
    final tempFile = File(
      path.join(
        tempDir.path,
        'perf_test_${DateTime.now().millisecondsSinceEpoch}.tmp',
      ),
    );

    final writeStart = stopwatch.elapsedMicroseconds;
    await tempFile.writeAsBytes(bytes);
    final writeTime = stopwatch.elapsedMicroseconds - writeStart;

    // Cleanup
    await tempFile.delete();
    stopwatch.stop();

    final fileSize = bytes.length;
    final readSpeedMBps = (fileSize / (readTime / 1000000)) / _1MB;
    final writeSpeedMBps = (fileSize / (writeTime / 1000000)) / _1MB;

    return {
      'fileSize': fileSize,
      'fileSizeFormatted': formatFileSize(fileSize),
      'readTime': readTime,
      'writeTime': writeTime,
      'readSpeedMBps': readSpeedMBps.toStringAsFixed(2),
      'writeSpeedMBps': writeSpeedMBps.toStringAsFixed(2),
      'totalTime': stopwatch.elapsedMicroseconds,
    };
  }

  // Utility helper functions
  static double log(double x) => math.log(x) / math.ln2;
}
