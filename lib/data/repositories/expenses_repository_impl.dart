import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart' as app_category;
import '../../domain/repositories/expenses_repository.dart';
import '../../core/errors/app_error.dart';
import '../datasources/local_data_source.dart';
import '../../core/network/connectivity_service.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  ExpensesRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required LocalDataSource localDataSource,
    required ConnectivityService connectivityService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _localDataSource = localDataSource,
        _connectivityService = connectivityService;

  // 安全获取用户ID
  String? get _userId {
    final user = _auth.currentUser;
    return user?.uid;
  }

  // 检查认证状态
  void _checkAuthentication() {
    if (_userId == null) {
      throw AuthError.unauthenticated();
    }
  }

  // 安全获取expenses集合
  CollectionReference<Map<String, dynamic>> _getExpensesCollection() {
    final userId = _userId;
    if (userId == null) {
      throw AuthError.unauthenticated();
    }
    return _firestore.collection('users').doc(userId).collection('expenses');
  }

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      _checkAuthentication();

      // 检查网络连接
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        // 离线模式：从本地数据库获取支出列表
        return _localDataSource.getExpenses();
      }

      // 在线模式：从Firebase获取数据，并同步到本地
      final collection = _getExpensesCollection();
      final snapshot = await collection.orderBy('date', descending: true).get();

      final expenses = snapshot.docs.map((doc) {
        final data = doc.data();
        final categoryString = data['category'] as String?;
        final category = categoryString != null
            ? app_category.CategoryExtension.fromId(categoryString) ??
                app_category.Category.others
            : app_category.Category.others;
        return Expense(
          id: doc.id,
          remark: data['remark'] as String? ?? '',
          amount: (data['amount'] as num).toDouble(),
          date: (data['date'] as Timestamp).toDate(),
          category: category,
          method: PaymentMethod.values.firstWhere(
            (e) => e.toString() == 'PaymentMethod.${data['method']}',
            orElse: () => PaymentMethod.cash,
          ),
          description: data['description'] as String?,
          currency: data['currency'] as String? ?? 'MYR',
        );
      }).toList();

      // 更新本地数据库
      for (final expense in expenses) {
        await _localDataSource.saveExpense(expense);
        await _localDataSource.markExpenseAsSynced(expense.id);
      }

      return expenses;
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }

      if (e is NetworkError) {
        // 如果是网络错误，尝试从本地获取数据
        return _localDataSource.getExpenses();
      }

      throw DataError('Failed to get expenses: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> addExpense(Expense expense) async {
    try {
      _checkAuthentication();

      // 检查网络连接
      final isConnected = await _connectivityService.isConnected;
      final userId = _userId!;

      // 先保存到本地数据库
      await _localDataSource.saveExpense(expense);

      if (!isConnected) {
        // 离线模式：仅保存在本地，等待后续同步
        return;
      }

      // 在线模式：保存到Firebase
      final collection = _getExpensesCollection();
      await collection.doc(expense.id).set({
        'remark': expense.remark,
        'amount': expense.amount,
        'date': Timestamp.fromDate(expense.date),
        'category': expense.category.id,
        'method': expense.method.toString().split('.').last,
        'description': expense.description,
        'currency': expense.currency,
      });

      // 标记为已同步
      await _localDataSource.markExpenseAsSynced(expense.id);
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }

      if (e is NetworkError) {
        // 网络错误时已保存到本地，不需要其他处理
        return;
      }

      throw DataError('Failed to add expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      _checkAuthentication();

      // 检查网络连接
      final isConnected = await _connectivityService.isConnected;

      // 先更新本地数据库
      await _localDataSource.updateExpense(expense);

      if (!isConnected) {
        // 离线模式：仅更新本地，等待后续同步
        return;
      }

      // 在线模式：更新Firebase
      final collection = _getExpensesCollection();
      await collection.doc(expense.id).update({
        'remark': expense.remark,
        'amount': expense.amount,
        'date': Timestamp.fromDate(expense.date),
        'category': expense.category.id,
        'method': expense.method.toString().split('.').last,
        'description': expense.description,
        'currency': expense.currency,
      });

      // 标记为已同步
      await _localDataSource.markExpenseAsSynced(expense.id);
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }

      if (e is NetworkError) {
        // 网络错误时已更新到本地，不需要其他处理
        return;
      }

      throw DataError('Failed to update expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      _checkAuthentication();

      // 检查网络连接
      final isConnected = await _connectivityService.isConnected;

      // 先从本地数据库删除
      await _localDataSource.deleteExpense(id);

      if (!isConnected) {
        // 离线模式：仅从本地删除，等待后续同步
        return;
      }

      // 在线模式：从Firebase删除
      final collection = _getExpensesCollection();
      await collection.doc(id).delete();
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }

      if (e is NetworkError) {
        // 网络错误时已从本地删除，不需要其他处理
        return;
      }

      throw DataError('Failed to delete expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }
}
