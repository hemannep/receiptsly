// lib/data/repositories/client_repository.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:receiptsly/data/models/client/client_model.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/i_client_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/models/client/client_model.dart';
import '../../domain/datasources/local/client_local_datasource.dart';
import '../../domain/datasources/remote/firebase/client_remote_datasource.dart';
import '../../services/sync/sync_service.dart';

class ClientRepository implements IClientRepository {
  final ClientLocalDatasource _localDatasource;
  final ClientRemoteDatasource _remoteDatasource;
  final SyncService _syncService;
  final Connectivity _connectivity;

  ClientRepository({
    required ClientLocalDatasource localDatasource,
    required ClientRemoteDatasource remoteDatasource,
    required SyncService syncService,
    required Connectivity connectivity,
  }) : _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource,
       _syncService = syncService,
       _connectivity = connectivity;

  @override
  Future<Either<Failure, ClientEntity>> createClient({
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? company,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? taxId,
    String? notes,
    Map<String, String>? customFields,
  }) async {
    try {
      final clientId = _generateClientId();

      // Validate email uniqueness
      final existingClient = await _localDatasource.getClientByEmail(
        userId,
        email,
      );
      if (existingClient != null) {
        return Left(
          ValidationFailure('A client with this email already exists'),
        );
      }

      // Create client model
      final clientModel = ClientModel(
        id: clientId,
        userId: userId,
        name: name,
        email: email,
        phone: phone ?? '',
        company: company ?? '',
        address: address ?? '',
        city: city ?? '',
        state: state ?? '',
        zipCode: zipCode ?? '',
        country: country ?? '',
        taxId: taxId ?? '',
        notes: notes ?? '',
        customFields: customFields ?? {},
        isActive: true,
        totalInvoices: 0,
        totalAmount: 0.0,
        lastInvoiceDate: null,
        syncStatus: SyncStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save locally first
      await _localDatasource.insertClient(clientModel);

      // Check connectivity and sync if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          await _remoteDatasource.createClient(clientModel);

          // Mark as synced
          final syncedModel = clientModel.copyWith(
            syncStatus: SyncStatus.synced,
          );
          await _localDatasource.updateClient(syncedModel);

          return Right(syncedModel.toEntity());
        } catch (e) {
          // Add to sync queue if remote save fails
          await _syncService.addToSyncQueue(
            action: 'CREATE',
            collection: 'clients',
            data: clientModel.toJson(),
          );
        }
      } else {
        // Add to sync queue for offline creation
        await _syncService.addToSyncQueue(
          action: 'CREATE',
          collection: 'clients',
          data: clientModel.toJson(),
        );
      }

      return Right(clientModel.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('Failed to create client: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ClientEntity>> updateClient(
    String clientId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final currentClient = await _localDatasource.getClientById(clientId);
      if (currentClient == null) {
        return Left(DatabaseFailure('Client not found'));
      }

      // Validate email uniqueness if email is being updated
      if (updates['email'] != null && updates['email'] != currentClient.email) {
        final existingClient = await _localDatasource.getClientByEmail(
          currentClient.userId,
          updates['email'],
        );
        if (existingClient != null && existingClient.id != clientId) {
          return Left(
            ValidationFailure('A client with this email already exists'),
          );
        }
      }

      // Apply updates
      final updatedModel = currentClient.copyWith(
        name: updates['name'] ?? currentClient.name,
        email: updates['email'] ?? currentClient.email,
        phone: updates['phone'] ?? currentClient.phone,
        company: updates['company'] ?? currentClient.company,
        address: updates['address'] ?? currentClient.address,
        city: updates['city'] ?? currentClient.city,
        state: updates['state'] ?? currentClient.state,
        zipCode: updates['zipCode'] ?? currentClient.zipCode,
        country: updates['country'] ?? currentClient.country,
        taxId: updates['taxId'] ?? currentClient.taxId,
        notes: updates['notes'] ?? currentClient.notes,
        customFields: updates['customFields'] ?? currentClient.customFields,
        isActive: updates['isActive'] ?? currentClient.isActive,
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );

      // Update locally
      await _localDatasource.updateClient(updatedModel);

      // Check connectivity and sync if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          await _remoteDatasource.updateClient(updatedModel);

          // Mark as synced
          final syncedModel = updatedModel.copyWith(
            syncStatus: SyncStatus.synced,
          );
          await _localDatasource.updateClient(syncedModel);

          return Right(syncedModel.toEntity());
        } catch (e) {
          // Add to sync queue if remote update fails
          await _syncService.addToSyncQueue(
            action: 'UPDATE',
            collection: 'clients',
            documentId: clientId,
            data: updatedModel.toJson(),
          );
        }
      } else {
        // Add to sync queue for offline updates
        await _syncService.addToSyncQueue(
          action: 'UPDATE',
          collection: 'clients',
          documentId: clientId,
          data: updatedModel.toJson(),
        );
      }

      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('Failed to update client: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteClient(String clientId) async {
    try {
      final client = await _localDatasource.getClientById(clientId);
      if (client == null) {
        return Left(DatabaseFailure('Client not found'));
      }

      // Check if client has any invoices
      final hasInvoices = await _localDatasource.hasClientInvoices(clientId);
      if (hasInvoices) {
        return Left(
          BusinessLogicFailure('Cannot delete client with existing invoices'),
        );
      }

      // Delete from local database
      await _localDatasource.deleteClient(clientId);

      // Check connectivity and delete from remote if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          await _remoteDatasource.deleteClient(clientId);
        } catch (e) {
          // Add to sync queue if remote delete fails
          await _syncService.addToSyncQueue(
            action: 'DELETE',
            collection: 'clients',
            documentId: clientId,
            data: {'id': clientId},
          );
        }
      } else {
        // Add to sync queue for offline deletes
        await _syncService.addToSyncQueue(
          action: 'DELETE',
          collection: 'clients',
          documentId: clientId,
          data: {'id': clientId},
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete client: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateClient(String clientId) async {
    try {
      final client = await _localDatasource.getClientById(clientId);
      if (client == null) {
        return Left(DatabaseFailure('Client not found'));
      }

      final deactivatedClient = client.copyWith(
        isActive: false,
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );

      await _localDatasource.updateClient(deactivatedClient);

      // Add to sync queue
      await _syncService.addToSyncQueue(
        action: 'UPDATE',
        collection: 'clients',
        documentId: clientId,
        data: deactivatedClient.toJson(),
      );

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to deactivate client: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, ClientEntity?>> getClientById(String clientId) async {
    try {
      // Try local first
      final localClient = await _localDatasource.getClientById(clientId);
      if (localClient != null) {
        return Right(localClient.toEntity());
      }

      // Try remote if connected
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        final remoteClient = await _remoteDatasource.getClientById(clientId);
        if (remoteClient != null) {
          // Cache locally
          await _localDatasource.insertClient(remoteClient);
          return Right(remoteClient.toEntity());
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get client: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ClientEntity?>> getClientByEmail({
    required String userId,
    required String email,
  }) async {
    try {
      final client = await _localDatasource.getClientByEmail(userId, email);
      return Right(client?.toEntity());
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get client by email: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<ClientEntity>>> getClients({
    required String userId,
    int? limit,
    String? startAfter,
    bool? isActive,
    String? searchQuery,
  }) async {
    try {
      // Get from local database
      final localClients = await _localDatasource.getClients(
        userId: userId,
        limit: limit,
        startAfter: startAfter,
        isActive: isActive,
        searchQuery: searchQuery,
      );

      // Convert to entities
      final localEntities = localClients
          .map((model) => model.toEntity())
          .toList();

      // Try to fetch updates from remote if connected
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          final remoteClients = await _remoteDatasource.getClients(
            userId: userId,
            limit: limit,
            startAfter: startAfter,
            isActive: isActive,
            searchQuery: searchQuery,
          );

          // Merge remote data with local
          final mergedClients = await _mergeClientData(
            localClients,
            remoteClients,
          );
          final mergedEntities = mergedClients
              .map((model) => model.toEntity())
              .toList();

          return Right(mergedEntities);
        } catch (e) {
          // Return local data if remote fetch fails
          return Right(localEntities);
        }
      }

      return Right(localEntities);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get clients: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ClientEntity>>> searchClients({
    required String userId,
    required String query,
    bool? isActive,
  }) async {
    try {
      final clients = await _localDatasource.searchClients(
        userId: userId,
        query: query,
        isActive: isActive,
      );

      final entities = clients.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(DatabaseFailure('Failed to search clients: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getClientStatistics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final statistics = await _localDatasource.getClientStatistics(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      return Right(statistics);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get client statistics: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<ClientEntity>>> getTopClients({
    required String userId,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final topClients = await _localDatasource.getTopClients(
        userId: userId,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );

      final entities = topClients.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get top clients: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getClientInvoiceHistory(
    String clientId,
  ) async {
    try {
      final history = await _localDatasource.getClientInvoiceHistory(clientId);
      return Right(history);
    } catch (e) {
      return Left(
        DatabaseFailure(
          'Failed to get client invoice history: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updateClientInvoiceStats({
    required String clientId,
    required double invoiceAmount,
    required DateTime invoiceDate,
    bool isNewInvoice = true,
  }) async {
    try {
      final client = await _localDatasource.getClientById(clientId);
      if (client == null) {
        return Left(DatabaseFailure('Client not found'));
      }

      final updatedClient = client.copyWith(
        totalInvoices: isNewInvoice
            ? client.totalInvoices + 1
            : client.totalInvoices,
        totalAmount: client.totalAmount + invoiceAmount,
        lastInvoiceDate:
            invoiceDate.isAfter(client.lastInvoiceDate ?? DateTime(1900))
            ? invoiceDate
            : client.lastInvoiceDate,
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );

      await _localDatasource.updateClient(updatedClient);

      // Add to sync queue
      await _syncService.addToSyncQueue(
        action: 'UPDATE',
        collection: 'clients',
        documentId: clientId,
        data: updatedClient.toJson(),
      );

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to update client stats: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> bulkImportClients({
    required String userId,
    required List<Map<String, dynamic>> clientsData,
    Function(int, int)? onProgress,
  }) async {
    try {
      final results = <String, String>{};

      for (int i = 0; i < clientsData.length; i++) {
        try {
          final data = clientsData[i];

          // Validate required fields
          if (data['name'] == null || data['email'] == null) {
            results['row_${i + 1}'] = 'Missing required fields (name, email)';
            continue;
          }

          // Check for duplicate email
          final existingClient = await _localDatasource.getClientByEmail(
            userId,
            data['email'],
          );
          if (existingClient != null) {
            results['row_${i + 1}'] = 'Email already exists';
            continue;
          }

          // Create client
          final result = await createClient(
            userId: userId,
            name: data['name'],
            email: data['email'],
            phone: data['phone'],
            company: data['company'],
            address: data['address'],
            city: data['city'],
            state: data['state'],
            zipCode: data['zipCode'],
            country: data['country'],
            taxId: data['taxId'],
            notes: data['notes'],
          );

          result.fold(
            (failure) => results['row_${i + 1}'] = failure.message,
            (client) => results['row_${i + 1}'] = 'Success',
          );
        } catch (e) {
          results['row_${i + 1}'] = 'Error: ${e.toString()}';
        }

        // Report progress
        onProgress?.call(i + 1, clientsData.length);
      }

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to bulk import clients: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> syncClients(String userId) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return Left(NetworkFailure('No internet connection'));
      }

      // Get unsynced clients
      final unsyncedClients = await _localDatasource.getUnsyncedClients(userId);

      for (final client in unsyncedClients) {
        try {
          if (client.syncStatus == SyncStatus.pending) {
            await _remoteDatasource.createClient(client);

            // Update local as synced
            final syncedClient = client.copyWith(
              syncStatus: SyncStatus.synced,
              updatedAt: DateTime.now(),
            );
            await _localDatasource.updateClient(syncedClient);
          }
        } catch (e) {
          // Log error but continue with other clients
          print('Failed to sync client ${client.id}: $e');
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to sync clients: ${e.toString()}'));
    }
  }

  @override
  Stream<List<ClientEntity>> watchClients({
    required String userId,
    bool? isActive,
  }) {
    return _localDatasource
        .watchClients(userId: userId, isActive: isActive)
        .map((clients) => clients.map((model) => model.toEntity()).toList());
  }

  @override
  Future<Either<Failure, List<ClientEntity>>> getRecentClients({
    required String userId,
    int limit = 5,
  }) async {
    try {
      final recentClients = await _localDatasource.getRecentClients(
        userId: userId,
        limit: limit,
      );

      final entities = recentClients.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get recent clients: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> mergeClients({
    required String primaryClientId,
    required String secondaryClientId,
  }) async {
    try {
      final primaryClient = await _localDatasource.getClientById(
        primaryClientId,
      );
      final secondaryClient = await _localDatasource.getClientById(
        secondaryClientId,
      );

      if (primaryClient == null || secondaryClient == null) {
        return Left(DatabaseFailure('One or both clients not found'));
      }

      // Merge client data (keep primary client's data, but combine totals)
      final mergedClient = primaryClient.copyWith(
        totalInvoices:
            primaryClient.totalInvoices + secondaryClient.totalInvoices,
        totalAmount: primaryClient.totalAmount + secondaryClient.totalAmount,
        lastInvoiceDate: _getLatestDate(
          primaryClient.lastInvoiceDate,
          secondaryClient.lastInvoiceDate,
        ),
        notes: _combineNotes(primaryClient.notes, secondaryClient.notes),
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );

      // Update invoices to point to primary client
      await _localDatasource.updateInvoicesClientId(
        secondaryClientId,
        primaryClientId,
      );

      // Update primary client
      await _localDatasource.updateClient(mergedClient);

      // Delete secondary client
      await _localDatasource.deleteClient(secondaryClientId);

      // Add to sync queues
      await _syncService.addToSyncQueue(
        action: 'UPDATE',
        collection: 'clients',
        documentId: primaryClientId,
        data: mergedClient.toJson(),
      );

      await _syncService.addToSyncQueue(
        action: 'DELETE',
        collection: 'clients',
        documentId: secondaryClientId,
        data: {'id': secondaryClientId},
      );

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to merge clients: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> exportClients({
    required String userId,
    bool? isActive,
    List<String>? fields,
  }) async {
    try {
      final clients = await _localDatasource.getClients(
        userId: userId,
        isActive: isActive,
      );

      final exportData = clients.map((client) {
        final data = <String, dynamic>{
          'id': client.id,
          'name': client.name,
          'email': client.email,
          'phone': client.phone,
          'company': client.company,
          'address': client.address,
          'city': client.city,
          'state': client.state,
          'zipCode': client.zipCode,
          'country': client.country,
          'taxId': client.taxId,
          'notes': client.notes,
          'totalInvoices': client.totalInvoices,
          'totalAmount': client.totalAmount,
          'lastInvoiceDate': client.lastInvoiceDate?.toIso8601String(),
          'isActive': client.isActive,
          'createdAt': client.createdAt.toIso8601String(),
          'updatedAt': client.updatedAt.toIso8601String(),
        };

        // Add custom fields
        client.customFields.forEach((key, value) {
          data['custom_$key'] = value;
        });

        // Filter fields if specified
        if (fields != null) {
          return Map.fromEntries(
            data.entries.where((entry) => fields.contains(entry.key)),
          );
        }

        return data;
      }).toList();

      return Right(exportData);
    } catch (e) {
      return Left(DatabaseFailure('Failed to export clients: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addCustomField({
    required String clientId,
    required String fieldName,
    required String fieldValue,
  }) async {
    try {
      final client = await _localDatasource.getClientById(clientId);
      if (client == null) {
        return Left(DatabaseFailure('Client not found'));
      }

      final updatedCustomFields = Map<String, String>.from(client.customFields);
      updatedCustomFields[fieldName] = fieldValue;

      final updatedClient = client.copyWith(
        customFields: updatedCustomFields,
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );

      await _localDatasource.updateClient(updatedClient);

      // Add to sync queue
      await _syncService.addToSyncQueue(
        action: 'UPDATE',
        collection: 'clients',
        documentId: clientId,
        data: updatedClient.toJson(),
      );

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to add custom field: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> removeCustomField({
    required String clientId,
    required String fieldName,
  }) async {
    try {
      final client = await _localDatasource.getClientById(clientId);
      if (client == null) {
        return Left(DatabaseFailure('Client not found'));
      }

      final updatedCustomFields = Map<String, String>.from(client.customFields);
      updatedCustomFields.remove(fieldName);

      final updatedClient = client.copyWith(
        customFields: updatedCustomFields,
        syncStatus: SyncStatus.pending,
        updatedAt: DateTime.now(),
      );

      await _localDatasource.updateClient(updatedClient);

      // Add to sync queue
      await _syncService.addToSyncQueue(
        action: 'UPDATE',
        collection: 'clients',
        documentId: clientId,
        data: updatedClient.toJson(),
      );

      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to remove custom field: ${e.toString()}'),
      );
    }
  }

  // Private helper methods
  String _generateClientId() {
    return 'client_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      length,
      (index) => chars[random % chars.length],
    ).join();
  }

  Future<List<ClientModel>> _mergeClientData(
    List<ClientModel> localClients,
    List<ClientModel> remoteClients,
  ) async {
    final Map<String, ClientModel> merged = {};

    // Add local clients
    for (final client in localClients) {
      merged[client.id] = client;
    }

    // Merge remote clients
    for (final remoteClient in remoteClients) {
      final localClient = merged[remoteClient.id];

      if (localClient == null) {
        // New remote client - cache it locally
        merged[remoteClient.id] = remoteClient;
        await _localDatasource.insertClient(remoteClient);
      } else {
        // Check which is newer
        if (remoteClient.updatedAt.isAfter(localClient.updatedAt)) {
          // Remote is newer - update local
          merged[remoteClient.id] = remoteClient;
          await _localDatasource.updateClient(remoteClient);
        } else if (localClient.updatedAt.isAfter(remoteClient.updatedAt) &&
            localClient.syncStatus == SyncStatus.pending) {
          // Local is newer and unsynced - add to sync queue
          await _syncService.addToSyncQueue(
            action: 'UPDATE',
            collection: 'clients',
            documentId: localClient.id,
            data: localClient.toJson(),
          );
        }
      }
    }

    return merged.values.toList();
  }

  DateTime? _getLatestDate(DateTime? date1, DateTime? date2) {
    if (date1 == null && date2 == null) return null;
    if (date1 == null) return date2;
    if (date2 == null) return date1;
    return date1.isAfter(date2) ? date1 : date2;
  }

  String _combineNotes(String notes1, String notes2) {
    if (notes1.isEmpty && notes2.isEmpty) return '';
    if (notes1.isEmpty) return notes2;
    if (notes2.isEmpty) return notes1;
    return '$notes1\n\n--- Merged Notes ---\n$notes2';
  }
}
