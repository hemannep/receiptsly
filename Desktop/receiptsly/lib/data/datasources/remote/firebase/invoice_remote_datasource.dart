import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../models/invoice/invoice_model.dart';

class InvoiceRemoteDataSource {
  final FirebaseFirestore _firestore;

  InvoiceRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create invoice
  Future<String> createInvoice(InvoiceModel invoice) async {
    try {
      final invoiceData = invoice.toJson();
      invoiceData['createdAt'] = FieldValue.serverTimestamp();
      invoiceData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('invoices').add(invoiceData);
      return docRef.id;
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to create invoice: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to create invoice: $e');
    }
  }

  // Update invoice
  Future<void> updateInvoice(InvoiceModel invoice) async {
    try {
      final invoiceData = invoice.toJson();
      invoiceData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('invoices')
          .doc(invoice.id)
          .update(invoiceData);
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to update invoice: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to update invoice: $e');
    }
  }

  // Get invoice by ID
  Future<InvoiceModel?> getInvoiceById(String id) async {
    try {
      final doc = await _firestore.collection('invoices').doc(id).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;

      return InvoiceModel.fromJson(data);
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to get invoice: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to get invoice: $e');
    }
  }

  // Get invoices by user ID
  Future<List<InvoiceModel>> getInvoicesByUserId(
    String userId, {
    int? limit,
    DocumentSnapshot? lastDocument,
    String? status,
    String? clientId,
  }) async {
    try {
      Query query = _firestore
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .orderBy('issueDate', descending: true);

      // Apply filters
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      if (clientId != null && clientId.isNotEmpty) {
        query = query.where('clientId', isEqualTo: clientId);
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
        return InvoiceModel.fromJson(data);
      }).toList();
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to get invoices: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to get invoices: $e');
    }
  }

  // Delete invoice
  Future<void> deleteInvoice(String id) async {
    try {
      await _firestore.collection('invoices').doc(id).delete();
    } on FirebaseException catch (e) {
      throw RemoteDataException('Failed to delete invoice: ${e.message}');
    } catch (e) {
      throw RemoteDataException('Failed to delete invoice: $e');
    }
  }

  // Stream invoices by user ID
  Stream<List<InvoiceModel>> streamInvoicesByUserId(String userId) {
    return _firestore
        .collection('invoices')
        .where('userId', isEqualTo: userId)
        .orderBy('issueDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return InvoiceModel.fromJson(data);
          }).toList(),
        );
  }
}
