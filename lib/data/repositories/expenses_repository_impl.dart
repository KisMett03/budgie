import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart' as app_category;
import '../../domain/repositories/expenses_repository.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  final FirebaseFirestore _firestore;

  ExpensesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore.collection('users').doc(_userId).collection('expenses');

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      final snapshot =
          await _expensesCollection.orderBy('date', descending: true).get();
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
    } catch (e) {
      throw Exception('Failed to get expenses: $e');
    }
  }

  @override
  Future<void> addExpense(Expense expense) async {
    try {
      await _expensesCollection.add({
        'remark': expense.remark,
        'amount': expense.amount,
        'date': Timestamp.fromDate(expense.date),
        'category': expense.category.id,
        'method': expense.method.toString().split('.').last,
        'description': expense.description,
        'currency': expense.currency,
      });
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      await _expensesCollection.doc(expense.id).update({
        'remark': expense.remark,
        'amount': expense.amount,
        'date': Timestamp.fromDate(expense.date),
        'category': expense.category.id,
        'method': expense.method.toString().split('.').last,
        'description': expense.description,
        'currency': expense.currency,
      });
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await _expensesCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }
}
