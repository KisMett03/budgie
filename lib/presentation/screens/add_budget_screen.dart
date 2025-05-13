import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/category_manager.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_button.dart';
import '../widgets/submit_button.dart';

class AddBudgetScreen extends StatefulWidget {
  final String? monthId;

  const AddBudgetScreen({
    Key? key,
    this.monthId,
  }) : super(key: key);

  @override
  _AddBudgetScreenState createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Use ValueNotifier instead of direct setState calls
  final ValueNotifier<double?> _totalBudgetNotifier =
      ValueNotifier<double?>(null);
  final ValueNotifier<double> _totalAllocatedNotifier =
      ValueNotifier<double>(0);
  final ValueNotifier<double> _savingsNotifier = ValueNotifier<double>(0);

  // Date related properties
  DateTime _selectedDate = DateTime.now();
  String _currentMonthId = '';

  // 使用类别ID作为键的控制器映射
  final Map<String, TextEditingController> _categoryControllers = {};

  // 获取预算使用的类别ID列表
  List<String> get _budgetCategoryIds => CategoryManager.getBudgetCategoryIds();

  @override
  void dispose() {
    for (var c in _categoryControllers.values) {
      c.dispose();
    }
    _totalBudgetNotifier.dispose();
    _totalAllocatedNotifier.dispose();
    _savingsNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentMonthId = widget.monthId ?? _getMonthIdFromDate(_selectedDate);

    // Parse the month ID to get the date if provided
    if (widget.monthId != null) {
      try {
        final parts = widget.monthId!.split('-');
        if (parts.length == 2) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          _selectedDate = DateTime(year, month);
        }
      } catch (e) {
        // If parsing fails, use current date
        _selectedDate = DateTime.now();
      }
    }

    _setupListeners();
    if (widget.monthId != null) {
      _loadBudgetData(_currentMonthId);
    }
  }

  String _getMonthIdFromDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void _setupListeners() {
    // Listen for total budget changes, calculate savings
    _totalBudgetNotifier.addListener(_calculateSavings);
    _totalAllocatedNotifier.addListener(_calculateSavings);

    // Create controllers for each category
    for (final catId in _budgetCategoryIds) {
      _categoryControllers[catId] = TextEditingController();
      _categoryControllers[catId]?.addListener(_calculateTotalAllocated);
    }
  }

  void _calculateSavings() {
    final totalBudget = _totalBudgetNotifier.value ?? 0;
    final totalAllocated = _totalAllocatedNotifier.value;
    final savings = totalBudget - totalAllocated;

    _savingsNotifier.value = savings > 0 ? savings : 0;
  }

  void _loadBudgetData(String monthId) async {
    final vm = Provider.of<BudgetViewModel>(context, listen: false);
    await vm.loadBudget(monthId);

    if (!mounted) return;

    final budget = vm.budget;
    if (budget != null) {
      _totalBudgetNotifier.value = budget.total;

      for (final catId in _budgetCategoryIds) {
        _categoryControllers[catId]?.text =
            budget.categories[catId]?.budget.toString() ?? '';
      }
    } else {
      _totalBudgetNotifier.value = null;
      for (final catId in _budgetCategoryIds) {
        _categoryControllers[catId]?.text = '';
      }
    }

    // Calculate allocated budget
    _calculateTotalAllocated();
  }

  void _calculateTotalAllocated() {
    double total = 0;
    for (final catId in _budgetCategoryIds) {
      final val = double.tryParse(_categoryControllers[catId]?.text ?? '') ?? 0;
      total += val;
    }
    _totalAllocatedNotifier.value = total;
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _currentMonthId = _getMonthIdFromDate(newDate);
    });
    _loadBudgetData(_currentMonthId);
  }

  void _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSubmitting = true;
      });

      final total = _totalBudgetNotifier.value ?? 0;
      final Map<String, CategoryBudget> cats = {};

      for (final catId in _budgetCategoryIds) {
        final val =
            double.tryParse(_categoryControllers[catId]?.text ?? '') ?? 0;
        cats[catId] = CategoryBudget(budget: val, left: val);
      }

      final newBudget = Budget(total: total, left: total, categories: cats);

      if (!mounted) return;
      await Provider.of<BudgetViewModel>(context, listen: false)
          .saveBudget(_currentMonthId, newBudget);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.budgetSavedMessage),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          AppConstants.setBudgetTitle,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 日期选择按钮
            DatePickerButton(
              date: _selectedDate,
              onDateChanged: _onDateChanged,
              themeColor: AppTheme.primaryColor,
            ),

            // 总预算卡片
            CustomCard.withTitle(
              title: 'Total Budget',
              icon: Icons.account_balance_wallet,
              iconColor: AppTheme.primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<double?>(
                    valueListenable: _totalBudgetNotifier,
                    builder: (context, totalBudget, _) {
                      return CustomTextField.currency(
                        initialValue: totalBudget?.toString(),
                        labelText: 'Total Budget',
                        currencySymbol: 'MYR',
                        onChanged: (v) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _totalBudgetNotifier.value = double.tryParse(v);
                          });
                        },
                        isRequired: true,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 预算分配进度
                  ValueListenableBuilder<double?>(
                    valueListenable: _totalBudgetNotifier,
                    builder: (context, totalBudget, _) {
                      return ValueListenableBuilder<double>(
                        valueListenable: _totalAllocatedNotifier,
                        builder: (context, totalAllocated, _) {
                          final total = totalBudget ?? 0;
                          final percentage = total > 0
                              ? (totalAllocated / total * 100).clamp(0, 100)
                              : 0.0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Allocated: MYR ${totalAllocated.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: total > 0 ? totalAllocated / total : 0,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentage > 100
                                      ? AppTheme.errorColor
                                      : AppTheme.primaryColor,
                                ),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 储蓄卡片
            ValueListenableBuilder<double>(
              valueListenable: _savingsNotifier,
              builder: (context, savings, _) {
                return CustomCard.withTitle(
                  title: 'Savings',
                  icon: Icons.savings,
                  iconColor: AppTheme.primaryColor,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          'MYR ${savings.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: savings > 0
                                ? AppTheme.successColor
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          savings > 0
                              ? 'Available for savings'
                              : 'No savings available',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            color: savings > 0
                                ? AppTheme.successColor
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 类别预算卡片
            CustomCard.withTitle(
              title: 'Category Budgets',
              icon: Icons.category,
              iconColor: AppTheme.primaryColor,
              child: Column(
                children: _budgetCategoryIds.map((catId) {
                  // 获取类别对象（如果可用）
                  final category = CategoryManager.getCategoryFromId(catId);
                  final categoryIcon = category != null
                      ? CategoryManager.getIcon(category)
                      : CategoryManager.getIconFromId(catId);
                  final categoryColor = category != null
                      ? CategoryManager.getColor(category)
                      : CategoryManager.getColorFromId(catId);
                  final categoryName = category != null
                      ? CategoryManager.getName(category)
                      : CategoryManager.getNameFromId(catId);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            categoryIcon,
                            color: categoryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField.currency(
                            controller: _categoryControllers[catId],
                            labelText: categoryName,
                            currencySymbol: 'MYR',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SubmitButton(
          text: AppConstants.saveButtonText + ' ' + AppConstants.setBudgetTitle,
          loadingText: AppConstants.savingText,
          isLoading: _isSubmitting,
          onPressed: _saveBudget,
          icon: Icons.save,
        ),
      ),
    );
  }
}
