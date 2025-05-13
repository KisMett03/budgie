import 'category.dart';

enum PaymentMethod {
  creditCard,
  cash,
  eWallet,
}

class Expense {
  final String id;
  final String remark;
  final double amount;
  final DateTime date;
  final Category category;
  final PaymentMethod method;
  final String? description;
  final String currency;

  Expense({
    required this.id,
    required this.remark,
    required this.amount,
    required this.date,
    required this.category,
    required this.method,
    this.description,
    this.currency = 'MYR',
  });

  Expense copyWith({
    String? id,
    String? remark,
    double? amount,
    DateTime? date,
    Category? category,
    PaymentMethod? method,
    String? description,
    String? currency,
  }) {
    return Expense(
      id: id ?? this.id,
      remark: remark ?? this.remark,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      method: method ?? this.method,
      description: description ?? this.description,
      currency: currency ?? this.currency,
    );
  }
}
