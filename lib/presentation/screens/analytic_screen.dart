import 'package:budgie/presentation/screens/add_budget_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/budget_card.dart';
import '../widgets/date_picker_button.dart';
import '../widgets/animated_float_button.dart';
import 'add_expense_screen.dart';

import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';

String formatMonthId(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

class AnalyticScreen extends StatefulWidget {
  const AnalyticScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticScreen> createState() => _AnalyticScreenState();
}

class _AnalyticScreenState extends State<AnalyticScreen>
    with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  String _currentMonthId = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize with default values
    _selectedDate = DateTime.now();
    _currentMonthId = formatMonthId(_selectedDate);

    // Delay initialization to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeFilters();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeFilters();
    }
  }

  void _initializeFilters() {
    try {
      final expensesViewModel =
          Provider.of<ExpensesViewModel>(context, listen: false);

      // Get the screen-specific filter
      _selectedDate = expensesViewModel.getScreenFilterDate('analytics');
      _currentMonthId = formatMonthId(_selectedDate);

      // Apply the filter
      expensesViewModel.setSelectedMonth(_selectedDate,
          persist: true, screenKey: 'analytics');

      setState(() {
        _isInitialized = true;
      });

      // Load the budget data with the selected month
      _loadBudgetData();
    } catch (e) {
      debugPrint('Error retrieving analytic screen filter: $e');
      _selectedDate = DateTime.now();
      _currentMonthId = formatMonthId(_selectedDate);
      _loadBudgetData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app is resumed, refresh the data
    if (state == AppLifecycleState.resumed && mounted) {
      _loadBudgetData();
      Provider.of<ExpensesViewModel>(context, listen: false).refreshData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadBudgetData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get view models
      final budgetViewModel =
          Provider.of<BudgetViewModel>(context, listen: false);
      final expensesViewModel =
          Provider.of<ExpensesViewModel>(context, listen: false);

      // Set selected month for expenses, ensure we persist the filter
      expensesViewModel.setSelectedMonth(_selectedDate,
          persist: true, screenKey: 'analytics');

      // Explicitly update budget for this month to ensure it's current
      await expensesViewModel.updateBudgetForMonth(
          _selectedDate.year, _selectedDate.month);

      // Load budget data from database (now updated)
      await budgetViewModel.loadBudget(_currentMonthId);

      // Check for errors
      if (budgetViewModel.errorMessage != null) {
        setState(() {
          _errorMessage = budgetViewModel.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load budgets: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _currentMonthId = formatMonthId(_selectedDate);
      _errorMessage = null;
    });

    // Save to screen-specific filter
    final expensesViewModel =
        Provider.of<ExpensesViewModel>(context, listen: false);
    expensesViewModel.setSelectedMonth(_selectedDate,
        persist: true, screenKey: 'analytics');

    _loadBudgetData();
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, Routes.login);
  }

  Widget _buildErrorWidget() {
    final bool isAuthError =
        _errorMessage?.contains('not authenticated') ?? false;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAuthError ? Icons.login : Icons.error_outline,
            color: Colors.red[300],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isAuthError
                ? 'Login to view your Budgets'
                : _errorMessage ?? 'Error occurred',
            style: TextStyle(color: Colors.red[300]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (isAuthError)
            ElevatedButton(
              onPressed: _navigateToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF57C00),
              ),
              child: const Text('Login'),
            ),
          if (!isAuthError)
            ElevatedButton(
              onPressed: _loadBudgetData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF57C00),
              ),
              child: const Text('Retry again'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytic'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _errorMessage != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: () async {
                    // 刷新预算数据
                    await _loadBudgetData();
                    // 同时刷新支出数据
                    await Provider.of<ExpensesViewModel>(context, listen: false)
                        .refreshData();
                  },
                  child: CustomScrollView(
                    slivers: [
                      // 顶部间距
                      const SliverPadding(
                        padding: EdgeInsets.only(top: 16.0),
                        sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                      ),

                      // 日期选择器
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverToBoxAdapter(
                          child: DatePickerButton(
                            date: _selectedDate,
                            themeColor: Theme.of(context).colorScheme.primary,
                            prefix: 'Budget for',
                            onDateChanged: _onDateChanged,
                            showDaySelection: false,
                          ),
                        ),
                      ),

                      // 预算卡片
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverToBoxAdapter(
                          child: Consumer<BudgetViewModel>(
                            builder: (context, vm, _) {
                              return BudgetCard(
                                budget: vm.budget,
                                onTap: () async {
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    PageTransition(
                                      child: AddBudgetScreen(
                                        monthId: _currentMonthId,
                                      ),
                                      type: TransitionType.slideRight,
                                    ),
                                  ).then((_) {
                                    _loadBudgetData();
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),

                      // 这里可以添加其他分析内容
                      // ...

                      // 底部填充
                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: 80.0),
                        sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                      ),
                    ],
                  ),
                ),
      extendBody: true,
      floatingActionButton: AnimatedFloatButton(
        onPressed: () {
          Navigator.push(
            context,
            PageTransition(
              child: const AddExpenseScreen(),
              type: TransitionType.fadeAndSlideUp,
              settings: const RouteSettings(name: Routes.expenses),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        enableFeedback: true,
        reactToRouteChange: true,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (idx) {
          // Navigation is handled in BottomNavBar
        },
      ),
    );
  }
}
