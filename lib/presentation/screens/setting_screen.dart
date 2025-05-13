import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../widgets/switch_tile.dart';
import '../widgets/auth_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/animated_float_button.dart';
import 'add_expense_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool autoBudget = false;
  bool allowNotification = false;
  bool allowExtract = true;
  bool improveAccuracy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data()?['settings'] ?? {};
    setState(() {
      autoBudget = data['autoBudget'] ?? false;
      allowNotification = data['allowNotification'] ?? false;
      allowExtract = data['allowExtract'] ?? false;
      improveAccuracy = data['improveAccuracy'] ?? false;
      _loading = false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'settings': {key: value}
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7FCFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Setting', style: TextStyle(color: Colors.black)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.black12,
            height: 0.5,
          ),
        ),
      ),
      body: ListView(
        children: [
          SwitchTile(
            title: 'Auto budget rebalance',
            value: autoBudget,
            onChanged: (v) {
              setState(() => autoBudget = v);
              _updateSetting('autoBudget', v);
            },
          ),
          SwitchTile(
            title: 'Allow notification',
            value: allowNotification,
            onChanged: (v) {
              setState(() => allowNotification = v);
              _updateSetting('allowNotification', v);
            },
          ),
          SwitchTile(
            title: 'Allow extract info from notification',
            value: allowExtract,
            onChanged: (v) {
              setState(() => allowExtract = v);
              _updateSetting('allowExtract', v);
            },
          ),
          SwitchTile(
            title: 'Improve model accuracy',
            value: improveAccuracy,
            onChanged: (v) {
              setState(() => improveAccuracy = v);
              _updateSetting('improveAccuracy', v);
            },
          ),
        ],
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
        backgroundColor: const Color(0xFFF57C00),
        shape: const CircleBorder(),
        enableFeedback: true,
        reactToRouteChange: true,
        child: const Icon(Icons.add, color: Color(0xFFFBFCF8)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2, // Settings tab
        onTap: (idx) {
          // Navigation is handled in BottomNavBar
        },
      ),
    );
  }
}
