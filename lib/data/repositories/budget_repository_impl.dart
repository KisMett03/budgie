import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../core/errors/app_error.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BudgetRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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
      final doc = await _budgetDoc(monthId).get();
      if (!doc.exists) return null;
      return Budget.fromMap(doc.data()!);
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }
      throw DataError('Failed to get budget: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> setBudget(String monthId, Budget budget) async {
    try {
      _checkAuthentication();
      await _budgetDoc(monthId).set(budget.toMap());
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }
      throw DataError('Failed to set budget: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }
}
