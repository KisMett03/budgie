class CategoryBudget {
  final double budget;
  final double left;

  CategoryBudget({required this.budget, required this.left});

  Map<String, dynamic> toMap() => {
    'budget': budget,
    'left': left,
  };

  factory CategoryBudget.fromMap(Map<String, dynamic> map) => CategoryBudget(
    budget: (map['budget'] as num?)?.toDouble() ?? 0,
    left: (map['left'] as num?)?.toDouble() ?? 0,
  );
}

class Budget {
  final double total;
  final double left;
  final Map<String, CategoryBudget> categories;

  Budget({required this.total, required this.left, required this.categories});

  Map<String, dynamic> toMap() => {
    'total': total,
    'left': left,
    'categories': categories.map((k, v) => MapEntry(k, v.toMap())),
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    total: (map['total'] as num?)?.toDouble() ?? 0,
    left: (map['left'] as num?)?.toDouble() ?? 0,
    categories: (map['categories'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, CategoryBudget.fromMap(v))),
  );
}