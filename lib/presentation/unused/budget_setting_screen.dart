import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../widgets/section_header.dart';
import '../widgets/date_picker_button.dart';
import '../widgets/budget_progress.dart';
import '../widgets/savings_display.dart';
import '../widgets/category_budget_field.dart';
import '../widgets/currency_text_field.dart';
import '../widgets/custom_card.dart';
import '../utils/category_manager.dart';

class BudgetSettingScreen extends StatefulWidget {
  final String monthId;
  const BudgetSettingScreen({Key? key, required this.monthId})
      : super(key: key);

  @override
  State<BudgetSettingScreen> createState() =>
      _BudgetSettingScreenRefactoredState();
}

class _BudgetSettingScreenRefactoredState extends State<BudgetSettingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Use ValueNotifier instead of direct setState calls
  final ValueNotifier<double?> _totalBudgetNotifier =
      ValueNotifier<double?>(null);
  final ValueNotifier<double> _totalAllocatedNotifier =
      ValueNotifier<double>(0);
  final ValueNotifier<double> _savingsNotifier = ValueNotifier<double>(0);

  // Date related properties
  DateTime _selectedDate = DateTime.now();
  String _currentMonthId = '';

  final Map<String, TextEditingController> _categoryControllers = {};

  // Main theme color
  final Color _themeColor = const Color(0xFFF57C00);

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
    _currentMonthId = widget.monthId;
    // Parse the month ID to get the date
    try {
      final parts = _currentMonthId.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        _selectedDate = DateTime(year, month);
      }
    } catch (e) {
      // If parsing fails, use current date
      _selectedDate = DateTime.now();
    }

    _setupListeners();
    _loadBudgetData(_currentMonthId);
  }

  void _setupListeners() {
    // Listen for total budget changes, calculate savings
    _totalBudgetNotifier.addListener(_calculateSavings);
    _totalAllocatedNotifier.addListener(_calculateSavings);

    // Create controllers for each category
    for (final cat in CategoryManager.getBudgetCategoryIds()) {
      _categoryControllers[cat] = TextEditingController();
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

      for (final cat in CategoryManager.getBudgetCategoryIds()) {
        _categoryControllers[cat]?.text =
            budget.categories[cat]?.budget.toString() ?? '';
      }
    } else {
      _totalBudgetNotifier.value = null;
      for (final cat in CategoryManager.getBudgetCategoryIds()) {
        _categoryControllers[cat]?.text = '';
      }
    }

    // Calculate allocated budget
    _calculateTotalAllocated();
  }

  void _calculateTotalAllocated() {
    double total = 0;
    for (final cat in CategoryManager.getBudgetCategoryIds()) {
      final val = double.tryParse(_categoryControllers[cat]?.text ?? '') ?? 0;
      total += val;
    }
    _totalAllocatedNotifier.value = total;
  }

  void _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final total = _totalBudgetNotifier.value ?? 0;
    final Map<String, CategoryBudget> cats = {};

    for (final cat in CategoryManager.getBudgetCategoryIds()) {
      final val = double.tryParse(_categoryControllers[cat]?.text ?? '') ?? 0;
      cats[cat] = CategoryBudget(budget: val, left: val);
    }

    final newBudget = Budget(total: total, left: total, categories: cats);

    if (!mounted) return;
    await Provider.of<BudgetViewModel>(context, listen: false)
        .saveBudget(_currentMonthId, newBudget);

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _onDateChanged(DateTime newDate) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Edit mode shows current month only. Go back to analytics to change month.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Set Budget'),
        backgroundColor: _themeColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Display current month as a label
            DatePickerButton(
              date: _selectedDate,
              themeColor: _themeColor,
              onDateChanged: _onDateChanged,
            ),

            // Total Budget Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    icon: Icons.account_balance_wallet,
                    title: 'Total Budget',
                    iconColor: _themeColor,
                  ),
                  const SizedBox(height: 20),
                  ValueListenableBuilder<double?>(
                    valueListenable: _totalBudgetNotifier,
                    builder: (context, totalBudget, _) {
                      return CurrencyTextField(
                        initialValue: totalBudget?.toString(),
                        labelText: 'Total Budget (MYR)',
                        currencySymbol: 'MYR',
                        onChanged: (v) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _totalBudgetNotifier.value = double.tryParse(v);
                          });
                        },
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please enter total budget'
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Budget allocation progress indicator
                  ValueListenableBuilder<double?>(
                    valueListenable: _totalBudgetNotifier,
                    builder: (context, totalBudget, _) {
                      return ValueListenableBuilder<double>(
                        valueListenable: _totalAllocatedNotifier,
                        builder: (context, totalAllocated, _) {
                          return BudgetProgress(
                            totalBudget: totalBudget,
                            allocatedBudget: totalAllocated,
                            themeColor: _themeColor,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Savings Card
            ValueListenableBuilder<double>(
              valueListenable: _savingsNotifier,
              builder: (context, savings, _) {
                return CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        icon: Icons.savings,
                        title: 'Savings',
                        iconColor: _themeColor,
                        iconSize: 25,
                      ),
                      const SizedBox(height: 20),
                      SavingsDisplay(
                        savings: savings,
                        themeColor: _themeColor,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Category Budget Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    icon: Icons.category,
                    title: 'Category Budgets',
                    iconColor: _themeColor,
                  ),
                  const SizedBox(height: 20),
                  ...CategoryManager.getBudgetCategoryIds().map((cat) {
                    return CategoryBudgetField(
                      category: cat,
                      icon: CategoryManager.getIconFromId(cat),
                      iconColor: CategoryManager.getColorFromId(cat),
                      controller: _categoryControllers[cat]!,
                      onChanged: (value) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _calculateTotalAllocated();
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
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
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _saveBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Budget',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
