import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../models/receipt/receipt_model.dart';

class ReceiptRemoteDataSource {
  final FirebaseFirestore _firestore;

  ReceiptRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create receipt
  Future<String> createReceipt(ReceiptModel receipt) async {
    try {
      final receiptData = receipt.toJson();
      receiptData['createdAt'] = FieldValue.serverTimestamp();
      receiptData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('receipts').add(receiptData);
      return docRef.id;
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to create receipt: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to create receipt: $e');
    }
  }

  // Update receipt
  Future<void> updateReceipt(ReceiptModel receipt) async {
    try {
      final receiptData = receipt.toJson();
      receiptData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('receipts')
          .doc(receipt.id)
          .update(receiptData);
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to update receipt: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to update receipt: $e');
    }
  }

  // Get receipt by ID
  Future<ReceiptModel?> getReceiptById(String id) async {
    try {
      final doc = await _firestore.collection('receipts').doc(id).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;

      return ReceiptModel.fromJson(data);
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to get receipt: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to get receipt: $e');
    }
  }

  // Get receipts by user ID
  Future<List<ReceiptModel>> getReceiptsByUserId(
    String userId, {
    int? limit,
    DocumentSnapshot? lastDocument,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('receipts')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true);

      // Apply filters
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ReceiptModel.fromJson(data);
      }).toList();
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to get receipts: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to get receipts: $e');
    }
  }

  // Delete receipt
  Future<void> deleteReceipt(String id) async {
    try {
      await _firestore.collection('receipts').doc(id).delete();
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to delete receipt: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to delete receipt: $e');
    }
  }

  // Stream receipts by user ID
  Stream<List<ReceiptModel>> streamReceiptsByUserId(String userId) {
    return _firestore
        .collection('receipts')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return ReceiptModel.fromJson(data);
          }).toList(),
        );
  }

  // Batch create receipts
  Future<void> batchCreateReceipts(List<ReceiptModel> receipts) async {
    try {
      final batch = _firestore.batch();

      for (final receipt in receipts) {
        final docRef = _firestore.collection('receipts').doc();
        final receiptData = receipt.toJson();
        receiptData['id'] = docRef.id;
        receiptData['createdAt'] = FieldValue.serverTimestamp();
        receiptData['updatedAt'] = FieldValue.serverTimestamp();

        batch.set(docRef, receiptData);
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw RemoteDataException(
        'Failed to batch create receipts: ${e.message}',
      );
    } catch (e) {
      throw RemoteDataException('Failed to batch create receipts: $e');
    }
  }
}
