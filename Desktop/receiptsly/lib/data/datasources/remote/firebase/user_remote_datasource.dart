import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../models/user/user_model.dart';

class UserRemoteDataSource {
  final FirebaseFirestore _firestore;

  UserRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create or update user
  Future<void> saveUser(UserModel user) async {
    try {
      final userData = user.toJson();
      userData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to save user: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to save user: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return UserModel.fromJson(data);
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to get user: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to get user: $e');
    }
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    try {
      final userData = user.toJson();
      userData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(user.uid).update(userData);
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to update user: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to update user: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to delete user: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to delete user: $e');
    }
  }

  // Stream user data
  Stream<UserModel?> streamUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    });
  }
}
