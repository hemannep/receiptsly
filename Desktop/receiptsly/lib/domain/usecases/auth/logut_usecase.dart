import 'package:dartz/dartz.dart';
import '../../repositories/i_auth_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../services/local/local_storage_service.dart';
import '../../../services/sync/sync_service.dart';

class LogoutUseCase {
  final IAuthRepository _authRepository;
  final LocalStorageService _localStorageService;
  final SyncService _syncService;

  LogoutUseCase(
    this._authRepository,
    this._localStorageService,
    this._syncService,
  );

  Future<Either<Failure, void>> call() async {
    try {
      // Get current user ID for cleanup
      final currentUser = await _authRepository.getCurrentUser();

      if (currentUser == null) {
        return Left(AuthFailure('No user is currently logged in'));
      }

      // Attempt to sync any pending data before logout
      try {
        await _syncService.forceSyncPendingData();
      } catch (e) {
        // Log the error but don't prevent logout
        print('Warning: Failed to sync pending data during logout: $e');
      }

      // Clear local storage and cache
      await _clearLocalData();

      // Sign out from Firebase Auth
      final signOutResult = await _authRepository.signOut();

      return signOutResult.fold(
        (failure) => Left(failure),
        (_) => const Right(null),
      );
    } catch (e) {
      return Left(AuthFailure('Logout failed: ${e.toString()}'));
    }
  }

  Future<void> _clearLocalData() async {
    try {
      // Clear sensitive data
      await _localStorageService.clearUserSession();

      // Clear cached receipts (keep for offline access if user wants)
      // await _localStorageService.clearReceiptCache();

      // Clear temporary files
      await _localStorageService.clearTempFiles();

      // Clear user preferences (except app settings)
      await _localStorageService.clearUserPreferences();

      // Reset sync status
      await _syncService.resetSyncStatus();
    } catch (e) {
      print('Warning: Failed to clear some local data: $e');
      // Continue with logout even if cleanup fails
    }
  }
}
