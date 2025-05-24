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
}

/// Overall budget entity containing total budget and category-wise allocations
class Budget {
  /// Total budget amount
  final double total;

  /// Total remaining budget
  final double left;

  /// Budget allocations by category ID
  final Map<String, CategoryBudget> categories;

  /// Creates a new Budget instance
  Budget({required this.total, required this.left, required this.categories});

  /// Converts the Budget to a Map for serialization
  Map<String, dynamic> toMap() => {
        'total': total,
        'left': left,
        'categories': categories.map((k, v) => MapEntry(k, v.toMap())),
      };

  /// Creates a Budget from a Map
  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        total: (map['total'] as num?)?.toDouble() ?? 0,
        left: (map['left'] as num?)?.toDouble() ?? 0,
        categories: (map['categories'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, CategoryBudget.fromMap(v))),
      );
}
