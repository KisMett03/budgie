import 'package:flutter/material.dart';

/// 应用常量管理类
class AppConstants {
  /// 货币列表
  static const List<String> currencies = [
    'MYR',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CNY'
  ];

  /// 支付方式列表
  static const List<String> paymentMethods = [
    'Credit Card',
    'Cash',
    'e-Wallet'
  ];

  /// 重复支付选项
  static const List<String> recurringOptions = [
    'One-time',
    'Recurring Payment'
  ];

  /// 日期格式
  static const String dateFormat = 'yyyy MMMM dd';
  static const String timeFormat = 'HH : mm : ss';
  static const String monthYearFormat = 'MMMM yyyy';

  /// 表单验证消息
  static const String requiredFieldMessage = 'This field is required';
  static const String invalidNumberMessage = 'Please enter a valid number';
  static const String positiveNumberMessage =
      'Amount must be greater than zero';

  /// 成功消息
  static const String expenseAddedMessage = 'Expense added successfully';
  static const String budgetSavedMessage = 'Budget saved successfully';

  /// 错误消息
  static const String generalErrorMessage =
      'An error occurred. Please try again.';

  /// 屏幕标题
  static const String newExpenseTitle = 'New Expenses';
  static const String setBudgetTitle = 'Set Budget';
  static const String analyticsTitle = 'Analytics';
  static const String settingsTitle = 'Settings';

  /// 按钮文本
  static const String saveButtonText = 'Save';
  static const String addButtonText = 'Add';
  static const String cancelButtonText = 'Cancel';
  static const String currentTimeButtonText = 'Current Time';

  /// 动作中状态文本
  static const String addingText = 'Adding...';
  static const String savingText = 'Saving...';
  static const String loadingText = 'Loading...';
}
