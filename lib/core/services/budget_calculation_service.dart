import 'package:flutter/foundation.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/expense.dart';

/// 预算计算服务类
class BudgetCalculationService {
  /// 计算总预算剩余金额和各类别剩余预算
  ///
  /// [budget] 原始预算数据
  /// [expenses] 支出列表（必须已经按月份过滤）
  /// 返回更新后的预算对象
  static Future<Budget> calculateBudget(
      Budget budget, List<Expense> expenses) async {
    // 使用compute函数在后台线程计算以避免UI卡顿
    return compute(
        _calculateBudgetInternal,
        _CalculationParams(
          budget: budget,
          expenses: expenses,
        ));
  }

  /// 内部计算函数，在后台线程中运行
  static Budget _calculateBudgetInternal(_CalculationParams params) {
    final Budget budget = params.budget;
    final List<Expense> expenses = params.expenses;

    // 创建类别支出映射表
    final Map<String, double> categoryExpenses = {};

    // 计算每个类别的总支出
    // 注意：此处假设传入的expenses已经按月份过滤
    for (final expense in expenses) {
      final categoryId = expense.category.id;
      categoryExpenses[categoryId] =
          (categoryExpenses[categoryId] ?? 0) + expense.amount;
    }

    // 计算总支出
    final double totalExpenses =
        categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);

    // 计算总剩余预算
    final double totalLeft = budget.total - totalExpenses;

    // 创建新的类别预算映射表
    final Map<String, CategoryBudget> newCategories = {};

    // 更新每个类别的剩余预算
    for (final entry in budget.categories.entries) {
      final String categoryId = entry.key;
      final CategoryBudget categoryBudget = entry.value;

      // 获取该类别的支出
      final double categoryExpense = categoryExpenses[categoryId] ?? 0;

      // 计算类别剩余预算
      final double categoryLeft = categoryBudget.budget - categoryExpense;

      // 创建新的类别预算对象
      newCategories[categoryId] = CategoryBudget(
        budget: categoryBudget.budget,
        left: categoryLeft,
      );
    }

    // 创建并返回新的预算对象
    return Budget(
      total: budget.total,
      left: totalLeft,
      categories: newCategories,
    );
  }
}

/// 计算参数类，用于compute函数
class _CalculationParams {
  final Budget budget;
  final List<Expense> expenses;

  _CalculationParams({
    required this.budget,
    required this.expenses,
  });
}
