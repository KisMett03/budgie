import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../core/errors/app_error.dart';
import '../datasources/local_data_source.dart';
import '../../core/network/connectivity_service.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  BudgetRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required LocalDataSource localDataSource,
    required ConnectivityService connectivityService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _localDataSource = localDataSource,
        _connectivityService = connectivityService;

  String? get _userId {
    final user = _auth.currentUser;
    return user?.uid;
  }

  void _checkAuthentication() {
    if (_userId == null) {
      throw AuthError.unauthenticated();
    }
  }

  DocumentReference<Map<String, dynamic>> _budgetDoc(String monthId) {
    final userId = _userId;
    if (userId == null) {
      throw AuthError.unauthenticated();
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(monthId);
  }

  @override
  Future<Budget?> getBudget(String monthId) async {
    try {
      _checkAuthentication();
      final userId = _userId!;

      // 检查网络连接
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        // 离线模式：从本地数据库获取预算
        return _localDataSource.getBudget(monthId, userId);
      }

      // 在线模式：从Firebase获取数据
      final doc = await _budgetDoc(monthId).get();
      if (!doc.exists) return null;

      final budget = Budget.fromMap(doc.data()!);

      // 更新本地数据库
      await _localDataSource.saveBudget(monthId, budget, userId);
      await _localDataSource.markBudgetAsSynced(monthId, userId);

      return budget;
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }

      if (e is NetworkError) {
        // 如果是网络错误，尝试从本地获取数据
        final userId = _userId!;
        return _localDataSource.getBudget(monthId, userId);
      }

      throw DataError('Failed to get budget: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setBudget(String monthId, Budget budget) async {
    try {
      _checkAuthentication();
      final userId = _userId!;

      // 检查网络连接
      final isConnected = await _connectivityService.isConnected;

      // 先保存到本地数据库
      await _localDataSource.saveBudget(monthId, budget, userId);

      if (!isConnected) {
        // 离线模式：仅保存在本地，等待后续同步
        return;
      }

      // 在线模式：保存到Firebase
      await _budgetDoc(monthId).set(budget.toMap());

      // 标记为已同步
      await _localDataSource.markBudgetAsSynced(monthId, userId);
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }

      if (e is NetworkError) {
        // 网络错误时已保存到本地，不需要其他处理
        return;
      }

      throw DataError('Failed to set budget: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }
}
