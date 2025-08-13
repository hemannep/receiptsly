import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/errors/exceptions.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  // Upload file
  Future<String> uploadFile({
    required String path,
    required File file,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      final ref = _storage.ref().child(path);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: contentType, customMetadata: metadata),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw RemoteDataException('File upload failed: ${e.message}');
    } catch (e) {
      throw RemoteDataException('File upload failed: $e');
    }
  }

  // Upload bytes
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      final ref = _storage.ref().child(path);

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: contentType, customMetadata: metadata),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw RemoteDataException('Bytes upload failed: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Bytes upload failed: $e');
    }
  }

  // Delete file
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } on FirebaseException catch (e) {
      throw RemoteDataException('File deletion failed: ${e.message}');
    } catch (e) {
      throw RemoteDataException('File deletion failed: $e');
    }
  }

  // Get download URL
  Future<String> getDownloadURL(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } on FirebaseException catch (e) {
      throw RemoteDataException('Get download URL failed: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Get download URL failed: $e');
    }
  }
}
