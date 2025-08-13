// lib/services/sync/conflict_resolver.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ConflictType {
  dataConflict,
  deleteConflict,
  schemaConflict,
  versionConflict,
}

enum ResolutionStrategy {
  localWins,
  remoteWins,
  lastWriteWins,
  manual,
  merge,
  duplicate,
}

class ConflictData {
  final String id;
  final String documentId;
  final String collection;
  final ConflictType type;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final ResolutionStrategy? strategy;
  final String? userComment;
  final bool isResolved;

  ConflictData({
    required this.id,
    required this.documentId,
    required this.collection,
    required this.type,
    required this.localData,
    required this.remoteData,
    required this.createdAt,
    this.resolvedAt,
    this.strategy,
    this.userComment,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'collection': collection,
      'type': type.index,
      'local_data': jsonEncode(localData),
      'remote_data': jsonEncode(remoteData),
      'created_at': createdAt.millisecondsSinceEpoch,
      'resolved_at': resolvedAt?.millisecondsSinceEpoch,
      'strategy': strategy?.index,
      'user_comment': userComment,
      'is_resolved': isResolved ? 1 : 0,
    };
  }

  factory ConflictData.fromMap(Map<String, dynamic> map) {
    return ConflictData(
      id: map['id'],
      documentId: map['document_id'],
      collection: map['collection'],
      type: ConflictType.values[map['type']],
      localData: jsonDecode(map['local_data']),
      remoteData: jsonDecode(map['remote_data']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['resolved_at'])
          : null,
      strategy: map['strategy'] != null
          ? ResolutionStrategy.values[map['strategy']]
          : null,
      userComment: map['user_comment'],
      isResolved: (map['is_resolved'] ?? 0) == 1,
    );
  }

  ConflictData copyWith({
    String? id,
    String? documentId,
    String? collection,
    ConflictType? type,
    Map<String, dynamic>? localData,
    Map<String, dynamic>? remoteData,
    DateTime? createdAt,
    DateTime? resolvedAt,
    ResolutionStrategy? strategy,
    String? userComment,
    bool? isResolved,
  }) {
    return ConflictData(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      collection: collection ?? this.collection,
      type: type ?? this.type,
      localData: localData ?? this.localData,
      remoteData: remoteData ?? this.remoteData,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      strategy: strategy ?? this.strategy,
      userComment: userComment ?? this.userComment,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}

class ConflictResolution {
  final ResolutionStrategy strategy;
  final Map<String, dynamic> resolvedData;
  final String? comment;

  ConflictResolution({
    required this.strategy,
    required this.resolvedData,
    this.comment,
  });
}

class ConflictResolver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<List<ConflictData>> _conflictsController = 
      StreamController<List<ConflictData>>.broadcast();

  Stream<List<ConflictData>> get conflictsStream => _conflictsController.stream;

  // Detect conflicts between local and remote data
  ConflictData? detectConflict({
    required String documentId,
    required String collection,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
  }) {
    try {
      // Check if data actually conflicts
      if (_isDataIdentical(localData, remoteData)) {
        return null; // No conflict
      }

      // Determine conflict type
      final conflictType = _determineConflictType(localData, remoteData);

      return ConflictData(
        id: _generateConflictId(),
        documentId: documentId,
        collection: collection,
        type: conflictType,
        localData: localData,
        remoteData: remoteData,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('ConflictResolver: Error detecting conflict - $e');
      return null;
    }
  }

  // Automatically resolve conflicts based on strategy
  Future<ConflictResolution?> autoResolveConflict(
    ConflictData conflict,
    ResolutionStrategy defaultStrategy,
  ) async {
    try {
      switch (defaultStrategy) {
        case ResolutionStrategy.lastWriteWins:
          return _resolveLastWriteWins(conflict);
        
        case ResolutionStrategy.localWins:
          return _resolveLocalWins(conflict);
        
        case ResolutionStrategy.remoteWins:
          return _resolveRemoteWins(conflict);
        
        case ResolutionStrategy.merge:
          return _resolveMerge(conflict);
        
        case ResolutionStrategy.duplicate:
        resolvedData = Map<String, dynamic>.from(conflict.localData);
        // Create duplicate with modified ID
        await _createDuplicate(conflict);
        break;
      
      case ResolutionStrategy.lastWriteWins:
        final resolution = _resolveLastWriteWins(conflict);
        resolvedData = resolution?.resolvedData ?? conflict.remoteData;
        break;
      
      case ResolutionStrategy.manual:
        resolvedData = customData ?? conflict.localData;
        break;
    }

    return ConflictResolution(
      strategy: strategy,
      resolvedData: resolvedData,
      comment: comment,
    );
  }

  // Apply conflict resolution
  Future<bool> applyResolution(
    ConflictData conflict,
    ConflictResolution resolution,
  ) async {
    try {
      // Update the document in Firestore
      await _updateFirestoreDocument(
        conflict.collection,
        conflict.documentId,
        resolution.resolvedData,
      );

      // Mark conflict as resolved
      await _markConflictResolved(
        conflict,
        resolution.strategy,
        resolution.comment,
      );

      debugPrint('ConflictResolver: Resolution applied for ${conflict.documentId}');
      return true;
    } catch (e) {
      debugPrint('ConflictResolver: Failed to apply resolution - $e');
      return false;
    }
  }

  // Batch resolve multiple conflicts
  Future<Map<String, bool>> batchResolveConflicts(
    List<ConflictData> conflicts,
    ResolutionStrategy strategy,
  ) async {
    final results = <String, bool>{};

    for (final conflict in conflicts) {
      try {
        final resolution = await autoResolveConflict(conflict, strategy);
        if (resolution != null) {
          final success = await applyResolution(conflict, resolution);
          results[conflict.id] = success;
        } else {
          results[conflict.id] = false;
        }
      } catch (e) {
        debugPrint('ConflictResolver: Batch resolution failed for ${conflict.id} - $e');
        results[conflict.id] = false;
      }
    }

    return results;
  }

  // Get conflict suggestions based on data analysis
  List<ResolutionStrategy> getSuggestedStrategies(ConflictData conflict) {
    final suggestions = <ResolutionStrategy>[];

    try {
      // Analyze timestamps
      final localTimestamp = _extractTimestamp(conflict.localData);
      final remoteTimestamp = _extractTimestamp(conflict.remoteData);

      if (localTimestamp != null && remoteTimestamp != null) {
        suggestions.add(ResolutionStrategy.lastWriteWins);
      }

      // Check if data can be merged
      if (_canMergeData(conflict.localData, conflict.remoteData)) {
        suggestions.add(ResolutionStrategy.merge);
      }

      // Always offer basic strategies
      suggestions.addAll([
        ResolutionStrategy.localWins,
        ResolutionStrategy.remoteWins,
        ResolutionStrategy.duplicate,
        ResolutionStrategy.manual,
      ]);

      return suggestions;
    } catch (e) {
      debugPrint('ConflictResolver: Error getting suggestions - $e');
      return [ResolutionStrategy.manual];
    }
  }

  // Get conflict impact analysis
  Map<String, dynamic> analyzeConflictImpact(ConflictData conflict) {
    final analysis = <String, dynamic>{};

    try {
      // Calculate data differences
      final differences = _calculateDifferences(conflict.localData, conflict.remoteData);
      analysis['differences'] = differences;
      analysis['differenceCount'] = differences.length;

      // Assess data completeness
      final localCompleteness = _assessDataCompleteness(conflict.localData);
      final remoteCompleteness = _assessDataCompleteness(conflict.remoteData);
      
      analysis['localCompleteness'] = localCompleteness;
      analysis['remoteCompleteness'] = remoteCompleteness;

      // Determine severity
      analysis['severity'] = _determineSeverity(conflict);

      // Check for data loss risks
      analysis['dataLossRisk'] = _assessDataLossRisk(conflict);

      return analysis;
    } catch (e) {
      debugPrint('ConflictResolver: Error analyzing impact - $e');
      return {'error': e.toString()};
    }
  }

  // Private helper methods

  ConflictResolution _resolveLastWriteWins(ConflictData conflict) {
    final localTimestamp = _extractTimestamp(conflict.localData);
    final remoteTimestamp = _extractTimestamp(conflict.remoteData);

    if (localTimestamp != null && remoteTimestamp != null) {
      if (localTimestamp.isAfter(remoteTimestamp)) {
        return ConflictResolution(
          strategy: ResolutionStrategy.lastWriteWins,
          resolvedData: conflict.localData,
          comment: 'Local data is newer',
        );
      } else {
        return ConflictResolution(
          strategy: ResolutionStrategy.lastWriteWins,
          resolvedData: conflict.remoteData,
          comment: 'Remote data is newer',
        );
      }
    }

    // Fallback to remote wins if timestamps are unavailable
    return ConflictResolution(
      strategy: ResolutionStrategy.remoteWins,
      resolvedData: conflict.remoteData,
      comment: 'Timestamp comparison failed, using remote data',
    );
  }

  ConflictResolution _resolveLocalWins(ConflictData conflict) {
    return ConflictResolution(
      strategy: ResolutionStrategy.localWins,
      resolvedData: conflict.localData,
      comment: 'Local data preserved',
    );
  }

  ConflictResolution _resolveRemoteWins(ConflictData conflict) {
    return ConflictResolution(
      strategy: ResolutionStrategy.remoteWins,
      resolvedData: conflict.remoteData,
      comment: 'Remote data accepted',
    );
  }

  ConflictResolution _resolveMerge(ConflictData conflict) {
    final mergedData = _mergeData(conflict.localData, conflict.remoteData);
    return ConflictResolution(
      strategy: ResolutionStrategy.merge,
      resolvedData: mergedData,
      comment: 'Data merged automatically',
    );
  }

  ConflictResolution _resolveDuplicate(ConflictData conflict) {
    return ConflictResolution(
      strategy: ResolutionStrategy.duplicate,
      resolvedData: conflict.localData,
      comment: 'Local data kept, remote data will be duplicated',
    );
  }

  Future<void> _createDuplicate(ConflictData conflict) async {
    try {
      final duplicateData = Map<String, dynamic>.from(conflict.remoteData);
      duplicateData['id'] = _generateDuplicateId(conflict.documentId);
      duplicateData['isDuplicate'] = true;
      duplicateData['originalId'] = conflict.documentId;
      duplicateData['duplicatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(conflict.collection)
          .doc(duplicateData['id'])
          .set(duplicateData);

      debugPrint('ConflictResolver: Created duplicate ${duplicateData['id']}');
    } catch (e) {
      debugPrint('ConflictResolver: Failed to create duplicate - $e');
      throw ConflictResolverException('Failed to create duplicate: $e');
    }
  }

  bool _isDataIdentical(Map<String, dynamic> data1, Map<String, dynamic> data2) {
    try {
      // Remove timestamp fields for comparison
      final filtered1 = _removeTimestampFields(data1);
      final filtered2 = _removeTimestampFields(data2);

      return const DeepCollectionEquality().equals(filtered1, filtered2);
    } catch (e) {
      debugPrint('ConflictResolver: Error comparing data - $e');
      return false;
    }
  }

  ConflictType _determineConflictType(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // Check for schema differences
    if (_hasSchemaConflict(localData, remoteData)) {
      return ConflictType.schemaConflict;
    }

    // Check for delete conflicts
    if (_hasDeleteConflict(localData, remoteData)) {
      return ConflictType.deleteConflict;
    }

    // Check for version conflicts
    if (_hasVersionConflict(localData, remoteData)) {
      return ConflictType.versionConflict;
    }

    // Default to data conflict
    return ConflictType.dataConflict;
  }

  bool _hasSchemaConflict(Map<String, dynamic> data1, Map<String, dynamic> data2) {
    final keys1 = data1.keys.toSet();
    final keys2 = data2.keys.toSet();
    
    // Check for significant schema differences
    final missingInData1 = keys2.difference(keys1);
    final missingInData2 = keys1.difference(keys2);
    
    return missingInData1.isNotEmpty || missingInData2.isNotEmpty;
  }

  bool _hasDeleteConflict(Map<String, dynamic> data1, Map<String, dynamic> data2) {
    return (data1['isDeleted'] == true && data2['isDeleted'] != true) ||
           (data1['isDeleted'] != true && data2['isDeleted'] == true);
  }

  bool _hasVersionConflict(Map<String, dynamic> data1, Map<String, dynamic> data2) {
    final version1 = data1['version'] as int?;
    final version2 = data2['version'] as int?;
    
    if (version1 != null && version2 != null) {
      return (version1 - version2).abs() > 1;
    }
    
    return false;
  }

  Map<String, dynamic> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final merged = Map<String, dynamic>.from(localData);

    for (final entry in remoteData.entries) {
      if (!merged.containsKey(entry.key)) {
        // Add missing keys from remote
        merged[entry.key] = entry.value;
      } else if (entry.key.endsWith('At') || entry.key.contains('timestamp')) {
        // For timestamp fields, keep the latest
        final localTime = _parseTimestamp(merged[entry.key]);
        final remoteTime = _parseTimestamp(entry.value);
        
        if (remoteTime != null && 
            (localTime == null || remoteTime.isAfter(localTime))) {
          merged[entry.key] = entry.value;
        }
      } else if (entry.value != null && merged[entry.key] == null) {
        // Replace null values with non-null ones
        merged[entry.key] = entry.value;
      }
    }

    // Update merge metadata
    merged['mergedAt'] = FieldValue.serverTimestamp();
    merged['isMerged'] = true;

    return merged;
  }

  bool _canMergeData(Map<String, dynamic> data1, Map<String, dynamic> data2) {
    try {
      // Check if critical fields conflict
      final criticalFields = ['id', 'userId', 'type'];
      
      for (final field in criticalFields) {
        if (data1[field] != null && 
            data2[field] != null && 
            data1[field] != data2[field]) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('ConflictResolver: Error checking merge compatibility - $e');
      return false;
    }
  }

  DateTime? _extractTimestamp(Map<String, dynamic> data) {
    try {
      // Try common timestamp field names
      final timestampFields = ['updatedAt', 'modifiedAt', 'lastModified', 'timestamp'];
      
      for (final field in timestampFields) {
        final value = data[field];
        if (value != null) {
          return _parseTimestamp(value);
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('ConflictResolver: Error extracting timestamp - $e');
      return null;
    }
  }

  DateTime? _parseTimestamp(dynamic value) {
    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> _removeTimestampFields(Map<String, dynamic> data) {
    final filtered = Map<String, dynamic>.from(data);
    final timestampFields = [
      'createdAt', 'updatedAt', 'modifiedAt', 'lastModified', 
      'timestamp', 'syncedAt', 'mergedAt'
    ];
    
    for (final field in timestampFields) {
      filtered.remove(field);
    }
    
    return filtered;
  }

  List<String> _calculateDifferences(
    Map<String, dynamic> data1,
    Map<String, dynamic> data2,
  ) {
    final differences = <String>[];
    final allKeys = {...data1.keys, ...data2.keys};

    for (final key in allKeys) {
      final value1 = data1[key];
      final value2 = data2[key];

      if (value1 != value2) {
        differences.add(key);
      }
    }

    return differences;
  }

  double _assessDataCompleteness(Map<String, dynamic> data) {
    if (data.isEmpty) return 0.0;

    final nonNullValues = data.values.where((value) => value != null).length;
    return nonNullValues / data.length;
  }

  String _determineSeverity(ConflictData conflict) {
    final differences = _calculateDifferences(conflict.localData, conflict.remoteData);
    
    if (differences.length <= 2) return 'low';
    if (differences.length <= 5) return 'medium';
    return 'high';
  }

  String _assessDataLossRisk(ConflictData conflict) {
    final localCompleteness = _assessDataCompleteness(conflict.localData);
    final remoteCompleteness = _assessDataCompleteness(conflict.remoteData);
    
    final completenessGap = (localCompleteness - remoteCompleteness).abs();
    
    if (completenessGap > 0.3) return 'high';
    if (completenessGap > 0.1) return 'medium';
    return 'low';
  }

  Future<void> _updateFirestoreDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection(collection)
        .doc(documentId)
        .update(data);
  }

  Future<void> _markConflictResolved(
    ConflictData conflict,
    ResolutionStrategy strategy,
    String? comment,
  ) async {
    // Implementation depends on your local storage
    // This would update the conflict record in your local database
    debugPrint('ConflictResolver: Marked conflict ${conflict.id} as resolved');
  }

  String _generateConflictId() {
    return 'conflict_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (999 * 1000).round()).toString()}';
  }

  String _generateDuplicateId(String originalId) {
    return '${originalId}_duplicate_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Cleanup and disposal
  void dispose() {
    _conflictsController.close();
  }
}

// Custom exception for conflict resolver errors
class ConflictResolverException implements Exception {
  final String message;
  
  ConflictResolverException(this.message);
  
  @override
  String toString() => 'ConflictResolverException: $message';
}

// Additional utility class for deep collection equality
class DeepCollectionEquality {
  const DeepCollectionEquality();

  bool equals(Object? e1, Object? e2) {
    if (identical(e1, e2)) return true;
    if (e1 == null || e2 == null) return false;
    
    if (e1 is Map && e2 is Map) {
      return _mapEquals(e1, e2);
    } else if (e1 is List && e2 is List) {
      return _listEquals(e1, e2);
    }
    
    return e1 == e2;
  }

  bool _mapEquals(Map m1, Map m2) {
    if (m1.length != m2.length) return false;
    
    for (final key in m1.keys) {
      if (!m2.containsKey(key) || !equals(m1[key], m2[key])) {
        return false;
      }
    }
    
    return true;
  }

  bool _listEquals(List l1, List l2) {
    if (l1.length != l2.length) return false;
    
    for (int i = 0; i < l1.length; i++) {
      if (!equals(l1[i], l2[i])) {
        return false;
      }
    }
    
    return true;
  }
}
          return _resolveDuplicate(conflict);
        
        case ResolutionStrategy.manual:
          return null; // Manual resolution required
      }
    } catch (e) {
      debugPrint('ConflictResolver: Auto-resolution failed - $e');
      return null;
    }
  }

  // Resolve conflict manually with user input
  Future<ConflictResolution> manualResolveConflict(
    ConflictData conflict,
    ResolutionStrategy strategy,
    Map<String, dynamic>? customData,
    String? comment,
  ) async {
    Map<String, dynamic> resolvedData;

    switch (strategy) {
      case ResolutionStrategy.localWins:
        resolvedData = Map<String, dynamic>.from(conflict.localData);
        break;
      
      case ResolutionStrategy.remoteWins:
        resolvedData = Map<String, dynamic>.from(conflict.remoteData);
        break;
      
      case ResolutionStrategy.merge:
        resolvedData = _mergeData(conflict.localData, conflict.remoteData);
        break;
      
      case ResolutionStrategy.duplicate: