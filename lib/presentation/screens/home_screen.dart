import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../viewmodels/expenses_viewmodel.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/legend_card.dart';
import '../widgets/expense_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/date_picker_button.dart';
import '../widgets/animated_float_button.dart';
import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    // Initialize with current month filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<ExpensesViewModel>(context, listen: false);
      vm.setSelectedMonth(_selectedDate);
    });
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });

    final vm = Provider.of<ExpensesViewModel>(context, listen: false);
    vm.setSelectedMonth(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpensesViewModel>();
    final expenses = vm.expenses;
    final height = MediaQuery.of(context).size.height;
    final isLoading = vm.isLoading;

    // Use the ViewModel's method to get category totals
    final categoryTotals = vm.getCategoryTotals();
    final totalAmount = vm.getTotalExpenses();

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Home',
            style: TextStyle(fontFamily: 'Lexend', fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF57C00)))
          : CustomScrollView(
              slivers: [
                // Month selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DatePickerButton(
                      date: _selectedDate,
                      themeColor: const Color(0xFFF57C00),
                      prefix: 'Expenses for',
                      onDateChanged: _onDateChanged,
                    ),
                  ),
                ),

                // Summary info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total: MYR ${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF57C00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 1) Pie chart in a fixed box
                SliverToBoxAdapter(
                  child: expenses.isEmpty
                      ? SizedBox(
                          height: height * 0.25,
                          child: const Center(
                            child: Text(
                              'No expenses for this month',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: height * 0.25,
                          child: ExpensePieChart(data: categoryTotals),
                        ),
                ),

                // 2) Some breathing room
                const SliverToBoxAdapter(child: SizedBox(height: 15)),

                // 3) Legend card, auto-height 2×3 grid
                if (expenses.isNotEmpty)
                  SliverToBoxAdapter(
                    child: LegendCard(
                        categories:
                            categoryTotals.keys.map((e) => e.id).toList()),
                  ),

                // 4) More breathing room
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // 5) All your expense cards
                expenses.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'Add your first expense by tapping the + button below',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              ExpenseCard(expense: expenses[index]),
                          childCount: expenses.length,
                        ),
                      ),

                // 6) Padding at bottom so FAB + NavBar don't cover last card
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),

      // 3) Floating "+" button
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

      // 4) Bottom nav bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (idx) {
          // 实现导航逻辑
          if (idx != 0) {
            switch (idx) {
              case 1:
                Navigator.pushReplacementNamed(context, Routes.analytic);
                break;
              case 2:
                Navigator.pushReplacementNamed(context, Routes.settings);
                break;
              case 3:
                Navigator.pushReplacementNamed(context, Routes.profile);
                break;
            }
          }
        },
      ),
    );
  }
}
