import '../../domain/entities/budget.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/user.dart';

abstract class LocalDataSource {
  // User 操作
  Future<User?> getUser(String userId);
  Future<void> saveUser(User user);

  // Expenses 操作
  Future<List<Expense>> getExpenses();
  Future<void> saveExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<List<Expense>> getUnsyncedExpenses();
  Future<void> markExpenseAsSynced(String id);

  // Budget 操作
  Future<Budget?> getBudget(String monthId, String userId);
  Future<void> saveBudget(String monthId, Budget budget, String userId);
  Future<List<String>> getUnsyncedBudgetIds(String userId);
  Future<void> markBudgetAsSynced(String monthId, String userId);

  // 同步操作
  Future<void> addToSyncQueue(
      String entityType, String entityId, String userId, String operation);
  Future<List<Map<String, dynamic>>> getPendingSyncOperations();
  Future<void> clearSyncOperation(int syncId);
}
