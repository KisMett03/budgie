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

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Form fields
  String _currency = 'MYR';
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();
  Category _selectedCategory = Category.food;

  String _paymentMethod = 'Credit Card';
  String _recurring = 'One-time';

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _setCurrentDateTime() {
    setState(() {
      _selectedDateTime = DateTime.now();
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isSubmitting = true;
        });

        // 准备支付方式
        PaymentMethod method;
        switch (_paymentMethod) {
          case 'Credit Card':
            method = PaymentMethod.creditCard;
            break;
          case 'e-Wallet':
            method = PaymentMethod.eWallet;
            break;
          case 'Cash':
          default:
            method = PaymentMethod.cash;
        }

        final viewModel =
            Provider.of<ExpensesViewModel>(context, listen: false);
        final expense = Expense(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          remark: _remarkController.text,
          amount: double.parse(_amountController.text),
          date: _selectedDateTime,
          category: _selectedCategory,
          method: method,
          description: _recurring,
          currency: _currency,
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
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
                // 类别选择器
                Center(
                  child: CategorySelector(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    // 可以选择性地过滤类别
                    // categories: [Category.food, Category.entertainment, Category.others],
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
                      child: CustomDropdownField<String>(
                        value: _currency,
                        items: AppConstants.currencies,
                        labelText: 'Currency',
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _currency = value;
                            });
                          }
                        },
                        itemLabelBuilder: (item) => item,
                      ),
                    ),
                    // 金额输入框
                    Expanded(
                      child: CustomTextField.number(
                        controller: _amountController,
                        labelText: 'Amount',
                        suffixText: _currency,
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
                DateTimePickerField(
                  dateTime: _selectedDateTime,
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDateTime = date;
                    });
                  },
                  onTimeChanged: (time) {
                    setState(() {
                      _selectedDateTime = time;
                    });
                  },
                  onCurrentTimePressed: _setCurrentDateTime,
                ),
                const SizedBox(height: 16),

                // 支付方式选择
                CustomDropdownField<String>(
                  value: _paymentMethod,
                  items: AppConstants.paymentMethods,
                  labelText: 'Payment Method',
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _paymentMethod = value;
                      });
                    }
                  },
                  itemLabelBuilder: (item) => item,
                  prefixIcon: Icons.payment,
                ),
                const SizedBox(height: 16),

                // 重复支付选项
                CustomDropdownField<String>(
                  value: _recurring,
                  items: AppConstants.recurringOptions,
                  labelText: 'Recurring Payment',
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _recurring = value;
                      });
                    }
                  },
                  itemLabelBuilder: (item) => item,
                  prefixIcon: Icons.repeat,
                ),
                const SizedBox(height: 24),

                // 提交按钮
                SubmitButton(
                  text: AppConstants.addButtonText +
                      ' ' +
                      AppConstants.newExpenseTitle,
                  loadingText: AppConstants.addingText,
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                  icon: Icons.add,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
