import 'package:budgie/widgets/animated_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:budgie/widgets/silver_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controls the hiding/showing of the nav bar.
  bool _navBarVisible = true;
  // Tracks which nav item is selected.
  int _selectedIndex = 0;
  // For detecting scroll direction.
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_listenToScroll);
  }

  // Hide nav bar on scroll down and show on scroll up.
  void _listenToScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_navBarVisible) {
        setState(() {
          _navBarVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_navBarVisible) {
        setState(() {
          _navBarVisible = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_listenToScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Handle navigation item taps.
  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Implement your navigation logic.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AnimatedNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        duration: const Duration(milliseconds: 300),
        isVisible: _navBarVisible,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // PageView with some sample content.
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.lightBlueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Balance Overview",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "RM ${(5000 - index * 780).toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // "Recent Transactions" title row.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: const [
                  Text(
                    "Recent Transactions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.history, size: 20),
                ],
              ),
            ),
          ),
          // Transaction list.
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.shopping_cart, color: Colors.white),
                    ),
                    title: Text("Transaction ${index + 1}"),
                    subtitle: const Text("Category - Notes"),
                    trailing: Text(
                      "- RM ${(index + 1) * 7}",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              childCount: 20,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
