import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../../core/errors/exceptions.dart';

class ImageCacheManager {
  static ImageCacheManager? _instance;
  Directory? _cacheDir;

  ImageCacheManager._internal();

  factory ImageCacheManager() {
    _instance ??= ImageCacheManager._internal();
    return _instance!;
  }

  Future<void> init() async {
    final tempDir = await getTemporaryDirectory();
    _cacheDir = Directory('${tempDir.path}/image_cache');

    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  // Cache image
  Future<String> cacheImage(String url, Uint8List bytes) async {
    if (_cacheDir == null) await init();

    final fileName = _generateFileName(url);
    final file = File('${_cacheDir!.path}/$fileName');

    await file.writeAsBytes(bytes);
    return file.path;
  }

  // Get cached image
  Future<File?> getCachedImage(String url) async {
    if (_cacheDir == null) await init();

    final fileName = _generateFileName(url);
    final file = File('${_cacheDir!.path}/$fileName');

    if (await file.exists()) {
      return file;
    }

    return null;
  }

  // Check if image is cached
  Future<bool> isImageCached(String url) async {
    if (_cacheDir == null) await init();

    final fileName = _generateFileName(url);
    final file = File('${_cacheDir!.path}/$fileName');

    return await file.exists();
  }

  // Clear all cached images
  Future<void> clearCache() async {
    if (_cacheDir == null) await init();

    if (await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create(recursive: true);
    }
  }

  // Clear old cached images
  Future<void> clearOldCache({
    Duration maxAge = const Duration(days: 7),
  }) async {
    if (_cacheDir == null) await init();

    final cutoffTime = DateTime.now().subtract(maxAge);

    await for (final entity in _cacheDir!.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoffTime)) {
          await entity.delete();
        }
      }
    }
  }

  // Get cache size
  Future<int> getCacheSize() async {
    if (_cacheDir == null) await init();

    int totalSize = 0;

    await for (final entity in _cacheDir!.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        totalSize += stat.size;
      }
    }

    return totalSize;
  }

  // Remove specific cached image
  Future<void> removeCachedImage(String url) async {
    if (_cacheDir == null) await init();

    final fileName = _generateFileName(url);
    final file = File('${_cacheDir!.path}/$fileName');

    if (await file.exists()) {
      await file.delete();
    }
  }

  // Generate file name from URL
  String _generateFileName(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Get cached image path
  Future<String?> getCachedImagePath(String url) async {
    final cachedFile = await getCachedImage(url);
    return cachedFile?.path;
  }

  // Cache image from file
  Future<String> cacheImageFromFile(String url, File imageFile) async {
    if (_cacheDir == null) await init();

    final fileName = _generateFileName(url);
    final targetFile = File('${_cacheDir!.path}/$fileName');

    await imageFile.copy(targetFile.path);
    return targetFile.path;
  }

  // Prune cache to size limit
  Future<void> pruneCacheToSize(int maxSizeBytes) async {
    if (_cacheDir == null) await init();

    final files = <FileSystemEntity>[];
    await for (final entity in _cacheDir!.list()) {
      if (entity is File) {
        files.add(entity);
      }
    }

    // Sort by modification date (oldest first)
    files.sort((a, b) {
      final aStat = a.statSync();
      final bStat = b.statSync();
      return aStat.modified.compareTo(bStat.modified);
    });

    int currentSize = await getCacheSize();

    for (final file in files) {
      if (currentSize <= maxSizeBytes) break;

      final stat = file.statSync();
      currentSize -= stat.size;
      await file.delete();
    }
  }
}
