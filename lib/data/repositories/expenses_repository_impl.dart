import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart' as app_category;
import '../../domain/repositories/expenses_repository.dart';
import '../../core/errors/app_error.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ExpensesRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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
      final collection = _getExpensesCollection();
      final snapshot = await collection.orderBy('date', descending: true).get();

      return snapshot.docs.map((doc) {
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
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }
      throw DataError('Failed to get expenses: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> addExpense(Expense expense) async {
    try {
      _checkAuthentication();
      final collection = _getExpensesCollection();
      await collection.add({
        'remark': expense.remark,
        'amount': expense.amount,
        'date': Timestamp.fromDate(expense.date),
        'category': expense.category.id,
        'method': expense.method.toString().split('.').last,
        'description': expense.description,
        'currency': expense.currency,
      });
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }
      throw DataError('Failed to add expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      _checkAuthentication();
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
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }
      throw DataError('Failed to update expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      _checkAuthentication();
      final collection = _getExpensesCollection();
      await collection.doc(id).delete();
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }
      throw DataError('Failed to delete expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }
}
