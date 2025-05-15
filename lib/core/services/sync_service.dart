import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../data/datasources/local_data_source.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/budget.dart';
import '../network/connectivity_service.dart';
import '../../core/errors/app_error.dart';

class SyncService {
  final LocalDataSource _localDataSource;
  final ExpensesRepository _expensesRepository;
  final BudgetRepository _budgetRepository;
  final ConnectivityService _connectivityService;
  final firebase_auth.FirebaseAuth _auth;
  Timer? _syncTimer;

  SyncService({
    required LocalDataSource localDataSource,
    required ExpensesRepository expensesRepository,
    required BudgetRepository budgetRepository,
    required ConnectivityService connectivityService,
    firebase_auth.FirebaseAuth? auth,
  })  : _localDataSource = localDataSource,
        _expensesRepository = expensesRepository,
        _budgetRepository = budgetRepository,
        _connectivityService = connectivityService,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance {
    // 监听连接状态变化，当连接恢复时自动同步
    _connectivityService.connectionStatusStream.listen((isConnected) {
      if (isConnected) {
        syncData();
      }
    });

    // 定期尝试同步（每15分钟）
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      final isConnected = await _connectivityService.isConnected;
      if (isConnected) {
        syncData();
      }
    });
  }

  // 手动触发同步
  Future<void> syncData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return; // 用户未登录，不执行同步
      }

      final userId = currentUser.uid;
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        return; // 无网络连接，不执行同步
      }

      // 获取队列中的所有操作
      final pendingOperations =
          await _localDataSource.getPendingSyncOperations();

      // 按照操作时间顺序处理
      for (final operation in pendingOperations) {
        final entityType = operation['entityType'] as String;
        final entityId = operation['entityId'] as String;
        final opUserId = operation['userId'] as String;
        final operationType = operation['operation'] as String;
        final syncId = operation['id'] as int;

        // 验证操作是否属于当前用户
        if (opUserId != userId) {
          await _localDataSource.clearSyncOperation(syncId);
          continue;
        }

        try {
          // 根据实体类型和操作类型处理同步
          if (entityType == 'expense') {
            await _syncExpense(entityId, operationType);
          } else if (entityType == 'budget') {
            await _syncBudget(entityId, userId, operationType);
          }

          // 标记此操作已完成
          await _localDataSource.clearSyncOperation(syncId);
        } catch (e) {
          // 如果是网络错误，终止同步过程
          if (e is NetworkError) {
            break;
          }
          // 其他错误继续处理下一个操作
          continue;
        }
      }
    } catch (e) {
      // 处理同步过程中的错误
      print('同步出错: $e');
    }
  }

  // 同步单个支出记录
  Future<void> _syncExpense(String expenseId, String operation) async {
    try {
      switch (operation) {
        case 'add':
        case 'update':
          final expenses = await _localDataSource.getUnsyncedExpenses();
          final expense = expenses.firstWhere((e) => e.id == expenseId);

          if (operation == 'add') {
            await _expensesRepository.addExpense(expense);
          } else {
            await _expensesRepository.updateExpense(expense);
          }

          await _localDataSource.markExpenseAsSynced(expenseId);
          break;

        case 'delete':
          await _expensesRepository.deleteExpense(expenseId);
          break;
      }
    } catch (e) {
      if (e is NetworkError) {
        rethrow;
      }
      // 其他错误，记录但继续处理
      print('同步支出记录错误: $e');
    }
  }

  // 同步单个预算
  Future<void> _syncBudget(
      String monthId, String userId, String operation) async {
    try {
      if (operation == 'update') {
        final budget = await _localDataSource.getBudget(monthId, userId);
        if (budget != null) {
          await _budgetRepository.setBudget(monthId, budget);
          await _localDataSource.markBudgetAsSynced(monthId, userId);
        }
      }
    } catch (e) {
      if (e is NetworkError) {
        rethrow;
      }
      print('同步预算错误: $e');
    }
  }

  // 当用户登录时初始化本地数据
  Future<void> initializeLocalDataOnLogin(String userId) async {
    try {
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        return; // 无网络连接时不初始化
      }

      // 获取远程支出数据并存入本地
      final expenses = await _expensesRepository.getExpenses();
      for (final expense in expenses) {
        await _localDataSource.saveExpense(expense);
        await _localDataSource.markExpenseAsSynced(expense.id);
      }

      // 获取当前月份预算
      final currentMonthId = _getCurrentMonthId();
      final budget = await _budgetRepository.getBudget(currentMonthId);
      if (budget != null) {
        await _localDataSource.saveBudget(currentMonthId, budget, userId);
        await _localDataSource.markBudgetAsSynced(currentMonthId, userId);
      }
    } catch (e) {
      print('初始化本地数据错误: $e');
    }
  }

  // 辅助方法：获取当前月份ID（格式：YYYY-MM）
  String _getCurrentMonthId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
