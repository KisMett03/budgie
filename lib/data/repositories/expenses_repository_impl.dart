import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart' as app_category;
import '../../domain/repositories/expenses_repository.dart';
import '../../core/errors/app_error.dart';
import '../datasources/local_data_source.dart';
import '../../core/network/connectivity_service.dart';

/// Implementation of ExpensesRepository with offline support
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

  /// Safely get user ID
  String? get _userId {
    final user = _auth.currentUser;
    return user?.uid;
  }

  /// Check authentication status
  void _checkAuthentication() {
    if (_userId == null) {
      throw AuthError.unauthenticated();
    }
  }

  /// Safely get expenses collection reference
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

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) {
        // Offline mode: get expenses from local database
        return _localDataSource.getExpenses();
      }

      // Online mode: get data from Firebase and sync to local
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

      // Update local database
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
        // If network error, try to get data from local storage
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

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;
      final userId = _userId!;

      // Save to local database first
      await _localDataSource.saveExpense(expense);

      if (!isConnected) {
        // Offline mode: save locally only, sync later
        return;
      }

      // Online mode: save to Firebase
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

      // Mark as synced
      await _localDataSource.markExpenseAsSynced(expense.id);
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }

      if (e is NetworkError) {
        // Network error but already saved locally, no additional handling needed
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

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;

      // Update local database first
      await _localDataSource.updateExpense(expense);

      if (!isConnected) {
        // Offline mode: update locally only, sync later
        return;
      }

      // Online mode: update Firebase
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

      // Mark as synced
      await _localDataSource.markExpenseAsSynced(expense.id);
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }

      if (e is NetworkError) {
        // Network error but already updated locally, no additional handling needed
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

      // Check network connectivity
      final isConnected = await _connectivityService.isConnected;

      // Delete from local database first
      await _localDataSource.deleteExpense(id);

      if (!isConnected) {
        // Offline mode: delete locally only, sync later
        return;
      }

      // Online mode: delete from Firebase
      final collection = _getExpensesCollection();
      await collection.doc(id).delete();
    } catch (e, stackTrace) {
      if (e is AuthError) {
        throw e;
      }

      if (e is NetworkError) {
        // Network error but already deleted locally, no additional handling needed
        return;
      }

      throw DataError('Failed to delete expense: ${e.toString()}',
          originalError: e, stackTrace: stackTrace);
    }
  }
}
