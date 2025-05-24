import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/budget.dart' as domain;
import '../../domain/entities/expense.dart' as domain;
import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/category.dart';
import '../local/database/app_database.dart';
import 'local_data_source.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class LocalDataSourceImpl implements LocalDataSource {
  final AppDatabase _database;
  final Uuid _uuid = const Uuid();
  final firebase_auth.FirebaseAuth _auth;

  LocalDataSourceImpl(this._database, {firebase_auth.FirebaseAuth? auth})
      : _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  // User 操作
  @override
  Future<domain.User?> getUser(String userId) async {
    final userRow = await (_database.select(_database.users)
          ..where((tbl) => tbl.id.equals(userId)))
        .getSingleOrNull();

    if (userRow == null) {
      return null;
    }

    return domain.User(
      id: userRow.id,
      email: userRow.email,
      displayName: userRow.displayName,
      photoUrl: userRow.photoUrl,
      currency: userRow.currency,
      theme: userRow.theme,
    );
  }

  @override
  Future<void> saveUser(domain.User user) async {
    await _database.into(_database.users).insertOnConflictUpdate(
          UsersCompanion.insert(
            id: user.id,
            email: Value(user.email),
            displayName: Value(user.displayName),
            photoUrl: Value(user.photoUrl),
            currency: Value(user.currency),
            theme: Value(user.theme),
            lastModified: DateTime.now(),
            isSynced: const Value(false),
          ),
        );

    await addToSyncQueue('user', user.id, user.id, 'update');
  }

  // User Settings 操作
  @override
  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    final userRow = await (_database.select(_database.users)
          ..where((tbl) => tbl.id.equals(userId)))
        .getSingleOrNull();

    if (userRow == null) {
      return null;
    }

    return {
      'currency': userRow.currency,
      'theme': userRow.theme,
      'settings': {
        'allowNotification': userRow.allowNotification,
        'autoBudget': userRow.autoBudget,
        'improveAccuracy': userRow.improveAccuracy,
      },
    };
  }

  @override
  Future<void> saveUserSettings(
      String userId, Map<String, dynamic> settings) async {
    final settingsMap = settings['settings'] as Map<String, dynamic>? ?? {};

    await _database.into(_database.users).insertOnConflictUpdate(
          UsersCompanion.insert(
            id: userId,
            currency: Value(settings['currency'] as String? ?? 'MYR'),
            theme: Value(settings['theme'] as String? ?? 'dark'),
            allowNotification:
                Value(settingsMap['allowNotification'] as bool? ?? true),
            autoBudget: Value(settingsMap['autoBudget'] as bool? ?? false),
            improveAccuracy:
                Value(settingsMap['improveAccuracy'] as bool? ?? false),
            lastModified: DateTime.now(),
            isSynced: const Value(false),
          ),
        );

    await addToSyncQueue('user_settings', userId, userId, 'update');
  }

  @override
  Future<void> markUserSettingsAsSynced(String userId) async {
    await (_database.update(_database.users)
          ..where((tbl) => tbl.id.equals(userId)))
        .write(const UsersCompanion(isSynced: Value(true)));
  }

  // Expenses 操作
  @override
  Future<List<domain.Expense>> getExpenses() async {
    final expenses = await (_database.select(_database.expenses)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    return expenses.map((row) {
      final category =
          CategoryExtension.fromId(row.category) ?? Category.others;
      final methodString = row.method;
      final paymentMethod = domain.PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.$methodString',
        orElse: () => domain.PaymentMethod.cash,
      );

      return domain.Expense(
        id: row.id,
        remark: row.remark,
        amount: row.amount,
        date: row.date,
        category: category,
        method: paymentMethod,
        description: row.description,
        currency: row.currency,
      );
    }).toList();
  }

  @override
  Future<void> saveExpense(domain.Expense expense) async {
    final newId = expense.id.isEmpty ? _uuid.v4() : expense.id;
    final userId = await _getCurrentUserId();

    await _database.into(_database.expenses).insertOnConflictUpdate(
          ExpensesCompanion.insert(
            id: newId,
            userId: userId,
            remark: expense.remark,
            amount: expense.amount,
            date: expense.date,
            category: expense.category.id,
            method: expense.method.toString().split('.').last,
            description: Value(expense.description),
            currency: Value(expense.currency),
            isSynced: const Value(false),
            lastModified: DateTime.now(),
          ),
        );

    await addToSyncQueue('expense', newId, userId, 'add');
  }

  @override
  Future<void> updateExpense(domain.Expense expense) async {
    final userId = await _getCurrentUserId();

    await _database.update(_database.expenses).replace(
          ExpensesCompanion(
            id: Value(expense.id),
            userId: Value(userId),
            remark: Value(expense.remark),
            amount: Value(expense.amount),
            date: Value(expense.date),
            category: Value(expense.category.id),
            method: Value(expense.method.toString().split('.').last),
            description: Value(expense.description),
            currency: Value(expense.currency),
            isSynced: const Value(false),
            lastModified: Value(DateTime.now()),
          ),
        );

    await addToSyncQueue('expense', expense.id, userId, 'update');
  }

  @override
  Future<void> deleteExpense(String id) async {
    final userId = await _getCurrentUserId();

    await (_database.delete(_database.expenses)
          ..where((tbl) => tbl.id.equals(id)))
        .go();

    await addToSyncQueue('expense', id, userId, 'delete');
  }

  @override
  Future<List<domain.Expense>> getUnsyncedExpenses() async {
    final expenses = await (_database.select(_database.expenses)
          ..where((tbl) => tbl.isSynced.equals(false)))
        .get();

    return expenses.map((row) {
      final category =
          CategoryExtension.fromId(row.category) ?? Category.others;
      final methodString = row.method;
      final paymentMethod = domain.PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.$methodString',
        orElse: () => domain.PaymentMethod.cash,
      );

      return domain.Expense(
        id: row.id,
        remark: row.remark,
        amount: row.amount,
        date: row.date,
        category: category,
        method: paymentMethod,
        description: row.description,
        currency: row.currency,
      );
    }).toList();
  }

  @override
  Future<void> markExpenseAsSynced(String id) async {
    await (_database.update(_database.expenses)
          ..where((tbl) => tbl.id.equals(id)))
        .write(const ExpensesCompanion(isSynced: Value(true)));
  }

  // Budget 操作
  @override
  Future<domain.Budget?> getBudget(String monthId, String userId) async {
    final budgetRow = await (_database.select(_database.budgets)
          ..where(
              (tbl) => tbl.monthId.equals(monthId) & tbl.userId.equals(userId)))
        .getSingleOrNull();

    if (budgetRow == null) {
      return null;
    }

    final Map<String, dynamic> categoriesMap =
        jsonDecode(budgetRow.categoriesJson);
    final Map<String, domain.CategoryBudget> categories = {};

    categoriesMap.forEach((key, value) {
      categories[key] =
          domain.CategoryBudget.fromMap(Map<String, dynamic>.from(value));
    });

    return domain.Budget(
      total: budgetRow.total,
      left: budgetRow.left,
      categories: categories,
    );
  }

  @override
  Future<void> saveBudget(
      String monthId, domain.Budget budget, String userId) async {
    final categoriesJson = jsonEncode(budget.toMap()['categories']);

    await _database.into(_database.budgets).insertOnConflictUpdate(
          BudgetsCompanion.insert(
            monthId: monthId,
            userId: userId,
            total: budget.total,
            left: budget.left,
            categoriesJson: categoriesJson,
            lastModified: DateTime.now(),
            isSynced: const Value(false),
          ),
        );

    await addToSyncQueue('budget', monthId, userId, 'update');
  }

  @override
  Future<List<String>> getUnsyncedBudgetIds(String userId) async {
    final budgets = await (_database.select(_database.budgets)
          ..where(
              (tbl) => tbl.userId.equals(userId) & tbl.isSynced.equals(false)))
        .get();

    return budgets.map((b) => b.monthId).toList();
  }

  @override
  Future<void> markBudgetAsSynced(String monthId, String userId) async {
    await (_database.update(_database.budgets)
          ..where(
              (tbl) => tbl.monthId.equals(monthId) & tbl.userId.equals(userId)))
        .write(const BudgetsCompanion(isSynced: Value(true)));
  }

  // 同步操作
  @override
  Future<void> addToSyncQueue(String entityType, String entityId, String userId,
      String operation) async {
    await _database.into(_database.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            userId: userId,
            operation: operation,
            timestamp: DateTime.now(),
          ),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final operations = await (_database.select(_database.syncQueue)
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();

    return operations
        .map((op) => {
              'id': op.id,
              'entityType': op.entityType,
              'entityId': op.entityId,
              'userId': op.userId,
              'operation': op.operation,
              'timestamp': op.timestamp,
            })
        .toList();
  }

  @override
  Future<void> clearSyncOperation(int syncId) async {
    await (_database.delete(_database.syncQueue)
          ..where((tbl) => tbl.id.equals(syncId)))
        .go();
  }

  // 辅助方法
  Future<String> _getCurrentUserId() async {
    // 首先尝试从本地数据库获取用户
    final users = await _database.select(_database.users).get();
    if (users.isNotEmpty) {
      return users.first.id;
    }

    // 如果本地数据库没有用户，尝试从Firebase获取
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      // 获取到Firebase用户，将其保存到本地数据库
      final user = domain.User(
        id: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        // 使用默认值
        currency: 'MYR',
        theme: 'light',
      );

      // 保存用户到本地数据库（不需要等待完成）
      saveUser(user);

      return firebaseUser.uid;
    }

    // 如果Firebase也没有用户，则抛出异常
    throw Exception('No user found in local database or Firebase');
  }
}
