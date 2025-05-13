import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/category_manager.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_dropdown_field.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_time_picker_field.dart';
import '../widgets/submit_button.dart';
import '../../core/errors/app_error.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // 使用懒加载和缓存优化
  final ValueNotifier<String> _currency = ValueNotifier<String>('MYR');
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();
  final ValueNotifier<DateTime> _selectedDateTime =
      ValueNotifier<DateTime>(DateTime.now());
  final ValueNotifier<Category> _selectedCategory =
      ValueNotifier<Category>(Category.food);
  final ValueNotifier<String> _paymentMethod =
      ValueNotifier<String>('Credit Card');
  final ValueNotifier<String> _recurring = ValueNotifier<String>('One-time');

  @override
  void dispose() {
    // 释放所有controller和notifier
    _amountController.dispose();
    _remarkController.dispose();
    _currency.dispose();
    _selectedDateTime.dispose();
    _selectedCategory.dispose();
    _paymentMethod.dispose();
    _recurring.dispose();
    super.dispose();
  }

  void _setCurrentDateTime() {
    _selectedDateTime.value = DateTime.now();
  }

  // 优化支付方式转换
  PaymentMethod _getPaymentMethodEnum(String method) {
    switch (method) {
      case 'Credit Card':
        return PaymentMethod.creditCard;
      case 'e-Wallet':
        return PaymentMethod.eWallet;
      case 'Cash':
      default:
        return PaymentMethod.cash;
    }
  }

  // 专门用作VoidCallback的方法
  void _handleSubmit() {
    _submit();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isSubmitting = true;
        });

        final viewModel =
            Provider.of<ExpensesViewModel>(context, listen: false);
        final expense = Expense(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          remark: _remarkController.text,
          amount: double.parse(_amountController.text),
          date: _selectedDateTime.value,
          category: _selectedCategory.value,
          method: _getPaymentMethodEnum(_paymentMethod.value),
          description: _recurring.value,
          currency: _currency.value,
        );

        await viewModel.addExpense(expense);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(AppConstants.expenseAddedMessage),
              backgroundColor: AppTheme.primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e, stackTrace) {
        final error = AppError.from(e, stackTrace);
        error.log();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          AppConstants.newExpenseTitle,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 类别选择器 - 使用ValueListenableBuilder避免整个屏幕重建
                Center(
                  child: ValueListenableBuilder<Category>(
                    valueListenable: _selectedCategory,
                    builder: (context, selectedCategory, _) {
                      return CategorySelector(
                        selectedCategory: selectedCategory,
                        onCategorySelected: (category) {
                          _selectedCategory.value = category;
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 金额输入框和货币选择
                Row(
                  children: [
                    // 货币下拉选择器
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: ValueListenableBuilder<String>(
                        valueListenable: _currency,
                        builder: (context, currency, _) {
                          return CustomDropdownField<String>(
                            value: currency,
                            items: AppConstants.currencies,
                            labelText: 'Currency',
                            onChanged: (value) {
                              if (value != null) {
                                _currency.value = value;
                              }
                            },
                            itemLabelBuilder: (item) => item,
                          );
                        },
                      ),
                    ),
                    // 金额输入框
                    Expanded(
                      child: CustomTextField.number(
                        controller: _amountController,
                        labelText: 'Amount',
                        suffixText: _currency.value,
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 备注输入框
                CustomTextField(
                  controller: _remarkController,
                  labelText: 'Remark',
                  prefixIcon: Icons.note,
                  isRequired: true,
                ),
                const SizedBox(height: 16),

                // 日期时间选择器
                ValueListenableBuilder<DateTime>(
                  valueListenable: _selectedDateTime,
                  builder: (context, selectedDateTime, _) {
                    return DateTimePickerField(
                      dateTime: selectedDateTime,
                      onDateChanged: (date) {
                        _selectedDateTime.value = date;
                      },
                      onTimeChanged: (time) {
                        _selectedDateTime.value = time;
                      },
                      onCurrentTimePressed: _setCurrentDateTime,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 支付方式选择
                ValueListenableBuilder<String>(
                  valueListenable: _paymentMethod,
                  builder: (context, paymentMethod, _) {
                    return CustomDropdownField<String>(
                      value: paymentMethod,
                      items: AppConstants.paymentMethods,
                      labelText: 'Payment Method',
                      onChanged: (value) {
                        if (value != null) {
                          _paymentMethod.value = value;
                        }
                      },
                      itemLabelBuilder: (item) => item,
                      prefixIcon: Icons.payment,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 重复支付选项
                ValueListenableBuilder<String>(
                  valueListenable: _recurring,
                  builder: (context, recurring, _) {
                    return CustomDropdownField<String>(
                      value: recurring,
                      items: AppConstants.recurringOptions,
                      labelText: 'Recurring Payment',
                      onChanged: (value) {
                        if (value != null) {
                          _recurring.value = value;
                        }
                      },
                      itemLabelBuilder: (item) => item,
                      prefixIcon: Icons.repeat,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 提交按钮 - 使用原生按钮解决问题
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppConstants.addingText,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              AppConstants.addButtonText +
                                  " " +
                                  AppConstants.newExpenseTitle,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
