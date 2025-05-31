import 'package:flutter/foundation.dart';

/// Budget allocation for a specific category
class CategoryBudget {
  /// Total budget allocated for this category
  final double budget;

  /// Remaining budget for this category
  final double left;

  /// Creates a new CategoryBudget instance
  CategoryBudget({required this.budget, required this.left});

  /// Converts the CategoryBudget to a Map for serialization
  Map<String, dynamic> toMap() => {
        'budget': budget,
        'left': left,
      };

  /// Creates a CategoryBudget from a Map
  factory CategoryBudget.fromMap(Map<String, dynamic> map) => CategoryBudget(
        budget: (map['budget'] as num?)?.toDouble() ?? 0,
        left: (map['left'] as num?)?.toDouble() ?? 0,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CategoryBudget) return false;

    // Use a small epsilon for double comparison to handle floating point precision issues
    const epsilon = 0.001;
    return (other.budget - budget).abs() < epsilon &&
        (other.left - left).abs() < epsilon;
  }

  @override
  int get hashCode => budget.hashCode ^ left.hashCode;
}

/// Overall budget entity containing total budget and category-wise allocations
class Budget {
  /// Total budget amount
  final double total;

  /// Total remaining budget
  final double left;

  /// Budget allocations by category ID
  final Map<String, CategoryBudget> categories;

  /// Currency code (default: MYR)
  final String currency;

  /// Creates a new Budget instance
  Budget({
    required this.total,
    required this.left,
    required this.categories,
    this.currency = 'MYR',
  });

  /// Converts the Budget to a Map for serialization
  Map<String, dynamic> toMap() => {
        'total': total,
        'left': left,
        'categories': categories.map((k, v) => MapEntry(k, v.toMap())),
        'currency': currency,
      };

  /// Creates a Budget from a Map
  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        total: (map['total'] as num?)?.toDouble() ?? 0,
        left: (map['left'] as num?)?.toDouble() ?? 0,
        categories: (map['categories'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, CategoryBudget.fromMap(v))),
        currency: map['currency'] as String? ?? 'MYR',
      );

  /// Creates a copy of this Budget with the given fields replaced with new values
  Budget copyWith({
    double? total,
    double? left,
    Map<String, CategoryBudget>? categories,
    String? currency,
  }) {
    return Budget(
      total: total ?? this.total,
      left: left ?? this.left,
      categories: categories ?? this.categories,
      currency: currency ?? this.currency,
    );
  }

  /// Creates a new Budget with all amounts converted to a different currency
  Budget convertCurrency(
      String newCurrency, Map<String, double> conversionRates) {
    debugPrint(
        '💱 [Budget] Starting currency conversion: $currency → $newCurrency');
    debugPrint('💱 [Budget] Original total: $total $currency');

    // If currency is the same, return the same budget
    if (newCurrency == currency) {
      debugPrint('💱 [Budget] Currencies are the same, no conversion needed');
      return this;
    }

    // Get conversion rate from current currency to new currency
    final conversionRate = conversionRates[newCurrency] ?? 1.0;
    debugPrint(
        '💱 [Budget] Using conversion rate: $conversionRate ($currency to $newCurrency)');

    // Convert total and left amounts with 2 decimal precision
    final newTotal = double.parse((total * conversionRate).toStringAsFixed(2));
    final newLeft = double.parse((left * conversionRate).toStringAsFixed(2));

    debugPrint(
        '💱 [Budget] Converted total: $total $currency → $newTotal $newCurrency');
    debugPrint(
        '💱 [Budget] Converted left: $left $currency → $newLeft $newCurrency');

    // Convert each category budget
    final newCategories = <String, CategoryBudget>{};
    for (final entry in categories.entries) {
      final categoryId = entry.key;
      final categoryBudget = entry.value;

      // Convert category budget and left amounts with 2 decimal precision
      final newCategoryBudget = double.parse(
          (categoryBudget.budget * conversionRate).toStringAsFixed(2));
      final newCategoryLeft = double.parse(
          (categoryBudget.left * conversionRate).toStringAsFixed(2));

      debugPrint(
          '💱 [Budget] Category "$categoryId": Budget ${categoryBudget.budget} → $newCategoryBudget, Left ${categoryBudget.left} → $newCategoryLeft');

      newCategories[categoryId] = CategoryBudget(
        budget: newCategoryBudget,
        left: newCategoryLeft,
      );
    }

    // Create new budget with converted amounts
    final convertedBudget = Budget(
      total: newTotal,
      left: newLeft,
      categories: newCategories,
      currency: newCurrency,
    );

    debugPrint(
        '💱 [Budget] Currency conversion completed: $currency → $newCurrency');
    return convertedBudget;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Budget) return false;

    // Use a small epsilon for double comparison
    const epsilon = 0.001;
    if ((other.total - total).abs() >= epsilon ||
        (other.left - left).abs() >= epsilon ||
        other.currency != currency) {
      return false;
    }

    // Check if categories are the same
    if (other.categories.length != categories.length) {
      return false;
    }

    // Compare each category budget
    for (final entry in categories.entries) {
      final key = entry.key;
      final value = entry.value;

      if (!other.categories.containsKey(key)) {
        return false;
      }

      if (other.categories[key] != value) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode =>
      total.hashCode ^ left.hashCode ^ categories.hashCode ^ currency.hashCode;
}
