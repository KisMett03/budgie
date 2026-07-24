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
      debugPrint('🔍 BudgetRepository: Getting budget for month: $monthId');
      // Get budget from local database
      final localBudget = await _localDataSource.getBudget(monthId);
      debugPrint('🔍 BudgetRepository: Budget found: ${localBudget != null}');
      if (localBudget != null) {
        debugPrint(
            '🔍 BudgetRepository: Budget total: ${localBudget.total}, left: ${localBudget.left}, currency: ${localBudget.currency}');
      }
      return localBudget;
    } catch (e) {
      debugPrint('🔍 BudgetRepository: Error getting budget: $e');
      return null;
    }
  }

  @override
  Future<void> setBudget(String monthId, Budget budget) async {
    try {
      debugPrint('💾 BudgetRepository: Saving budget for month: $monthId');
      debugPrint(
          '💾 BudgetRepository: Budget total: ${budget.total}, left: ${budget.left}, currency: ${budget.currency}');

      // Validate month ID format
      if (!_isValidMonthId(monthId)) {
        debugPrint('💾 BudgetRepository: Invalid month ID format: $monthId');
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
      debugPrint(
          '💾 BudgetRepository: Verified saved budget exists: ${savedBudget != null}');
      if (savedBudget != null) {
        debugPrint(
            '💾 BudgetRepository: Saved budget total: ${savedBudget.total}, left: ${savedBudget.left}, currency: ${savedBudget.currency}');
      } else {
        debugPrint(
            '💾 BudgetRepository: WARNING - Budget verification failed, saved budget is null');
      }
    } catch (e) {
      debugPrint('💾 BudgetRepository: Error setting budget: $e');
      throw Exception('Failed to save budget: $e');
    }
  }

  @override
  Future<void> deleteBudget(String monthId) async {
    try {
      debugPrint('🗑️ BudgetRepository: Deleting budget for month: $monthId');

      // Validate month ID format
      if (!monthId.contains('-') || monthId.split('-').length != 2) {
        debugPrint('🗑️ BudgetRepository: Invalid month ID format: $monthId');
        throw Exception('Invalid month ID format');
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
    } catch (e) {
      debugPrint('🗑️ BudgetRepository: Error deleting budget: $e');
      throw Exception('Failed to delete budget: $e');
    }
  }

  @override
  Future<List<BudgetWithMonth>> getBudgetsWithSavings(
      List<String> monthIds) async {
    try {
      debugPrint(
          '🔍 BudgetRepository: Getting budgets with savings for months: $monthIds');
      return await _localDataSource.getBudgetsForMonths(monthIds);
    } catch (e) {
      debugPrint('🔍 BudgetRepository: Error getting budgets with savings: $e');
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
      debugPrint(
          '🔍 BudgetRepository: Error getting budgets with available savings: $e');
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
      debugPrint(
          '🔍 BudgetRepository: Error getting previous month budgets with savings: $e');
      return [];
    }
  }

  bool _isValidMonthId(String monthId) {
    return RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(monthId);
  }
}
