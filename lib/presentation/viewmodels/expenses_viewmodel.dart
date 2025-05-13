import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart' as app_category;
import '../../domain/repositories/expenses_repository.dart';
import 'dart:async';

class ExpensesViewModel extends ChangeNotifier {
  final ExpensesRepository _expensesRepository;
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _expensesSubscription;

  // For date filtering
  DateTime _selectedMonth = DateTime.now();
  bool _isFiltering = false;

  ExpensesViewModel({required ExpensesRepository expensesRepository})
      : _expensesRepository = expensesRepository {
    _startExpensesStream();
  }

  List<Expense> get expenses => _isFiltering ? _filteredExpenses : _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedMonth => _selectedMonth;

  void setSelectedMonth(DateTime month) {
    // Set to the first day of the month to standardize
    final normalizedMonth = DateTime(month.year, month.month, 1);

    if (_selectedMonth.year == normalizedMonth.year &&
        _selectedMonth.month == normalizedMonth.month) {
      return; // No change needed
    }

    _selectedMonth = normalizedMonth;
    _isFiltering = true;
    _filterExpensesByMonth();
    notifyListeners();
  }

  void clearMonthFilter() {
    _isFiltering = false;
    notifyListeners();
  }

  void _filterExpensesByMonth() {
    if (!_isFiltering) return;

    _filteredExpenses = _expenses.where((expense) {
      return expense.date.year == _selectedMonth.year &&
          expense.date.month == _selectedMonth.month;
    }).toList();
  }

  void _startExpensesStream() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _error = "User not logged in";
      _isLoading = false;
      notifyListeners();
      return;
    }

    _expensesSubscription?.cancel(); // Cancel previous subscription if any

    _expensesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('date', descending: true) // Order by date
        .snapshots()
        .listen(
      (snapshot) {
        _expenses = snapshot.docs.map((doc) {
          final data = doc.data();
          // Handle potential null or missing data safely
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          final timestamp = data['date'] as Timestamp?;
          final date = timestamp?.toDate() ?? DateTime.now();
          final categoryString = data['category'] as String?;
          final category = categoryString != null
              ? app_category.CategoryExtension.fromId(categoryString) ??
                  app_category.Category.others
              : app_category.Category.others;
          final methodString = data['method'] as String?;
          final method = PaymentMethod.values.firstWhere(
            (e) => e.toString().split('.').last == methodString,
            orElse: () => PaymentMethod.cash,
          );

          return Expense(
            id: doc.id,
            remark: data['remark'] as String? ?? '',
            amount: amount,
            date: date,
            category: category,
            method: method,
            description: data['description'] as String?,
            currency: data['currency'] as String? ?? 'MYR',
          );
        }).toList();

        // Apply filter if active
        if (_isFiltering) {
          _filterExpensesByMonth();
        }

        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
        print("Error loading expenses: $e"); // Log error
      },
    );
  }

  // Get total expenses for the selected month by category
  Map<app_category.Category, double> getCategoryTotals() {
    final expensesToUse = _isFiltering ? _filteredExpenses : _expenses;
    final Map<app_category.Category, double> result = {};

    for (var expense in expensesToUse) {
      result[expense.category] =
          (result[expense.category] ?? 0) + expense.amount;
    }

    return result;
  }

  // Get total expenses for the selected month
  double getTotalExpenses() {
    final expensesToUse = _isFiltering ? _filteredExpenses : _expenses;
    return expensesToUse.fold(0, (sum, expense) => sum + expense.amount);
  }

  Future<void> addExpense(Expense expense) async {
    try {
      // The repository method already adds to the correct user subcollection
      await _expensesRepository.addExpense(expense);
      // No need to call getExpenses() here because the stream will update _expenses automatically
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      print("Error adding expense: $e"); // Log error
      rethrow; // Rethrow to allow UI to handle
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _expensesRepository.updateExpense(expense);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      print("Error updating expense: $e");
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _expensesRepository.deleteExpense(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      print("Error deleting expense: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel(); // Cancel the stream subscription
    super.dispose();
  }
}
