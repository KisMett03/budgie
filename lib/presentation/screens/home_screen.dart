import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../viewmodels/expenses_viewmodel.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/legend_card.dart';
import '../widgets/expense_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/date_picker_button.dart';
import '../../core/constants/routes.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';

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
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF57C00)))
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                // Month selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DatePickerButton(
                    date: _selectedDate,
                    themeColor: const Color(0xFFF57C00),
                    prefix: 'Expenses for',
                    onDateChanged: _onDateChanged,
                  ),
                ),

                // Summary info
                Padding(
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

                // 1) Pie chart in a fixed box
                expenses.isEmpty
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

                // 2) Some breathing room
                const SizedBox(height: 2),

                // 3) Legend card, auto-height 2×3 grid
                if (expenses.isNotEmpty)
                  LegendCard(
                      categories:
                          categoryTotals.keys.map((e) => e.id).toList()),

                // 4) More breathing room
                const SizedBox(height: 12),

                // 5) All your expense cards
                ...expenses.map((e) => ExpenseCard(expense: e)),

                // If no expenses, show a message
                if (expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'Add your first expense by tapping the + button below',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),

                // 6) Padding at bottom so FAB + NavBar don't cover last card
                const SizedBox(height: 90),
              ],
            ),

      // 3) Floating "+" button
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, Routes.expenses),
        backgroundColor: const Color(0xFFF57C00),
        shape: const CircleBorder(),
        enableFeedback: true,
        child: const Icon(Icons.add, color: Color(0xFFFBFCF8)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 4) Bottom nav bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (idx) {

        },
      ),
    );
  }
}
