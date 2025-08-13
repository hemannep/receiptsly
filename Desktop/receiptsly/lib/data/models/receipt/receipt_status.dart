// lib/data/models/receipt/receipt_status.dart
import 'package:freezed_annotation/freezed_annotation.dart';

enum ReceiptStatus {
  @JsonValue('pending')
  pending,

  @JsonValue('processing')
  processing,

  @JsonValue('processed')
  processed,

  @JsonValue('review_required')
  reviewRequired,

  @JsonValue('approved')
  approved,

  @JsonValue('rejected')
  rejected,

  @JsonValue('archived')
  archived,

  @JsonValue('deleted')
  deleted,

  @JsonValue('error')
  error;

  /// Display-friendly label for the status
  String get label {
    switch (this) {
      case ReceiptStatus.pending:
        return 'Pending';
      case ReceiptStatus.processing:
        return 'Processing';
      case ReceiptStatus.processed:
        return 'Processed';
      case ReceiptStatus.reviewRequired:
        return 'Review Required';
      case ReceiptStatus.approved:
        return 'Approved';
      case ReceiptStatus.rejected:
        return 'Rejected';
      case ReceiptStatus.archived:
        return 'Archived';
      case ReceiptStatus.deleted:
        return 'Deleted';
      case ReceiptStatus.error:
        return 'Error';
    }
  }

  /// Description of the status
  String get description {
    switch (this) {
      case ReceiptStatus.pending:
        return 'Receipt is waiting to be processed';
      case ReceiptStatus.processing:
        return 'Receipt is being processed by OCR';
      case ReceiptStatus.processed:
        return 'Receipt has been successfully processed';
      case ReceiptStatus.reviewRequired:
        return 'Receipt requires manual review';
      case ReceiptStatus.approved:
        return 'Receipt has been reviewed and approved';
      case ReceiptStatus.rejected:
        return 'Receipt has been rejected';
      case ReceiptStatus.archived:
        return 'Receipt has been archived';
      case ReceiptStatus.deleted:
        return 'Receipt has been deleted';
      case ReceiptStatus.error:
        return 'An error occurred while processing';
    }
  }

  /// Color associated with the status (hex string)
  String get colorHex {
    switch (this) {
      case ReceiptStatus.pending:
        return '#FFA726'; // Orange
      case ReceiptStatus.processing:
        return '#42A5F5'; // Blue
      case ReceiptStatus.processed:
        return '#66BB6A'; // Green
      case ReceiptStatus.reviewRequired:
        return '#FF7043'; // Deep Orange
      case ReceiptStatus.approved:
        return '#4CAF50'; // Green
      case ReceiptStatus.rejected:
        return '#F44336'; // Red
      case ReceiptStatus.archived:
        return '#9E9E9E'; // Grey
      case ReceiptStatus.deleted:
        return '#424242'; // Dark Grey
      case ReceiptStatus.error:
        return '#E53935'; // Red
    }
  }

  /// Icon name associated with the status
  String get iconName {
    switch (this) {
      case ReceiptStatus.pending:
        return 'access_time';
      case ReceiptStatus.processing:
        return 'autorenew';
      case ReceiptStatus.processed:
        return 'check_circle';
      case ReceiptStatus.reviewRequired:
        return 'rate_review';
      case ReceiptStatus.approved:
        return 'check_circle_outline';
      case ReceiptStatus.rejected:
        return 'cancel';
      case ReceiptStatus.archived:
        return 'archive';
      case ReceiptStatus.deleted:
        return 'delete';
      case ReceiptStatus.error:
        return 'error';
    }
  }

  /// Priority level for sorting (higher number = higher priority)
  int get priority {
    switch (this) {
      case ReceiptStatus.error:
        return 100;
      case ReceiptStatus.reviewRequired:
        return 90;
      case ReceiptStatus.processing:
        return 80;
      case ReceiptStatus.pending:
        return 70;
      case ReceiptStatus.processed:
        return 60;
      case ReceiptStatus.approved:
        return 50;
      case ReceiptStatus.rejected:
        return 40;
      case ReceiptStatus.archived:
        return 30;
      case ReceiptStatus.deleted:
        return 10;
    }
  }

  /// Whether the receipt can be edited in this status
  bool get canEdit {
    switch (this) {
      case ReceiptStatus.pending:
      case ReceiptStatus.reviewRequired:
      case ReceiptStatus.processed:
        return true;
      case ReceiptStatus.processing:
      case ReceiptStatus.approved:
      case ReceiptStatus.rejected:
      case ReceiptStatus.archived:
      case ReceiptStatus.deleted:
      case ReceiptStatus.error:
        return false;
    }
  }

  /// Whether the receipt can be deleted in this status
  bool get canDelete {
    switch (this) {
      case ReceiptStatus.pending:
      case ReceiptStatus.reviewRequired:
      case ReceiptStatus.processed:
      case ReceiptStatus.rejected:
      case ReceiptStatus.error:
        return true;
      case ReceiptStatus.processing:
      case ReceiptStatus.approved:
      case ReceiptStatus.archived:
      case ReceiptStatus.deleted:
        return false;
    }
  }

  /// Whether the receipt can be archived in this status
  bool get canArchive {
    switch (this) {
      case ReceiptStatus.processed:
      case ReceiptStatus.approved:
      case ReceiptStatus.rejected:
        return true;
      case ReceiptStatus.pending:
      case ReceiptStatus.processing:
      case ReceiptStatus.reviewRequired:
      case ReceiptStatus.archived:
      case ReceiptStatus.deleted:
      case ReceiptStatus.error:
        return false;
    }
  }

  /// Whether the receipt can be approved in this status
  bool get canApprove {
    switch (this) {
      case ReceiptStatus.processed:
      case ReceiptStatus.reviewRequired:
        return true;
      case ReceiptStatus.pending:
      case ReceiptStatus.processing:
      case ReceiptStatus.approved:
      case ReceiptStatus.rejected:
      case ReceiptStatus.archived:
      case ReceiptStatus.deleted:
      case ReceiptStatus.error:
        return false;
    }
  }

  /// Whether the receipt can be rejected in this status
  bool get canReject {
    switch (this) {
      case ReceiptStatus.processed:
      case ReceiptStatus.reviewRequired:
        return true;
      case ReceiptStatus.pending:
      case ReceiptStatus.processing:
      case ReceiptStatus.approved:
      case ReceiptStatus.rejected:
      case ReceiptStatus.archived:
      case ReceiptStatus.deleted:
      case ReceiptStatus.error:
        return false;
    }
  }

  /// Whether the receipt is in a final state
  bool get isFinal {
    switch (this) {
      case ReceiptStatus.approved:
      case ReceiptStatus.archived:
      case ReceiptStatus.deleted:
        return true;
      case ReceiptStatus.pending:
      case ReceiptStatus.processing:
      case ReceiptStatus.processed:
      case ReceiptStatus.reviewRequired:
      case ReceiptStatus.rejected:
      case ReceiptStatus.error:
        return false;
    }
  }

  /// Whether the receipt is in an active processing state
  bool get isActive {
    switch (this) {
      case ReceiptStatus.pending:
      case ReceiptStatus.processing:
      case ReceiptStatus.processed:
      case ReceiptStatus.reviewRequired:
        return true;
      case ReceiptStatus.approved:
      case ReceiptStatus.rejected:
      case ReceiptStatus.archived:
      case ReceiptStatus.deleted:
      case ReceiptStatus.error:
        return false;
    }
  }

  /// Whether the receipt needs attention from the user
  bool get needsAttention {
    switch (this) {
      case ReceiptStatus.reviewRequired:
      case ReceiptStatus.error:
        return true;
      case ReceiptStatus.pending:
      case ReceiptStatus.processing:
      case ReceiptStatus.processed:
      case ReceiptStatus.approved:
      case ReceiptStatus.rejected:
      case ReceiptStatus.archived:
      case ReceiptStatus.deleted:
        return false;
    }
  }

  /// Valid next statuses from current status
  List<ReceiptStatus> get validTransitions {
    switch (this) {
      case ReceiptStatus.pending:
        return [
          ReceiptStatus.processing,
          ReceiptStatus.error,
          ReceiptStatus.deleted,
        ];
      case ReceiptStatus.processing:
        return [
          ReceiptStatus.processed,
          ReceiptStatus.reviewRequired,
          ReceiptStatus.error,
        ];
      case ReceiptStatus.processed:
        return [
          ReceiptStatus.approved,
          ReceiptStatus.rejected,
          ReceiptStatus.reviewRequired,
        ];
      case ReceiptStatus.reviewRequired:
        return [
          ReceiptStatus.approved,
          ReceiptStatus.rejected,
          ReceiptStatus.processed,
        ];
      case ReceiptStatus.approved:
        return [ReceiptStatus.archived];
      case ReceiptStatus.rejected:
        return [
          ReceiptStatus.processed,
          ReceiptStatus.archived,
          ReceiptStatus.deleted,
        ];
      case ReceiptStatus.archived:
        return [ReceiptStatus.processed]; // Can be unarchived
      case ReceiptStatus.deleted:
        return []; // Final state
      case ReceiptStatus.error:
        return [ReceiptStatus.pending, ReceiptStatus.deleted];
    }
  }

  /// Check if transition to another status is valid
  bool canTransitionTo(ReceiptStatus newStatus) {
    return validTransitions.contains(newStatus);
  }

  /// Get all statuses that require user attention
  static List<ReceiptStatus> get attentionRequired {
    return values.where((status) => status.needsAttention).toList();
  }

  /// Get all active statuses
  static List<ReceiptStatus> get activeStatuses {
    return values.where((status) => status.isActive).toList();
  }

  /// Get all final statuses
  static List<ReceiptStatus> get finalStatuses {
    return values.where((status) => status.isFinal).toList();
  }

  /// Convert from string value
  static ReceiptStatus fromString(String value) {
    return values.firstWhere(
      (status) => status.name == value,
      orElse: () => ReceiptStatus.pending,
    );
  }
}
