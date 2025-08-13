// lib/data/models/invoice/invoice_status.dart
import 'package:freezed_annotation/freezed_annotation.dart';

enum InvoiceStatus {
  @JsonValue('draft')
  draft,

  @JsonValue('pending')
  pending,

  @JsonValue('sent')
  sent,

  @JsonValue('viewed')
  viewed,

  @JsonValue('partial_payment')
  partialPayment,

  @JsonValue('paid')
  paid,

  @JsonValue('overdue')
  overdue,

  @JsonValue('cancelled')
  cancelled,

  @JsonValue('refunded')
  refunded,

  @JsonValue('disputed')
  disputed,

  @JsonValue('archived')
  archived;

  /// Display-friendly label for the status
  String get label {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.pending:
        return 'Pending';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.viewed:
        return 'Viewed';
      case InvoiceStatus.partialPayment:
        return 'Partial Payment';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
      case InvoiceStatus.refunded:
        return 'Refunded';
      case InvoiceStatus.disputed:
        return 'Disputed';
      case InvoiceStatus.archived:
        return 'Archived';
    }
  }

  /// Description of the status
  String get description {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Invoice is being prepared and not yet sent';
      case InvoiceStatus.pending:
        return 'Invoice is ready to be sent';
      case InvoiceStatus.sent:
        return 'Invoice has been sent to client';
      case InvoiceStatus.viewed:
        return 'Client has viewed the invoice';
      case InvoiceStatus.partialPayment:
        return 'Invoice has been partially paid';
      case InvoiceStatus.paid:
        return 'Invoice has been fully paid';
      case InvoiceStatus.overdue:
        return 'Invoice payment is past due date';
      case InvoiceStatus.cancelled:
        return 'Invoice has been cancelled';
      case InvoiceStatus.refunded:
        return 'Invoice payment has been refunded';
      case InvoiceStatus.disputed:
        return 'Invoice payment is under dispute';
      case InvoiceStatus.archived:
        return 'Invoice has been archived';
    }
  }

  /// Color associated with the status (hex string)
  String get colorHex {
    switch (this) {
      case InvoiceStatus.draft:
        return '#9E9E9E'; // Grey
      case InvoiceStatus.pending:
        return '#FF9800'; // Orange
      case InvoiceStatus.sent:
        return '#2196F3'; // Blue
      case InvoiceStatus.viewed:
        return '#03A9F4'; // Light Blue
      case InvoiceStatus.partialPayment:
        return '#FF9800'; // Orange
      case InvoiceStatus.paid:
        return '#4CAF50'; // Green
      case InvoiceStatus.overdue:
        return '#F44336'; // Red
      case InvoiceStatus.cancelled:
        return '#795548'; // Brown
      case InvoiceStatus.refunded:
        return '#9C27B0'; // Purple
      case InvoiceStatus.disputed:
        return '#E91E63'; // Pink
      case InvoiceStatus.archived:
        return '#607D8B'; // Blue Grey
    }
  }

  /// Icon name associated with the status
  String get iconName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'edit';
      case InvoiceStatus.pending:
        return 'schedule';
      case InvoiceStatus.sent:
        return 'send';
      case InvoiceStatus.viewed:
        return 'visibility';
      case InvoiceStatus.partialPayment:
        return 'payment';
      case InvoiceStatus.paid:
        return 'check_circle';
      case InvoiceStatus.overdue:
        return 'schedule';
      case InvoiceStatus.cancelled:
        return 'cancel';
      case InvoiceStatus.refunded:
        return 'undo';
      case InvoiceStatus.disputed:
        return 'report_problem';
      case InvoiceStatus.archived:
        return 'archive';
    }
  }

  /// Priority level for sorting (higher number = higher priority)
  int get priority {
    switch (this) {
      case InvoiceStatus.overdue:
        return 100;
      case InvoiceStatus.disputed:
        return 90;
      case InvoiceStatus.partialPayment:
        return 80;
      case InvoiceStatus.sent:
        return 70;
      case InvoiceStatus.viewed:
        return 65;
      case InvoiceStatus.pending:
        return 60;
      case InvoiceStatus.draft:
        return 50;
      case InvoiceStatus.paid:
        return 40;
      case InvoiceStatus.refunded:
        return 30;
      case InvoiceStatus.cancelled:
        return 20;
      case InvoiceStatus.archived:
        return 10;
    }
  }

  /// Whether the invoice can be edited in this status
  bool get canEdit {
    switch (this) {
      case InvoiceStatus.draft:
      case InvoiceStatus.pending:
        return true;
      case InvoiceStatus.sent:
      case InvoiceStatus.viewed:
      case InvoiceStatus.partialPayment:
      case InvoiceStatus.paid:
      case InvoiceStatus.overdue:
      case InvoiceStatus.cancelled:
      case InvoiceStatus.refunded:
      case InvoiceStatus.disputed:
      case InvoiceStatus.archived:
        return false;
    }
  }

  /// Whether the invoice can be sent in this status
  bool get canSend {
    switch (this) {
      case InvoiceStatus.draft:
      case InvoiceStatus.pending:
        return true;
      case InvoiceStatus.sent:
      case InvoiceStatus.viewed:
      case InvoiceStatus.partialPayment:
      case InvoiceStatus.paid:
      case InvoiceStatus.overdue:
      case InvoiceStatus.cancelled:
      case InvoiceStatus.refunded:
      case InvoiceStatus.disputed:
      case InvoiceStatus.archived:
        return false;
    }
  }

  /// Whether the invoice can be cancelled in this status
  bool get canCancel {
    switch (this) {
      case InvoiceStatus.draft:
      case InvoiceStatus.pending:
      case InvoiceStatus.sent:
      case InvoiceStatus.viewed:
      case InvoiceStatus.overdue:
        return true;
      case InvoiceStatus.partialPayment:
      case InvoiceStatus.paid:
      case InvoiceStatus.cancelled:
      case InvoiceStatus.refunded:
      case InvoiceStatus.disputed:
      case InvoiceStatus.archived:
        return false;
    }
  }

  /// Whether the invoice can be archived in this status
  bool get canArchive {
    switch (this) {
      case InvoiceStatus.paid:
      case InvoiceStatus.cancelled:
      case InvoiceStatus.refunded:
        return true;
      case InvoiceStatus.draft:
      case InvoiceStatus.pending:
      case InvoiceStatus.sent:
      case InvoiceStatus.viewed:
      case InvoiceStatus.partialPayment:
      case InvoiceStatus.overdue:
      case InvoiceStatus.disputed:
      case InvoiceStatus.archived:
        return false;
    }
  }

  /// Whether payments can be recorded for this invoice
  bool get canRecordPayment {
    switch (this) {
      case InvoiceStatus.sent:
      case InvoiceStatus.viewed:
      case InvoiceStatus.partialPayment:
      case InvoiceStatus.overdue:
        return true;
      case InvoiceStatus.draft:
      case InvoiceStatus.pending:
      case InvoiceStatus.paid:
      case InvoiceStatus.cancelled:
      case InvoiceStatus.refunded:
      case InvoiceStatus.disputed:
      case InvoiceStatus.archived:
        return false;
    }
  }

  /// Whether the invoice can be duplicated
  bool get canDuplicate {
    switch (this) {
      case InvoiceStatus.draft:
      case InvoiceStatus.pending:
      case InvoiceStatus.sent:
      case InvoiceStatus.viewed:
      case InvoiceStatus.partialPayment:
      case InvoiceStatus.paid:
      case InvoiceStatus.overdue:
      case InvoiceStatus.cancelled:
        return true;
      case InvoiceStatus.refunded:
      case InvoiceStatus.disputed:
      case InvoiceStatus.archived:
        return false;
    }
  }

  /// Whether reminders can be sent for this invoice
  bool get canSendReminder {
    switch (this) {
      case InvoiceStatus.sent:
      case InvoiceStatus.viewed:
      case InvoiceStatus.partialPayment:
      case InvoiceStatus.overdue:
        return true;
      case InvoiceStatus.draft:
      case InvoiceStatus.pending:
      case InvoiceStatus.paid:
      case InvoiceStatus.cancelled:
      case InvoiceStatus.refunded:
      case InvoiceStatus.disputed:
      case InvoiceStatus.archived:
        return false;
    }
  }

  /// Whether the invoice is in a final state
  bool get isFinal {
    switch (this) {
      case InvoiceStatus.paid:
      case InvoiceStatus.cancelled:
      case InvoiceStatus.refunded:
      case InvoiceStatus.archived:
        return true;
      case InvoiceStatus.draft:
      case InvoiceStatus.pending:
      case InvoiceStatus.sent:
      case InvoiceStatus.viewed:
      case InvoiceStatus.partialPayment:
      case InvoiceStatus.overdue:
      case InvoiceStatus.disputed:
        return false;
    }
  }

  /// Whether the invoice is awaiting payment
  bool get isAwaitingPayment {
    switch (this) {
      case InvoiceStatus.sent:
      case InvoiceStatus.viewed:
      case InvoiceStatus.partialPayment:
      case InvoiceStatus.overdue:
        return true;
      case InvoiceStatus.draft:
      case InvoiceStatus.pending:
      case InvoiceStatus.paid:
      case InvoiceStatus.cancelled:
      case InvoiceStatus.refunded:
      case InvoiceStatus.disputed:
      case InvoiceStatus.archived:
        return false;
    }
  }

  /// Whether the invoice needs immediate attention
  bool get needsAttention {
    switch (this) {
      case InvoiceStatus.overdue:
      case InvoiceStatus.disputed:
        return true;
      case InvoiceStatus.draft:
      case InvoiceStatus.pending:
      case InvoiceStatus.sent:
      case InvoiceStatus.viewed:
      case InvoiceStatus.partialPayment:
      case InvoiceStatus.paid:
      case InvoiceStatus.cancelled:
      case InvoiceStatus.refunded:
      case InvoiceStatus.archived:
        return false;
    }
  }

  /// Whether the invoice affects revenue (is paid or partially paid)
  bool get affectsRevenue {
    switch (this) {
      case InvoiceStatus.partialPayment:
      case InvoiceStatus.paid:
        return true;
      case InvoiceStatus.draft:
      case InvoiceStatus.pending:
      case InvoiceStatus.sent:
      case InvoiceStatus.viewed:
      case InvoiceStatus.overdue:
      case InvoiceStatus.cancelled:
      case InvoiceStatus.refunded:
      case InvoiceStatus.disputed:
      case InvoiceStatus.archived:
        return false;
    }
  }

  /// Valid next statuses from current status
  List<InvoiceStatus> get validTransitions {
    switch (this) {
      case InvoiceStatus.draft:
        return [
          InvoiceStatus.pending,
          InvoiceStatus.sent,
          InvoiceStatus.cancelled,
        ];
      case InvoiceStatus.pending:
        return [
          InvoiceStatus.draft,
          InvoiceStatus.sent,
          InvoiceStatus.cancelled,
        ];
      case InvoiceStatus.sent:
        return [
          InvoiceStatus.viewed,
          InvoiceStatus.partialPayment,
          InvoiceStatus.paid,
          InvoiceStatus.overdue,
          InvoiceStatus.cancelled,
        ];
      case InvoiceStatus.viewed:
        return [
          InvoiceStatus.partialPayment,
          InvoiceStatus.paid,
          InvoiceStatus.overdue,
          InvoiceStatus.cancelled,
        ];
      case InvoiceStatus.partialPayment:
        return [
          InvoiceStatus.paid,
          InvoiceStatus.overdue,
          InvoiceStatus.disputed,
        ];
      case InvoiceStatus.paid:
        return [
          InvoiceStatus.refunded,
          InvoiceStatus.disputed,
          InvoiceStatus.archived,
        ];
      case InvoiceStatus.overdue:
        return [
          InvoiceStatus.partialPayment,
          InvoiceStatus.paid,
          InvoiceStatus.cancelled,
          InvoiceStatus.disputed,
        ];
      case InvoiceStatus.cancelled:
        return [InvoiceStatus.archived];
      case InvoiceStatus.refunded:
        return [InvoiceStatus.archived];
      case InvoiceStatus.disputed:
        return [
          InvoiceStatus.paid,
          InvoiceStatus.cancelled,
          InvoiceStatus.refunded,
        ];
      case InvoiceStatus.archived:
        return []; // Final state
    }
  }

  /// Check if transition to another status is valid
  bool canTransitionTo(InvoiceStatus newStatus) {
    return validTransitions.contains(newStatus);
  }

  /// Get all statuses that need attention
  static List<InvoiceStatus> get attentionRequired {
    return values.where((status) => status.needsAttention).toList();
  }

  /// Get all statuses awaiting payment
  static List<InvoiceStatus> get awaitingPayment {
    return values.where((status) => status.isAwaitingPayment).toList();
  }

  /// Get all final statuses
  static List<InvoiceStatus> get finalStatuses {
    return values.where((status) => status.isFinal).toList();
  }

  /// Get all statuses that affect revenue
  static List<InvoiceStatus> get revenueStatuses {
    return values.where((status) => status.affectsRevenue).toList();
  }

  /// Convert from string value
  static InvoiceStatus fromString(String value) {
    return values.firstWhere(
      (status) => status.name == value,
      orElse: () => InvoiceStatus.draft,
    );
  }

  /// Get the next logical status based on business rules
  InvoiceStatus? getNextLogicalStatus() {
    switch (this) {
      case InvoiceStatus.draft:
        return InvoiceStatus.pending;
      case InvoiceStatus.pending:
        return InvoiceStatus.sent;
      case InvoiceStatus.sent:
        return InvoiceStatus.viewed;
      case InvoiceStatus.viewed:
        return InvoiceStatus.paid;
      case InvoiceStatus.partialPayment:
        return InvoiceStatus.paid;
      case InvoiceStatus.paid:
        return InvoiceStatus.archived;
      case InvoiceStatus.overdue:
        return InvoiceStatus.paid;
      case InvoiceStatus.cancelled:
        return InvoiceStatus.archived;
      case InvoiceStatus.refunded:
        return InvoiceStatus.archived;
      case InvoiceStatus.disputed:
        return null; // Requires manual resolution
      case InvoiceStatus.archived:
        return null; // Final state
    }
  }
}
