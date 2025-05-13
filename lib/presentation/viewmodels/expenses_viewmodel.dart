import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart' as app_category;
import '../../domain/entities/budget.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/performance_monitor.dart';
import '../../core/services/budget_calculation_service.dart';
import 'dart:async';
import 'dart:ui';

class ExpensesViewModel extends ChangeNotifier {
  final ExpensesRepository _expensesRepository;
  final BudgetRepository _budgetRepository;
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _expensesSubscription;

  // 缓存机制
  final Map<String, List<Expense>> _cache = {};

  // For date filtering
  DateTime _selectedMonth = DateTime.now();
  bool _isFiltering = false;

  ExpensesViewModel({
    required ExpensesRepository expensesRepository,
    required BudgetRepository budgetRepository,
  })  : _expensesRepository = expensesRepository,
        _budgetRepository = budgetRepository {
    _startExpensesStream();
  }

  List<Expense> get expenses => _isFiltering ? _filteredExpenses : _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedMonth => _selectedMonth;

  void setSelectedMonth(DateTime month) {
    // Set to the first day of the month to standardize
    final normalizedMonth = DateTime(month.year, month.month, 1);

    if (_selectedMonth.year == normalizedMonth.year &&
        _selectedMonth.month == normalizedMonth.month) {
      return; // No change needed
    }

    _selectedMonth = normalizedMonth;
    _isFiltering = true;
    _filterExpensesByMonth();
    notifyListeners();
  }

  void clearMonthFilter() {
    _isFiltering = false;
    notifyListeners();
  }

  void _filterExpensesByMonth() {
    if (!_isFiltering) return;

    PerformanceMonitor.startTimer('filter_expenses');

    final cacheKey = '${_selectedMonth.year}-${_selectedMonth.month}';

    // 使用缓存数据（如果有）
    if (_cache.containsKey(cacheKey)) {
      _filteredExpenses = _cache[cacheKey]!;
      PerformanceMonitor.stopTimer('filter_expenses', logResult: true);
      return;
    }

    // 使用compute函数将过滤操作移至隔离线程
    compute<_FilterParams, List<Expense>>(
            _filterExpenses,
            _FilterParams(
                expenses: _expenses,
                year: _selectedMonth.year,
                month: _selectedMonth.month))
        .then((result) {
      _filteredExpenses = result;
      // 更新缓存
      _cache[cacheKey] = result;
      PerformanceMonitor.stopTimer('filter_expenses');
      notifyListeners();
    });
  }

  // 静态方法，用于隔离线程中执行过滤
  static List<Expense> _filterExpenses(_FilterParams params) {
    return params.expenses.where((expense) {
      return expense.date.year == params.year &&
          expense.date.month == params.month;
    }).toList();
  }

  void _startExpensesStream() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _handleError(AuthError.unauthenticated());
      return;
    }

    _expensesSubscription?.cancel(); // Cancel previous subscription if any

    // 使用数据库层过滤当前月份的数据，添加分页加载
    PerformanceMonitor.startTimer('load_expenses');

    // 如果已经设置了月份过滤，则在数据库层过滤
    Query expensesQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('date', descending: true);

    // 限制加载的最大数据量，优化性能
    final int pageSize = 50;
    expensesQuery = expensesQuery.limit(pageSize);

    _expensesSubscription = expensesQuery.snapshots().listen(
      (snapshot) {
        _processExpensesSnapshot(snapshot, userId, pageSize);
      },
      onError: (e, stackTrace) {
        _handleError(e, stackTrace);
        PerformanceMonitor.stopTimer('load_expenses');
      },
    );
  }

  // 提取数据处理逻辑到独立方法，以便更好管理代码
  void _processExpensesSnapshot(
      QuerySnapshot snapshot, String userId, int pageSize) {
    // 使用compute进行并行处理提升性能
    compute<_ProcessParams, List<Expense>>(
        _processExpensesDocs,
        _ProcessParams(
          docs: snapshot.docs,
        )).then((processedExpenses) {
      _expenses = processedExpenses;

      // 清除过期缓存
      _cache.clear();

      // Apply filter if active
      if (_isFiltering) {
        _filterExpensesByMonth();
      }

      PerformanceMonitor.stopTimer('load_expenses');
      _isLoading = false;
      notifyListeners();
    }).catchError((e, stackTrace) {
      _handleError(e, stackTrace);
      PerformanceMonitor.stopTimer('load_expenses');
    });
  }

  // 静态方法，用于并行处理文档
  static List<Expense> _processExpensesDocs(_ProcessParams params) {
    return params.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Handle potential null or missing data safely
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final timestamp = data['date'] as Timestamp?;
      final date = timestamp?.toDate() ?? DateTime.now();
      final categoryString = data['category'] as String?;
      final category = categoryString != null
          ? app_category.CategoryExtension.fromId(categoryString) ??
              app_category.Category.others
          : app_category.Category.others;
      final methodString = data['method'] as String?;
      final method = PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == methodString,
        orElse: () => PaymentMethod.cash,
      );

      return Expense(
        id: doc.id,
        remark: data['remark'] as String? ?? '',
        amount: amount,
        date: date,
        category: category,
        method: method,
        description: data['description'] as String?,
        currency: data['currency'] as String? ?? 'MYR',
      );
    }).toList();
  }

  // 统一错误处理
  void _handleError(dynamic e, [StackTrace? stackTrace]) {
    final appError = AppError.from(e, stackTrace);
    _error = appError.message;
    _isLoading = false;
    notifyListeners();
    appError.log(); // 使用自定义的日志记录
  }

  // Get total expenses for the selected month by category - 优化使用compute函数
  Map<app_category.Category, double> getCategoryTotals() {
    final expensesToUse = _isFiltering ? _filteredExpenses : _expenses;

    if (expensesToUse.isEmpty) {
      return {};
    }

    return PerformanceMonitor.measure('calculate_category_totals', () {
      final Map<app_category.Category, double> result = {};

      for (var expense in expensesToUse) {
        result[expense.category] =
            (result[expense.category] ?? 0) + expense.amount;
      }

      return result;
    });
  }

  // Get total expenses for the selected month - 优化计算
  double getTotalExpenses() {
    final expensesToUse = _isFiltering ? _filteredExpenses : _expenses;

    if (expensesToUse.isEmpty) {
      return 0.0;
    }

    return PerformanceMonitor.measure('calculate_total_expenses', () {
      return expensesToUse.fold<double>(
          0.0, (sum, expense) => sum + expense.amount);
    });
  }

  // 根据日期获取对应的月份ID
  String _getMonthIdFromDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // 在支出更改后更新预算数据
  Future<void> _updateBudgetAfterExpenseChange(Expense expense) async {
    try {
      // 获取该支出所属月份的ID
      final monthId = _getMonthIdFromDate(expense.date);

      // 获取该月的预算
      final budget = await _budgetRepository.getBudget(monthId);
      if (budget == null) return; // 如果没有预算数据，则不需要更新

      // 获取该月的所有支出
      final monthExpenses =
          getExpensesForMonth(expense.date.year, expense.date.month);

      // 计算新的预算剩余金额
      final updatedBudget =
          await BudgetCalculationService.calculateBudget(budget, monthExpenses);

      // 将更新后的预算保存到数据库
      await _budgetRepository.setBudget(monthId, updatedBudget);

      debugPrint('Budget updated for month $monthId after expense change');
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      debugPrint(
          'Error updating budget after expense change: ${error.message}');
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      // 添加支出到数据库
      await PerformanceMonitor.measureAsync('add_expense', () async {
        return await _expensesRepository.addExpense(expense);
      });

      // 清除缓存以确保数据一致性
      _cache.clear();

      // 更新相关月份的预算
      await _updateBudgetAfterExpenseChange(expense);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      rethrow; // Rethrow to allow UI to handle
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      // 获取原始支出数据（用于处理日期变更的情况）
      final originalExpense = _expenses.firstWhere((e) => e.id == expense.id);
      final originalMonth = _getMonthIdFromDate(originalExpense.date);
      final newMonth = _getMonthIdFromDate(expense.date);
      final monthChanged = originalMonth != newMonth;

      // 更新支出数据
      await PerformanceMonitor.measureAsync('update_expense', () async {
        return await _expensesRepository.updateExpense(expense);
      });

      // 清除缓存以确保数据一致性
      _cache.clear();

      // 如果月份改变，则需要更新两个月份的预算
      if (monthChanged) {
        // 更新原始月份的预算
        final originalMonthExpenses = getExpensesForMonth(
            originalExpense.date.year, originalExpense.date.month);
        final originalBudget = await _budgetRepository.getBudget(originalMonth);
        if (originalBudget != null) {
          final updatedOriginalBudget =
              await BudgetCalculationService.calculateBudget(
                  originalBudget, originalMonthExpenses);
          await _budgetRepository.setBudget(
              originalMonth, updatedOriginalBudget);
        }
      }

      // 更新当前月份的预算
      await _updateBudgetAfterExpenseChange(expense);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      // 获取要删除的支出，以便后续更新相关月份的预算
      final expenseToDelete = _expenses.firstWhere((e) => e.id == id);

      // 删除支出
      await PerformanceMonitor.measureAsync('delete_expense', () async {
        return await _expensesRepository.deleteExpense(id);
      });

      // 清除缓存以确保数据一致性
      _cache.clear();

      // 更新相关月份的预算
      await _updateBudgetAfterExpenseChange(expenseToDelete);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace);
      rethrow;
    }
  }

  // Get expenses for a specific month
  List<Expense> getExpensesForMonth(int year, int month) {
    return PerformanceMonitor.measure('get_expenses_for_month', () {
      return _expenses.where((expense) {
        return expense.date.year == year && expense.date.month == month;
      }).toList();
    });
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel(); // Cancel the stream subscription
    super.dispose();
  }
}

// 过滤参数类，用于compute函数
class _FilterParams {
  final List<Expense> expenses;
  final int year;
  final int month;

  _FilterParams({
    required this.expenses,
    required this.year,
    required this.month,
  });
}

// 处理参数类，用于compute函数
class _ProcessParams {
  final List<QueryDocumentSnapshot> docs;

  _ProcessParams({
    required this.docs,
  });
}
