import 'package:budgie/presentation/screens/add_budget_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/budget_viewmodel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/budget_card.dart';
import '../widgets/date_picker_button.dart';

import '../../core/constants/routes.dart';

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

  @override
  void initState() {
    super.initState();
    _currentMonthId = formatMonthId(_selectedDate);
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() {
      _isLoading = true;
    });

    await Provider.of<BudgetViewModel>(context, listen: false)
        .loadBudget(_currentMonthId);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _currentMonthId = formatMonthId(_selectedDate);
    });
    _loadBudgetData();
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
            padding: const EdgeInsets.all(16.0),
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
                : Consumer<BudgetViewModel>(
                    builder: (context, vm, _) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            BudgetCard(
                              budget: vm.budget,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddBudgetScreen(
                                      monthId: _currentMonthId,
                                    ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, Routes.expenses),
        backgroundColor: themeColor,
        shape: const CircleBorder(),
        enableFeedback: true,
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
