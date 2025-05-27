import 'package:flutter/material.dart';
import 'dart:async';
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

  // Track last save time to prevent frequent updates
  DateTime? _lastSaveTime;
  Timer? _saveDebounceTimer;

  // Map to track pending budget saves by monthId
  final Map<String, Budget> _pendingSaves = {};

  BudgetViewModel({required BudgetRepository budgetRepository})
      : _budgetRepository = budgetRepository;

  Future<void> loadBudget(String monthId) async {
    // Set loading state without notifying
    isLoading = true;
    errorMessage = null;

    try {
      PerformanceMonitor.startTimer('load_budget');
      final loadedBudget = await _budgetRepository.getBudget(monthId);
      PerformanceMonitor.stopTimer('load_budget');

      // Only update and notify if there's a change
      if (budget != loadedBudget) {
        budget = loadedBudget;
        // Now notify after loading is complete
        isLoading = false;
        notifyListeners();
      } else {
        // Just update loading state without notifying if budget didn't change
        isLoading = false;
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      errorMessage = error.message;
      // 如果是认证错误，则清空预算数据
      if (error is AuthError) {
        budget = null;
      }
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveBudget(String monthId, Budget newBudget) async {
    // Cancel any pending save for this month
    if (_saveDebounceTimer != null && _saveDebounceTimer!.isActive) {
      _saveDebounceTimer!.cancel();
    }

    // Store this budget in pending saves
    _pendingSaves[monthId] = newBudget;

    // Check if we should throttle this save
    final now = DateTime.now();
    if (_lastSaveTime != null && now.difference(_lastSaveTime!).inSeconds < 2) {
      // Debounce save requests that come too quickly
      debugPrint('Debouncing budget save for month: $monthId');
      _saveDebounceTimer = Timer(const Duration(seconds: 2), () {
        // After debounce period, check if this save is still needed
        if (_pendingSaves.containsKey(monthId)) {
          final budgetToSave = _pendingSaves.remove(monthId);
          if (budgetToSave != null) {
            _executeSaveBudget(monthId, budgetToSave);
          }
        }
      });
      return;
    }

    // Not throttled, execute immediately
    _pendingSaves.remove(monthId);
    await _executeSaveBudget(monthId, newBudget);
  }

  // The actual save operation
  Future<void> _executeSaveBudget(String monthId, Budget newBudget) async {
    try {
      errorMessage = null;
      isLoading = true;
      notifyListeners();

      debugPrint('Executing budget save for month: $monthId');
      _lastSaveTime = DateTime.now();

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

  @override
  void dispose() {
    // Cancel any pending timers
    if (_saveDebounceTimer != null) {
      _saveDebounceTimer!.cancel();
      _saveDebounceTimer = null;
    }
    _pendingSaves.clear();
    super.dispose();
  }
}
