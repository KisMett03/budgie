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

class _AnalyticScreenState extends State<AnalyticScreen> {
  DateTime _selectedDate = DateTime.now();
  String _currentMonthId = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentMonthId = formatMonthId(_selectedDate);
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 获取预算视图模型
      final budgetViewModel =
          Provider.of<BudgetViewModel>(context, listen: false);

      // 设置支出视图模型的月份筛选（用于UI显示一致性）
      final expensesViewModel =
          Provider.of<ExpensesViewModel>(context, listen: false);
      expensesViewModel.setSelectedMonth(_selectedDate);

      // 直接从数据库加载预算数据（预算的剩余金额已经在支出变更时更新到数据库）
      await budgetViewModel.loadBudget(_currentMonthId);

      // 检查ViewModel中是否有错误
      if (budgetViewModel.errorMessage != null) {
        setState(() {
          _errorMessage = budgetViewModel.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载预算失败: ${e.toString()}';
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
            isAuthError ? '您需要登录才能查看预算' : _errorMessage ?? '出现错误',
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
              child: const Text('去登录'),
            ),
          if (!isAuthError)
            ElevatedButton(
              onPressed: _loadBudgetData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF57C00),
              ),
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFF57C00);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytic'),
        automaticallyImplyLeading: false,
        backgroundColor: themeColor,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 使用DatePickerButton组件保持UI一致性
          Padding(
            padding: EdgeInsets.all(16.0),
            child: DatePickerButton(
              date: _selectedDate,
              themeColor: themeColor,
              prefix: 'Budget for',
              onDateChanged: _onDateChanged,
            ),
          ),

          // 预算卡片
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: themeColor))
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : Consumer<BudgetViewModel>(
                        builder: (context, vm, _) {
                          return SingleChildScrollView(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              children: [
                                BudgetCard(
                                  budget: vm.budget,
                                  onTap: () async {
                                    // 直接进入预算编辑页面，不需要重新计算
                                    // 预算的剩余金额已经在添加/更新/删除支出时自动更新到数据库
                                    if (!mounted) return;

                                    // 使用自定义页面转换
                                    Navigator.push(
                                      context,
                                      PageTransition(
                                        child: AddBudgetScreen(
                                          monthId: _currentMonthId,
                                        ),
                                        type: TransitionType.slideRight,
                                      ),
                                    ).then((_) {
                                      // 编辑完成后重新加载预算数据
                                      _loadBudgetData();
                                    });
                                  },
                                ),

                                // 这里可以添加其他分析内容
                                // ...
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      extendBody: true,
      floatingActionButton: AnimatedFloatButton(
        onPressed: () {
          // 使用自定义动画导航到添加支出页面
          Navigator.push(
            context,
            PageTransition(
              child: const AddExpenseScreen(),
              type: TransitionType.fadeAndSlideUp,
              settings: const RouteSettings(name: Routes.expenses),
            ),
          );
        },
        backgroundColor: const Color(0xFFF57C00),
        shape: const CircleBorder(),
        enableFeedback: true,
        reactToRouteChange: true,
        child: const Icon(Icons.add, color: Color(0xFFFBFCF8)),
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
