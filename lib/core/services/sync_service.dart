import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/datasources/local_data_source.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../domain/repositories/budget_repository.dart';
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
        _auth = auth ?? firebase_auth.FirebaseAuth.instance {
    // Listen for connectivity changes and auto-sync when connection is restored
    _connectivityService.connectionStatusStream.listen((isConnected) {
      if (isConnected) {
        syncData();
      }
    });

    // Start periodic sync (every 15 minutes)
    _startPeriodicSync();
  }

  /// Start periodic synchronization timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      final isConnected = await _connectivityService.isConnected;
      if (isConnected) {
        syncData();
      }
    });
  }

  /// Manually trigger data synchronization
  Future<void> syncData() async {
    try {
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

        try {
          // Handle sync based on entity type and operation type
          switch (entityType) {
            case 'expense':
              await _syncExpense(entityId, operationType);
              break;
            case 'budget':
              await _syncBudget(entityId, userId, operationType);
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
          final expense = expenses.firstWhere((e) => e.id == expenseId);

          if (operation == 'add') {
            await _expensesRepository.addExpense(expense);
          } else {
            await _expensesRepository.updateExpense(expense);
          }

          await _localDataSource.markExpenseAsSynced(expenseId);
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

  /// Sync individual budget
  Future<void> _syncBudget(
      String monthId, String userId, String operation) async {
    try {
      if (operation == 'update') {
        final budget = await _localDataSource.getBudget(monthId, userId);
        if (budget != null) {
          await _budgetRepository.setBudget(monthId, budget);
          await _localDataSource.markBudgetAsSynced(monthId, userId);
        }
      }
    } catch (e) {
      if (e is NetworkError) {
        rethrow;
      }
      debugPrint('Budget sync error: $e');
    }
  }

  /// Sync user settings
  Future<void> _syncUserSettings(String userId, String operation) async {
    try {
      if (operation == 'update') {
        final settings = await _localDataSource.getUserSettings(userId);
        if (settings != null) {
          // Sync to Firebase
          await FirebaseFirestore.instance.collection('users').doc(userId).set(
            {
              'currency': settings['currency'],
              'theme': settings['theme'],
              'settings': settings['settings'],
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          await _localDataSource.markUserSettingsAsSynced(userId);
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
        await _localDataSource.saveBudget(currentMonthId, budget, userId);
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
    _syncTimer?.cancel();
  }
}
