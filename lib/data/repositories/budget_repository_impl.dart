import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../core/errors/app_error.dart';
import '../datasources/local_data_source.dart';
import '../../core/network/connectivity_service.dart';

/// Implementation of BudgetRepository with offline support
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

  /// Gets the current user ID
  String? get _userId {
    final user = _auth.currentUser;
    return user?.uid;
  }

  /// Checks if user is authenticated
  void _checkAuthentication() {
    if (_userId == null) {
      throw AuthError.unauthenticated();
    }
  }

  /// Gets the Firestore document reference for a budget
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

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        // Offline mode: get budget from local database
        return _localDataSource.getBudget(monthId, userId);
      }

      // Online mode: get data from Firebase
      final doc = await _budgetDoc(monthId).get();
      if (!doc.exists) return null;

      final budget = Budget.fromMap(doc.data()!);

      // Update local database
      await _localDataSource.saveBudget(monthId, budget, userId);
      await _localDataSource.markBudgetAsSynced(monthId, userId);

      return budget;
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }

      if (e is NetworkError) {
        // If network error, try to get data from local storage
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

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;

      // Save to local database first
      await _localDataSource.saveBudget(monthId, budget, userId);

      if (!isConnected) {
        // Offline mode: save locally only, sync later
        return;
      }

      // Online mode: save to Firebase
      await _budgetDoc(monthId).set(budget.toMap());

      // Mark as synced
      await _localDataSource.markBudgetAsSynced(monthId, userId);
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }

      if (e is NetworkError) {
        // Network error but already saved locally, no additional handling needed
        return;
      }

      throw DataError('Failed to set budget: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }
}
