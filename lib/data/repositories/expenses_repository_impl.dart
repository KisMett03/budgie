import '../../domain/entities/expense.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../datasources/local_data_source.dart';
import 'package:flutter/foundation.dart';

/// Implementation of ExpensesRepository with local storage
class ExpensesRepositoryImpl implements ExpensesRepository {
  final LocalDataSource _localDataSource;

  ExpensesRepositoryImpl({
    required LocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      // Get expenses from local database
      final localExpenses = await _localDataSource.getExpenses();
      return localExpenses;
    } catch (_) {
      debugPrint('ExpensesRepository: Error getting expenses');
      return [];
    }
  }

  @override
  Future<void> addExpense(Expense expense) async {
    try {
      // Save to local database
      await _localDataSource.saveExpense(expense);
    } catch (_) {
      debugPrint('ExpensesRepository: Error adding expense');
      rethrow;
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      // Update in local database
      await _localDataSource.updateExpense(expense);
    } catch (_) {
      debugPrint('ExpensesRepository: Error updating expense');
      rethrow;
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      // Delete from local database
      await _localDataSource.deleteExpense(id);
    } catch (_) {
      debugPrint('ExpensesRepository: Error deleting expense');
      rethrow;
    }
  }
}
