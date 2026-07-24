import 'package:flutter/foundation.dart';
import '../../entities/budget.dart';
import '../../entities/expense.dart';
import '../../repositories/budget_repository.dart';
import '../../repositories/expenses_repository.dart';
import '../../services/budget_calculation_service.dart';
import '../../../data/infrastructure/errors/app_error.dart';
import 'load_budget_usecase.dart';

/// Use case for refreshing budget data and recalculating budget amounts
class RefreshBudgetUseCase {
  final BudgetRepository _budgetRepository;
  final ExpensesRepository _expensesRepository;
  final BudgetCalculationService _budgetCalculationService;
  final LoadBudgetUseCase _loadBudgetUseCase;

  RefreshBudgetUseCase({
    required BudgetRepository budgetRepository,
    required ExpensesRepository expensesRepository,
    required BudgetCalculationService budgetCalculationService,
    required LoadBudgetUseCase loadBudgetUseCase,
  })  : _budgetRepository = budgetRepository,
        _expensesRepository = expensesRepository,
        _budgetCalculationService = budgetCalculationService,
        _loadBudgetUseCase = loadBudgetUseCase;

  /// Execute the refresh budget use case
  Future<Budget?> execute(String monthId) async {
    try {
      debugPrint(
          '🔄 RefreshBudgetUseCase: Refreshing budget for month $monthId');

      // Recalculate budget based on local data
      final updatedBudget = await _recalculateBudget(monthId);

      return updatedBudget;
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      debugPrint(
          '❌ RefreshBudgetUseCase: Error refreshing budget: ${error.message}');
      error.log();
      rethrow;
    }
  }

  /// Recalculate budget based on current expenses
  Future<Budget?> _recalculateBudget(String monthId) async {
    try {
      // Get current budget
      final currentBudget = await _budgetRepository.getBudget(monthId);
      if (currentBudget == null) {
        debugPrint(
            '⚠️ RefreshBudgetUseCase: No budget found for month $monthId');
        return null;
      }

      // Get all expenses
      final allExpenses = await _expensesRepository.getExpenses();

      // Filter expenses for this month
      final year = int.parse(monthId.split('-')[0]);
      final month = int.parse(monthId.split('-')[1]);
      final monthExpenses = _getExpensesForMonth(allExpenses, year, month);

      debugPrint(
          '🧮 RefreshBudgetUseCase: Recalculating budget with ${monthExpenses.length} expenses');

      // Calculate new budget remaining amounts
      final updatedBudget = await _budgetCalculationService.calculateBudget(
          currentBudget, monthExpenses);

      // Only save if budget actually changed
      if (currentBudget != updatedBudget) {
        debugPrint('💾 RefreshBudgetUseCase: Budget changed, saving updates');
        await _budgetRepository.setBudget(monthId, updatedBudget);
      } else {
        debugPrint('ℹ️ RefreshBudgetUseCase: Budget unchanged, no save needed');
      }

      return updatedBudget;
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      debugPrint(
          '❌ RefreshBudgetUseCase: Error recalculating budget: ${error.message}');
      error.log();
      return await _loadBudgetUseCase
          .execute(monthId); // Fallback to loading existing budget
    }
  }

  /// Get expenses for a specific month
  List<Expense> _getExpensesForMonth(
      List<Expense> expenses, int year, int month) {
    return expenses.where((expense) {
      return expense.date.year == year && expense.date.month == month;
    }).toList();
  }
}
