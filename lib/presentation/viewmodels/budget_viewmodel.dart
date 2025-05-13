import 'package:flutter/material.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/performance_monitor.dart';
import '../../core/services/budget_calculation_service.dart';

class BudgetViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepository;
  Budget? budget;
  bool isLoading = false;
  String? errorMessage;

  BudgetViewModel({required BudgetRepository budgetRepository})
      : _budgetRepository = budgetRepository;

  Future<void> loadBudget(String monthId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      PerformanceMonitor.startTimer('load_budget');
      budget = await _budgetRepository.getBudget(monthId);
      PerformanceMonitor.stopTimer('load_budget');
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
      // 如果是认证错误，则清空预算数据
      if (error is AuthError) {
        budget = null;
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveBudget(String monthId, Budget newBudget) async {
    try {
      errorMessage = null;
      isLoading = true;
      notifyListeners();

      await PerformanceMonitor.measureAsync('save_budget', () async {
        return await _budgetRepository.setBudget(monthId, newBudget);
      });

      budget = newBudget;
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 计算预算剩余金额（总额和各类别）
  ///
  /// [expenses] 当月支出列表
  Future<void> calculateBudgetRemaining(List<Expense> expenses) async {
    if (budget == null) return;

    try {
      errorMessage = null;
      isLoading = true;
      notifyListeners();

      // 使用预算计算服务计算剩余预算
      final updatedBudget =
          await PerformanceMonitor.measureAsync('calculate_budget', () async {
        return await BudgetCalculationService.calculateBudget(
            budget!, expenses);
      });

      // 更新预算数据
      budget = updatedBudget;
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
