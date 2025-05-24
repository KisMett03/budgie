import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/legend_card.dart';
import '../widgets/expense_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/date_picker_button.dart';
import '../widgets/animated_float_button.dart';
import '../widgets/notification_expense_card.dart';
import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        title: Text('Home'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),

      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary))
          : RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async {
                // 调用ViewModel的刷新方法
                await Provider.of<ExpensesViewModel>(context, listen: false)
                    .refreshData();
              },
              child: CustomScrollView(
                slivers: [
                  const SliverPadding(
                    padding: const EdgeInsets.only(top: 16.0),
                    sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),

                  // Auto-detected expenses section
                  SliverToBoxAdapter(
                    child: _buildAutoDetectedExpensesSection(),
                  ),

                  // Month selector
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DatePickerButton(
                        date: _selectedDate,
                        themeColor: Theme.of(context).colorScheme.primary,
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        enableFeedback: true,
        reactToRouteChange: true,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
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

  Widget _buildAutoDetectedExpensesSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('auto_detected_expenses')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final autoExpenses = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Auto-detected Expenses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            ...autoExpenses.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return NotificationExpenseCard(
                expenseData: data,
                onApprove: () => _approveExpense(doc.id, data),
                onReject: () => _rejectExpense(doc.id),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Future<void> _approveExpense(String docId, Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Add to regular expenses collection
      await FirebaseFirestore.instance.collection('expenses').add({
        'userId': user.uid,
        'amount': data['amount'],
        'description': data['merchant'] ?? 'Auto-detected expense',
        'category': 'Other', // Default category
        'date': data['date'] ?? DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'isAutoDetected': true,
        'originalSource': data['source'],
      });

      // Remove from auto-detected collection
      await FirebaseFirestore.instance
          .collection('auto_detected_expenses')
          .doc(docId)
          .delete();

      // Refresh expenses
      if (mounted) {
        final vm = Provider.of<ExpensesViewModel>(context, listen: false);
        await vm.refreshData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectExpense(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('auto_detected_expenses')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense dismissed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error dismissing expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
