import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final FirebaseFirestore _firestore;

  BudgetRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> _budgetDoc(String monthId) =>
      _firestore.collection('users').doc(_userId).collection('budgets').doc(monthId);

  @override
  Future<Budget?> getBudget(String monthId) async {
    final doc = await _budgetDoc(monthId).get();
    if (!doc.exists) return null;
    return Budget.fromMap(doc.data()!);
  }

  @override
  Future<void> setBudget(String monthId, Budget budget) async {
    await _budgetDoc(monthId).set(budget.toMap());
  }
} 