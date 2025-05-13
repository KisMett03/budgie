import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<Budget?> getBudget(String monthId);
  Future<void> setBudget(String monthId, Budget budget);
} 