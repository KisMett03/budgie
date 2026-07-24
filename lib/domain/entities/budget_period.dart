import 'budget.dart';

/// A budget paired with the month it belongs to.
class BudgetWithMonth {
  final String monthId;
  final Budget budget;

  BudgetWithMonth({
    required this.monthId,
    required this.budget,
  });
}
