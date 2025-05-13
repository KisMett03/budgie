import 'package:flutter/material.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepository;
  Budget? budget;
  bool isLoading = false;

  BudgetViewModel({required BudgetRepository budgetRepository})
      : _budgetRepository = budgetRepository;

  Future<void> loadBudget(String monthId) async {
    isLoading = true;
    notifyListeners();
    budget = await _budgetRepository.getBudget(monthId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> saveBudget(String monthId, Budget newBudget) async {
    await _budgetRepository.setBudget(monthId, newBudget);
    budget = newBudget;
    notifyListeners();
  }
} 