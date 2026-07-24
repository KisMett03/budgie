import 'package:flutter/foundation.dart';

import '../../repositories/expenses_repository.dart';
import '../budget/refresh_budget_usecase.dart';
import '../../../data/infrastructure/errors/app_error.dart';

/// Use case for deleting an expense
class DeleteExpenseUseCase {
  final ExpensesRepository _expensesRepository;
  final RefreshBudgetUseCase _refreshBudgetUseCase;

  DeleteExpenseUseCase({
    required ExpensesRepository expensesRepository,
    required RefreshBudgetUseCase refreshBudgetUseCase,
  })  : _expensesRepository = expensesRepository,
        _refreshBudgetUseCase = refreshBudgetUseCase;

  /// Execute the delete expense use case
  Future<void> execute(String expenseId, DateTime expenseDate) async {
    try {
      debugPrint('Deleting expense: $expenseId');

      // Delete expense from repository
      await _expensesRepository.deleteExpense(expenseId);

      // Update budget after expense deletion
      await _updateBudgetAfterExpenseChange(expenseDate);
    } catch (e, stackTrace) {
      final appError = AppError.from(e, stackTrace);
      debugPrint('Error deleting expense: ${appError.message}');
      rethrow;
    }
  }

  /// Update budget after expense change
  Future<void> _updateBudgetAfterExpenseChange(DateTime expenseDate) async {
    try {
      // Get the month from the expense date
      final monthId =
          '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';

      // Refresh budget for the month
      await _refreshBudgetUseCase.execute(monthId);
    } catch (e) {
      debugPrint('Error updating budget after expense deletion: $e');
      // Don't rethrow - this is a secondary operation
    }
  }
}
