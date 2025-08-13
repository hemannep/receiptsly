import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/invoice/invoice_model.dart';
import '../../data/models/client/client_model.dart';
import '../../services/invoice/invoice_service.dart';
import '../../core/errors/failures.dart';

// Invoice Service Provider
final invoiceServiceProvider = Provider<InvoiceService>(
  (ref) => InvoiceService(),
);

// Invoice State Notifier
class InvoiceStateNotifier
    extends StateNotifier<AsyncValue<List<InvoiceModel>>> {
  final String userId;
  final InvoiceService _invoiceService;

  InvoiceStateNotifier(this.userId, this._invoiceService)
    : super(const AsyncValue.loading()) {
    _loadInvoices();
  }

  void _loadInvoices() {
    FirebaseFirestore.instance
        .collection('invoices')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final invoices = snapshot.docs
                .map(
                  (doc) => InvoiceModel.fromJson({'id': doc.id, ...doc.data()}),
                )
                .toList();
            state = AsyncValue.data(invoices);
          },
          onError: (error, stackTrace) =>
              state = AsyncValue.error(error, stackTrace),
        );
  }

  // Create Invoice
  Future<InvoiceModel> createInvoice({
    required String clientId,
    required List<InvoiceItemModel> items,
    required DateTime dueDate,
    String? notes,
    String? terms,
    double? taxRate,
    double? discountAmount,
  }) async {
    try {
      final invoice = InvoiceModel(
        id: '',
        userId: userId,
        clientId: clientId,
        invoiceNumber: await _generateInvoiceNumber(),
        items: items,
        issueDate: DateTime.now(),
        dueDate: dueDate,
        status: InvoiceStatus.draft,
        subtotal: _calculateSubtotal(items),
        taxRate: taxRate ?? 0.0,
        taxAmount: _calculateTax(items, taxRate ?? 0.0),
        discountAmount: discountAmount ?? 0.0,
        total: _calculateTotal(items, taxRate ?? 0.0, discountAmount ?? 0.0),
        notes: notes,
        terms: terms,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await FirebaseFirestore.instance
          .collection('invoices')
          .add(invoice.toJson());

      return invoice.copyWith(id: docRef.id);
    } catch (error) {
      throw InvoiceFailure('Failed to create invoice');
    }
  }

  // Update Invoice
  Future<void> updateInvoice(
    String invoiceId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(invoiceId)
          .update({...updates, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (error) {
      throw InvoiceFailure('Failed to update invoice');
    }
  }

  // Send Invoice
  Future<void> sendInvoice(String invoiceId) async {
    try {
      await _invoiceService.sendInvoice(invoiceId);
      await updateInvoice(invoiceId, {
        'status': InvoiceStatus.sent.toString(),
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw InvoiceFailure('Failed to send invoice');
    }
  }

  // Mark as Paid
  Future<void> markAsPaid(String invoiceId, {DateTime? paymentDate}) async {
    try {
      await updateInvoice(invoiceId, {
        'status': InvoiceStatus.paid.toString(),
        'paidAt': paymentDate ?? DateTime.now(),
      });
    } catch (error) {
      throw InvoiceFailure('Failed to mark invoice as paid');
    }
  }

  // Delete Invoice
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(invoiceId)
          .delete();
    } catch (error) {
      throw InvoiceFailure('Failed to delete invoice');
    }
  }

  Future<String> _generateInvoiceNumber() async {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');

    // Get last invoice number for this month
    final snapshot = await FirebaseFirestore.instance
        .collection('invoices')
        .where('userId', isEqualTo: userId)
        .where('invoiceNumber', isGreaterThanOrEqualTo: 'INV-$year$month')
        .where('invoiceNumber', isLessThan: 'INV-$year$month\uf8ff')
        .orderBy('invoiceNumber', descending: true)
        .limit(1)
        .get();

    int nextNumber = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastInvoiceNumber =
          snapshot.docs.first.data()['invoiceNumber'] as String;
      final lastNumber = int.tryParse(lastInvoiceNumber.split('-').last) ?? 0;
      nextNumber = lastNumber + 1;
    }

    return 'INV-$year$month${nextNumber.toString().padLeft(3, '0')}';
  }

  double _calculateSubtotal(List<InvoiceItemModel> items) {
    return items.fold(0.0, (sum, item) => sum + item.amount);
  }

  double _calculateTax(List<InvoiceItemModel> items, double taxRate) {
    final subtotal = _calculateSubtotal(items);
    return subtotal * (taxRate / 100);
  }

  double _calculateTotal(
    List<InvoiceItemModel> items,
    double taxRate,
    double discountAmount,
  ) {
    final subtotal = _calculateSubtotal(items);
    final tax = _calculateTax(items, taxRate);
    return subtotal + tax - discountAmount;
  }
}

// Invoice Provider
final invoiceProvider =
    StateNotifierProvider.family<
      InvoiceStateNotifier,
      AsyncValue<List<InvoiceModel>>,
      String
    >((ref, userId) {
      return InvoiceStateNotifier(userId, ref.watch(invoiceServiceProvider));
    });

// Client State Notifier
class ClientStateNotifier extends StateNotifier<AsyncValue<List<ClientModel>>> {
  final String userId;

  ClientStateNotifier(this.userId) : super(const AsyncValue.loading()) {
    _loadClients();
  }

  void _loadClients() {
    FirebaseFirestore.instance
        .collection('clients')
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()
        .listen(
          (snapshot) {
            final clients = snapshot.docs
                .map(
                  (doc) => ClientModel.fromJson({'id': doc.id, ...doc.data()}),
                )
                .toList();
            state = AsyncValue.data(clients);
          },
          onError: (error, stackTrace) =>
              state = AsyncValue.error(error, stackTrace),
        );
  }

  // Add Client
  Future<void> addClient(ClientModel client) async {
    try {
      await FirebaseFirestore.instance
          .collection('clients')
          .add(client.toJson());
    } catch (error) {
      throw ClientFailure('Failed to add client');
    }
  }

  // Update Client
  Future<void> updateClient(
    String clientId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('clients')
          .doc(clientId)
          .update({...updates, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (error) {
      throw ClientFailure('Failed to update client');
    }
  }

  // Delete Client
  Future<void> deleteClient(String clientId) async {
    try {
      await FirebaseFirestore.instance
          .collection('clients')
          .doc(clientId)
          .delete();
    } catch (error) {
      throw ClientFailure('Failed to delete client');
    }
  }
}

// Client Provider
final clientProvider =
    StateNotifierProvider.family<
      ClientStateNotifier,
      AsyncValue<List<ClientModel>>,
      String
    >((ref, userId) {
      return ClientStateNotifier(userId);
    });

// Invoice Draft State
class InvoiceDraftState {
  final String? clientId;
  final List<InvoiceItemModel> items;
  final DateTime? dueDate;
  final String? notes;
  final String? terms;
  final double taxRate;
  final double discountAmount;

  const InvoiceDraftState({
    this.clientId,
    this.items = const [],
    this.dueDate,
    this.notes,
    this.terms,
    this.taxRate = 0.0,
    this.discountAmount = 0.0,
  });

  InvoiceDraftState copyWith({
    String? clientId,
    List<InvoiceItemModel>? items,
    DateTime? dueDate,
    String? notes,
    String? terms,
    double? taxRate,
    double? discountAmount,
  }) {
    return InvoiceDraftState(
      clientId: clientId ?? this.clientId,
      items: items ?? this.items,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      taxRate: taxRate ?? this.taxRate,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.amount);
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount - discountAmount;
}

// Invoice Draft Notifier
class InvoiceDraftNotifier extends StateNotifier<InvoiceDraftState> {
  InvoiceDraftNotifier() : super(const InvoiceDraftState());

  void updateClient(String clientId) {
    state = state.copyWith(clientId: clientId);
  }

  void addItem(InvoiceItemModel item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void updateItem(int index, InvoiceItemModel item) {
    final updatedItems = [...state.items];
    updatedItems[index] = item;
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(int index) {
    final updatedItems = [...state.items];
    updatedItems.removeAt(index);
    state = state.copyWith(items: updatedItems);
  }

  void updateDueDate(DateTime dueDate) {
    state = state.copyWith(dueDate: dueDate);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void updateTerms(String terms) {
    state = state.copyWith(terms: terms);
  }

  void updateTaxRate(double taxRate) {
    state = state.copyWith(taxRate: taxRate);
  }

  void updateDiscountAmount(double discountAmount) {
    state = state.copyWith(discountAmount: discountAmount);
  }

  void reset() {
    state = const InvoiceDraftState();
  }
}

// Invoice Draft Provider
final invoiceDraftProvider =
    StateNotifierProvider<InvoiceDraftNotifier, InvoiceDraftState>((ref) {
      return InvoiceDraftNotifier();
    });

// Invoice Statistics Provider
final invoiceStatsProvider = Provider.family<Map<String, dynamic>, String>((
  ref,
  userId,
) {
  final invoicesAsync = ref.watch(invoiceProvider(userId));

  return invoicesAsync.when(
    data: (invoices) {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);

      final currentMonthInvoices = invoices
          .where((invoice) => invoice.createdAt.isAfter(currentMonth))
          .toList();

      final paidInvoices = invoices
          .where((invoice) => invoice.status == InvoiceStatus.paid)
          .toList();

      final overdueInvoices = invoices
          .where(
            (invoice) =>
                invoice.status == InvoiceStatus.sent &&
                invoice.dueDate.isBefore(now),
          )
          .toList();

      final totalRevenue = paidInvoices.fold(
        0.0,
        (sum, invoice) => sum + invoice.total,
      );

      final pendingAmount = invoices
          .where((invoice) => invoice.status == InvoiceStatus.sent)
          .fold(0.0, (sum, invoice) => sum + invoice.total);

      return {
        'totalInvoices': invoices.length,
        'currentMonthInvoices': currentMonthInvoices.length,
        'paidInvoices': paidInvoices.length,
        'overdueInvoices': overdueInvoices.length,
        'totalRevenue': totalRevenue,
        'pendingAmount': pendingAmount,
      };
    },
    loading: () => <String, dynamic>{},
    error: (_, __) => <String, dynamic>{},
  );
});
