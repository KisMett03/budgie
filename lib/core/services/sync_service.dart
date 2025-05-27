import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/datasources/local_data_source.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../network/connectivity_service.dart';
import '../errors/app_error.dart';

/// Service responsible for synchronizing local data with Firebase
class SyncService {
  final LocalDataSource _localDataSource;
  final ExpensesRepository _expensesRepository;
  final BudgetRepository _budgetRepository;
  final ConnectivityService _connectivityService;
  final firebase_auth.FirebaseAuth _auth;
  Timer? _syncTimer;

  // Track when we last synced to prevent too frequent syncs
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 5));

  SyncService({
    required LocalDataSource localDataSource,
    required ExpensesRepository expensesRepository,
    required BudgetRepository budgetRepository,
    required ConnectivityService connectivityService,
    firebase_auth.FirebaseAuth? auth,
  })  : _localDataSource = localDataSource,
        _expensesRepository = expensesRepository,
        _budgetRepository = budgetRepository,
        _connectivityService = connectivityService,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  /// Initialize the sync service
  Future<void> initialize({bool startPeriodicSync = false}) async {
    // Listen for connectivity changes and auto-sync when connection is restored
    _connectivityService.connectionStatusStream.listen((isConnected) {
      if (isConnected) {
        syncData(skipBudgets: true);
      }
    });

    // Only start periodic sync if explicitly requested
    if (startPeriodicSync) {
      _startPeriodicSync();
    }
  }

  /// Start periodic synchronization timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 30), (_) async {
      final isConnected = await _connectivityService.isConnected;
      if (isConnected) {
        syncData(skipBudgets: true);
      }
    });
    debugPrint(
        'Started periodic sync timer (every 30 minutes, skipping budgets)');
  }

  /// Manually trigger data synchronization
  Future<void> syncData({bool skipBudgets = true}) async {
    try {
      // Don't sync more than once every 5 seconds
      final now = DateTime.now();
      if (now.difference(_lastSyncTime).inSeconds < 5) {
        debugPrint('Sync requested too soon after previous sync, skipping...');
        return;
      }

      _lastSyncTime = now;

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return; // User not logged in, skip sync
      }

      final userId = currentUser.uid;
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        return; // No network connection, skip sync
      }

      // Get all pending operations from queue
      final pendingOperations =
          await _localDataSource.getPendingSyncOperations();

      // Process operations in chronological order
      for (final operation in pendingOperations) {
        final entityType = operation['entityType'] as String;
        final entityId = operation['entityId'] as String;
        final opUserId = operation['userId'] as String;
        final operationType = operation['operation'] as String;
        final syncId = operation['id'] as int;

        // Verify operation belongs to current user
        if (opUserId != userId) {
          await _localDataSource.clearSyncOperation(syncId);
          continue;
        }

        // Skip budget operations if requested
        if (skipBudgets && entityType == 'budget') {
          debugPrint(
              'Skipping budget sync operation: $syncId (skipBudgets=true)');
          await _localDataSource.clearSyncOperation(syncId);
          continue;
        }

        try {
          // Handle sync based on entity type and operation type
          switch (entityType) {
            case 'expense':
              await _syncExpense(entityId, operationType);
              break;
            case 'budget':
              if (!skipBudgets) {
                await _syncBudget(entityId, userId, operationType);
              }
              break;
            case 'user_settings':
              await _syncUserSettings(userId, operationType);
              break;
          }

          // Mark operation as completed
          await _localDataSource.clearSyncOperation(syncId);
        } catch (e) {
          // If network error, stop sync process
          if (e is NetworkError) {
            break;
          }
          // For other errors, continue with next operation
          continue;
        }
      }
    } catch (e) {
      // Handle sync process errors
      debugPrint('Sync error: $e');
    }
  }

  /// Sync individual expense record
  Future<void> _syncExpense(String expenseId, String operation) async {
    try {
      switch (operation) {
        case 'add':
        case 'update':
          final expenses = await _localDataSource.getUnsyncedExpenses();

          Expense? expense;
          try {
            expense = expenses.firstWhere((e) => e.id == expenseId);
          } catch (e) {
            debugPrint('Expense with ID $expenseId not found for sync');
            return;
          }

          if (operation == 'add') {
            // For offline expenses, add to Firebase and update local ID
            if (expense.id.startsWith('offline_')) {
              final currentUser = _auth.currentUser;
              if (currentUser == null) {
                throw Exception('User not authenticated');
              }

              // Add to Firebase
              final docRef = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('expenses')
                  .add({
                'remark': expense.remark,
                'amount': expense.amount,
                'date': Timestamp.fromDate(expense.date),
                'category': expense.category.id,
                'method': expense.method.toString().split('.').last,
                'description': expense.description,
                'currency': expense.currency,
              });

              debugPrint('Firebase save successful with ID: ${docRef.id}');

              // Update local record with Firebase ID
              final expenseWithFirebaseId = expense.copyWith(id: docRef.id);

              // Delete old offline record
              await _localDataSource.deleteExpense(expense.id);

              // Save with new Firebase ID as synced
              await _localDataSource.saveSyncedExpense(expenseWithFirebaseId);

              debugPrint(
                  'Synced offline expense ${expense.id} to Firebase with ID: ${docRef.id}');
            } else {
              // Regular add operation
              await _expensesRepository.addExpense(expense);
              await _localDataSource.markExpenseAsSynced(expenseId);
              debugPrint('Synced regular expense: $expenseId');
            }
          } else {
            // Update operation
            await _expensesRepository.updateExpense(expense);
            await _localDataSource.markExpenseAsSynced(expenseId);
          }
          break;

        case 'delete':
          await _expensesRepository.deleteExpense(expenseId);
          break;
      }
    } catch (e) {
      if (e is NetworkError) {
        rethrow;
      }
      // Log other errors but continue processing
      debugPrint('Expense sync error: $e');
    }
  }

  /// Sync individual budget with proper null safety
  Future<void> _syncBudget(
      String monthId, String userId, String operation) async {
    try {
      if (operation == 'update') {
        final localBudget = await _localDataSource.getBudget(monthId, userId);
        if (localBudget != null) {
          // Get the current budget from Firebase to compare
          final firebaseBudget = await _budgetRepository.getBudget(monthId);

          // Only update if the budgets are different
          if (firebaseBudget == null || localBudget != firebaseBudget) {
            debugPrint(
                'Budget for month $monthId needs syncing - updating Firebase');
            await _budgetRepository.setBudget(monthId, localBudget);
            await _localDataSource.markBudgetAsSynced(monthId, userId);
            debugPrint('Budget for month $monthId synced to Firebase');
          } else {
            debugPrint(
                'Budget for month $monthId is already in sync - skipping update');
            // Still mark as synced since it's already up to date
            await _localDataSource.markBudgetAsSynced(monthId, userId);
          }
        } else {
          debugPrint('Budget for month $monthId not found for sync');
        }
      }
    } catch (e) {
      if (e is NetworkError) {
        rethrow;
      }
      debugPrint('Budget sync error: $e');
    }
  }

  /// Sync user settings with proper null safety
  Future<void> _syncUserSettings(String userId, String operation) async {
    try {
      if (operation == 'update') {
        final settings = await _localDataSource.getUserSettings(userId);
        if (settings != null) {
          // Sync to Firebase with proper null checks
          final userData = <String, dynamic>{
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // Only add non-null values
          if (settings['currency'] != null) {
            userData['currency'] = settings['currency'];
          }
          if (settings['theme'] != null) {
            userData['theme'] = settings['theme'];
          }
          if (settings['allowNotification'] != null ||
              settings['autoBudget'] != null ||
              settings['improveAccuracy'] != null) {
            userData['settings'] = {
              if (settings['allowNotification'] != null)
                'allowNotification': settings['allowNotification'],
              if (settings['autoBudget'] != null)
                'autoBudget': settings['autoBudget'],
              if (settings['improveAccuracy'] != null)
                'improveAccuracy': settings['improveAccuracy'],
            };
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set(userData, SetOptions(merge: true));

          await _localDataSource.markUserSettingsAsSynced(userId);
        } else {
          debugPrint('User settings for user $userId not found for sync');
        }
      }
    } catch (e) {
      if (e is NetworkError) {
        rethrow;
      }
      debugPrint('User settings sync error: $e');
    }
  }

  /// Initialize local data when user logs in
  Future<void> initializeLocalDataOnLogin(String userId) async {
    try {
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        return; // Don't initialize when offline
      }

      // Get remote expense data and store locally
      final expenses = await _expensesRepository.getExpenses();
      for (final expense in expenses) {
        await _localDataSource.saveExpense(expense);
        await _localDataSource.markExpenseAsSynced(expense.id);
      }

      // Get current month budget
      final currentMonthId = _getCurrentMonthId();
      final budget = await _budgetRepository.getBudget(currentMonthId);
      if (budget != null) {
        await _localDataSource.saveBudget(currentMonthId, budget, userId,
            isSynced: true);
        await _localDataSource.markBudgetAsSynced(currentMonthId, userId);
      }
    } catch (e) {
      debugPrint('Local data initialization error: $e');
    }
  }

  /// Helper method: Get current month ID (format: YYYY-MM)
  String _getCurrentMonthId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Dispose resources
  void dispose() {
    if (_syncTimer != null) {
      _syncTimer!.cancel();
      _syncTimer = null;
      debugPrint('Sync timer cancelled');
    }
  }

  /// Clear pending budget sync operations for a specific user
  Future<void> clearPendingBudgetSyncs(String userId) async {
    try {
      debugPrint('Clearing pending budget sync operations for user: $userId');

      // Use the direct method in LocalDataSource
      await _localDataSource.clearAllBudgetSyncOperations(userId);

      debugPrint('Finished clearing pending budget sync operations');
    } catch (e) {
      debugPrint('Error clearing pending budget syncs: $e');
    }
  }

  /// Clear sync operations for a specific month's budget
  Future<void> clearBudgetSyncForMonth(String monthId, String userId) async {
    try {
      debugPrint('Clearing sync operations for budget month: $monthId');

      // Get all pending operations from queue
      final pendingOperations =
          await _localDataSource.getPendingSyncOperations();

      // Find and clear budget operations for this specific month
      for (final operation in pendingOperations) {
        final entityType = operation['entityType'] as String;
        final entityId = operation['entityId'] as String;
        final opUserId = operation['userId'] as String;
        final syncId = operation['id'] as int;

        // Only clear budget operations for this month and user
        if (entityType == 'budget' &&
            entityId == monthId &&
            opUserId == userId) {
          await _localDataSource.clearSyncOperation(syncId);
          debugPrint(
              'Cleared budget sync operation for month $monthId: $syncId');
        }
      }

      // Also mark the budget as synced in the database
      await _localDataSource.markBudgetAsSynced(monthId, userId);

      debugPrint(
          'Finished clearing sync operations for budget month: $monthId');
    } catch (e) {
      debugPrint('Error clearing budget sync for month: $e');
    }
  }

  /// Manually clear budget sync operations for a specific month
  Future<void> manualClearBudgetSyncForMonth(String monthId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final userId = currentUser.uid;
    debugPrint('Manually clearing budget sync for month: $monthId');

    try {
      // Get pending operations
      final operations = await _localDataSource.getPendingSyncOperations();

      // Find and clear budget operations for this month
      for (final operation in operations) {
        if (operation['entityType'] == 'budget' &&
            operation['entityId'] == monthId &&
            operation['userId'] == userId) {
          final syncId = operation['id'] as int;
          await _localDataSource.clearSyncOperation(syncId);
          debugPrint(
              'Cleared budget sync operation for month $monthId: $syncId');
        }
      }

      // Mark budget as synced in database
      await _localDataSource.markBudgetAsSynced(monthId, userId);
      debugPrint('Marked budget for month $monthId as synced');
    } catch (e) {
      debugPrint('Error clearing budget sync for month $monthId: $e');
    }
  }
}
