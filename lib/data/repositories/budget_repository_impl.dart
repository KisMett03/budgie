import 'package:flutter/foundation.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/local_data_source.dart';

/// Implementation of BudgetRepository with local storage focus
class BudgetRepositoryImpl implements BudgetRepository {
  final LocalDataSource _localDataSource;

  BudgetRepositoryImpl({
    required LocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Budget?> getBudget(String monthId) async {
    try {
      debugPrint('BudgetRepository: Getting budget');
      // Get budget from local database
      final localBudget = await _localDataSource.getBudget(monthId);
      debugPrint('budget_repository_impl: Diagnostic output redacted');
      return localBudget;
    } catch (e) {
      debugPrint('BudgetRepository: Error getting budget');
      return null;
    }
  }

  @override
  Future<void> setBudget(String monthId, Budget budget) async {
    try {
      debugPrint('BudgetRepository: Saving budget');

      // Validate month ID format
      if (!_isValidMonthId(monthId)) {
        debugPrint('BudgetRepository: Invalid month ID format');
        throw ArgumentError.value(monthId, 'monthId', 'Expected YYYY-MM');
      }

      // First check if the budget already exists and is identical
      final existingBudget = await _localDataSource.getBudget(monthId);
      if (existingBudget != null && existingBudget == budget) {
        debugPrint('💾 BudgetRepository: Budget unchanged, skipping save');
        return;
      }

      // Save to local database
      await _localDataSource.saveBudget(monthId, budget);
      debugPrint('💾 BudgetRepository: Budget saved successfully');

      // Verify the save worked
      final savedBudget = await _localDataSource.getBudget(monthId);
      debugPrint('budget_repository_impl: Diagnostic output redacted');
      if (savedBudget != null) {
      } else {
        debugPrint(
            '💾 BudgetRepository: WARNING - Budget verification failed, saved budget is null');
      }
    } catch (_) {
      debugPrint('BudgetRepository: Error setting budget');
      rethrow;
    }
  }

  @override
  Future<void> deleteBudget(String monthId) async {
    try {
      debugPrint('BudgetRepository: Deleting budget');

      // Validate month ID format
      if (!monthId.contains('-') || monthId.split('-').length != 2) {
        debugPrint('BudgetRepository: Invalid month ID format');
        throw ArgumentError.value(monthId, 'monthId', 'Expected YYYY-MM');
      }

      // Delete from local database
      await _localDataSource.deleteBudget(monthId);
      debugPrint('🗑️ BudgetRepository: Budget deleted successfully');

      // Verify the deletion worked
      final deletedBudget = await _localDataSource.getBudget(monthId);
      if (deletedBudget == null) {
        debugPrint(
            '🗑️ BudgetRepository: Verified budget was deleted successfully');
      } else {
        debugPrint(
            '🗑️ BudgetRepository: WARNING - Budget deletion verification failed');
      }
    } catch (_) {
      debugPrint('BudgetRepository: Error deleting budget');
      rethrow;
    }
  }

  @override
  Future<List<BudgetWithMonth>> getBudgetsWithSavings(
      List<String> monthIds) async {
    try {
      debugPrint('BudgetRepository: Getting budgets with savings');
      return await _localDataSource.getBudgetsForMonths(monthIds);
    } catch (e) {
      debugPrint('BudgetRepository: Error getting budgets with savings');
      return [];
    }
  }

  @override
  Future<List<BudgetWithMonth>> getBudgetsWithAvailableSavings() async {
    try {
      debugPrint(
          '🔍 BudgetRepository: Getting all budgets with available savings');
      return await _localDataSource.getBudgetsWithSavings();
    } catch (e) {
      debugPrint('budget_repository_impl: Diagnostic output redacted');
      return [];
    }
  }

  @override
  Future<List<BudgetWithMonth>> getPreviousMonthBudgetsWithSavings() async {
    try {
      debugPrint(
          '🔍 BudgetRepository: Getting previous month budgets with available savings for goal funding');
      return await _localDataSource.getPreviousMonthBudgetsWithSavings();
    } catch (e) {
      debugPrint('budget_repository_impl: Diagnostic output redacted');
      return [];
    }
  }

  bool _isValidMonthId(String monthId) {
    return RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(monthId);
  }
}
