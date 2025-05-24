import 'package:flutter/foundation.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/expense.dart';

/// Budget calculation service class
class BudgetCalculationService {
  /// Calculate total budget remaining amount and category remaining budgets
  ///
  /// [budget] Original budget data
  /// [expenses] Expense list (must be filtered by month)
  /// Returns updated budget object
  static Future<Budget> calculateBudget(
      Budget budget, List<Expense> expenses) async {
    // Use compute function to calculate in background thread to avoid UI blocking
    return compute(
        _calculateBudgetInternal,
        _CalculationParams(
          budget: budget,
          expenses: expenses,
        ));
  }

  /// Internal calculation function, runs in background thread
  static Budget _calculateBudgetInternal(_CalculationParams params) {
    final Budget budget = params.budget;
    final List<Expense> expenses = params.expenses;

    // Create category expense mapping
    final Map<String, double> categoryExpenses = {};

    // Calculate total expenses for each category
    // Note: assumes expenses are already filtered by month
    for (final expense in expenses) {
      final categoryId = expense.category.id;
      categoryExpenses[categoryId] =
          (categoryExpenses[categoryId] ?? 0) + expense.amount;
    }

    // Calculate total expenses
    final double totalExpenses =
        categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);

    // Calculate total remaining budget
    final double totalLeft = budget.total - totalExpenses;

    // Create new category budget mapping
    final Map<String, CategoryBudget> newCategories = {};

    // Update remaining budget for each category
    for (final entry in budget.categories.entries) {
      final String categoryId = entry.key;
      final CategoryBudget categoryBudget = entry.value;

      // Get expenses for this category
      final double categoryExpense = categoryExpenses[categoryId] ?? 0;

      // Calculate category remaining budget
      final double categoryLeft = categoryBudget.budget - categoryExpense;

      // Create new category budget object
      newCategories[categoryId] = CategoryBudget(
        budget: categoryBudget.budget,
        left: categoryLeft,
      );
    }

    // Create and return new budget object
    return Budget(
      total: budget.total,
      left: totalLeft,
      categories: newCategories,
    );
  }
}

/// Calculation parameters class for compute function
class _CalculationParams {
  final Budget budget;
  final List<Expense> expenses;

  _CalculationParams({
    required this.budget,
    required this.expenses,
  });
}
