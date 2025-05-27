import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/budget.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/category_manager.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_button.dart';
import '../widgets/submit_button.dart';
import '../../core/services/budget_calculation_service.dart';

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
    // Dispose all controllers
    for (var c in _categoryControllers.values) {
      c.dispose();
    }
    _categoryControllers.clear();

    // Dispose all notifiers
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

    // Use post-frame callback to load budget data after the build is complete
    if (widget.monthId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadBudgetData(_currentMonthId);
        }
      });
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
      if (!_categoryControllers.containsKey(catId)) {
        final controller = TextEditingController();
        _categoryControllers[catId] = controller;

        // Use a debounced listener to avoid excessive calculations
        controller.addListener(() {
          // Debounce rapid text changes
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _calculateTotalAllocated();
            }
          });
        });
      }
    }
  }

  void _calculateSavings() {
    final totalBudget = _totalBudgetNotifier.value ?? 0;
    final totalAllocated = _totalAllocatedNotifier.value;
    final savings = totalBudget - totalAllocated;

    final newSavings = savings > 0 ? savings : 0.0;

    // Only update if the value actually changed
    if (_savingsNotifier.value != newSavings) {
      _savingsNotifier.value = newSavings;
    }
  }

  void _loadBudgetData(String monthId) async {
    if (!mounted) return;

    final budgetVM = Provider.of<BudgetViewModel>(context, listen: false);

    // 直接从数据库加载预算数据
    // 预算的剩余金额已经在添加/更新/删除支出时自动更新到数据库
    await budgetVM.loadBudget(monthId);

    if (!mounted) return;

    final budget = budgetVM.budget;
    if (budget != null) {
      // Use a local variable first to avoid multiple notifier updates
      final newTotalBudget = budget.total;

      // Update category controllers without triggering listeners
      for (final catId in _budgetCategoryIds) {
        if (_categoryControllers.containsKey(catId)) {
          final controller = _categoryControllers[catId]!;
          final budgetValue = budget.categories[catId]?.budget.toString() ?? '';

          // Only update if different to avoid unnecessary rebuilds
          if (controller.text != budgetValue) {
            controller.text = budgetValue;
          }
        }
      }

      // Update total budget last to minimize rebuilds
      _totalBudgetNotifier.value = newTotalBudget;
    } else {
      _totalBudgetNotifier.value = null;

      // Clear category controllers
      for (final catId in _budgetCategoryIds) {
        if (_categoryControllers.containsKey(catId) &&
            _categoryControllers[catId]!.text.isNotEmpty) {
          _categoryControllers[catId]!.text = '';
        }
      }
    }

    // Calculate allocated budget after all controllers are updated
    _calculateTotalAllocated();
  }

  void _calculateTotalAllocated() {
    double total = 0;
    for (final catId in _budgetCategoryIds) {
      final controller = _categoryControllers[catId];
      if (controller != null) {
        final text = controller.text.trim();
        if (text.isNotEmpty) {
          final val = double.tryParse(text);
          if (val != null) {
            total += val;
          }
        }
      }
    }

    // Only update if the value actually changed
    if (_totalAllocatedNotifier.value != total) {
      _totalAllocatedNotifier.value = total;
    }
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _currentMonthId = _getMonthIdFromDate(newDate);
    });

    // Use post-frame callback to ensure setState is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBudgetData(_currentMonthId);
      }
    });
  }

  void _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSubmitting = true;
      });

      final totalBudget = _totalBudgetNotifier.value;
      if (totalBudget == null || totalBudget <= 0) {
        throw Exception('Please enter a valid total budget amount');
      }

      final Map<String, CategoryBudget> cats = {};

      for (final catId in _budgetCategoryIds) {
        final controller = _categoryControllers[catId];
        if (controller != null) {
          final text = controller.text.trim();
          final val = text.isNotEmpty ? (double.tryParse(text) ?? 0.0) : 0.0;
          // Initially set budget left = budget
          cats[catId] = CategoryBudget(budget: val, left: val);
        }
      }

      if (!mounted) return;
      final budgetVM = Provider.of<BudgetViewModel>(context, listen: false);
      final expensesVM = Provider.of<ExpensesViewModel>(context, listen: false);

      // Get year and month from month ID and calculate remaining budget
      try {
        final parts = _currentMonthId.split('-');
        if (parts.length == 2) {
          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);

          if (year != null && month != null) {
            // Create new budget object
            final newBudget =
                Budget(total: totalBudget, left: totalBudget, categories: cats);

            // Get expenses for current month
            final expenses = expensesVM.getExpensesForMonth(year, month);

            // Calculate the budget with expenses factored in
            final updatedBudget =
                await BudgetCalculationService.calculateBudget(
                    newBudget, expenses);

            // Save the final budget with correct remaining amounts - only one save operation
            await budgetVM.saveBudget(_currentMonthId, updatedBudget);
            debugPrint('Budget saved with expenses factored in');
          }
        }
      } catch (e) {
        debugPrint('Error calculating budget during save: $e');
        throw e; // Re-throw to show error message
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.budgetSavedMessage),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 2),
        ),
      );

      // Use Future.delayed to ensure budget update before returning to previous page
      // This ensures user sees latest data when returning to analytics page
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppConstants.setBudgetTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 日期选择按钮
            DatePickerButton(
              prefix: 'Budget for',
              date: _selectedDate,
              onDateChanged: _onDateChanged,
              themeColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
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
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.7),
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

                  // 获取该类别的剩余预算（如果有）
                  final categoryBudget = Provider.of<BudgetViewModel>(context)
                      .budget
                      ?.categories[catId];
                  final hasExistingBudget = categoryBudget != null;
                  final remainingBudget =
                      hasExistingBudget ? categoryBudget.left : 0.0;
                  final budgetPercentage =
                      hasExistingBudget && categoryBudget.budget > 0
                          ? (remainingBudget / categoryBudget.budget)
                              .clamp(0.0, 1.0)
                          : 0.0;

                  // 状态颜色
                  final statusColor = remainingBudget <= 0
                      ? Colors.red
                      : budgetPercentage < 0.3
                          ? Colors.orange
                          : Colors.green.shade700;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                      ),

                      // 类别预算剩余信息
                      if (hasExistingBudget) ...[
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 52.0, bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Remaining:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'MYR ${remainingBudget.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Stack(
                                children: [
                                  Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: budgetPercentage,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
          color: Theme.of(context).cardColor,
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
