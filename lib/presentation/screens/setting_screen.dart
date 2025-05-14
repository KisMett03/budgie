import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../widgets/switch_tile.dart';
import '../widgets/dropdown_tile.dart';
import '../widgets/auth_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/animated_float_button.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
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
  String currency = 'MYR';
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
    final data = doc.data() ?? {};
    final settings = data['settings'] ?? {};

    setState(() {
      autoBudget = settings['autoBudget'] ?? false;
      allowNotification = settings['allowNotification'] ?? false;
      allowExtract = settings['allowExtract'] ?? false;
      improveAccuracy = settings['improveAccuracy'] ?? false;
      currency = data['currency'] ?? 'MYR';
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

  Future<void> _updateCurrency(String value) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.updateUserSettings(currency: value);
    setState(() {
      currency = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Setting',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Theme.of(context).dividerColor,
            height: 0.5,
          ),
        ),
      ),
      body: ListView(
        children: [
          // 货币选择
          DropdownTile<String>(
            title: 'Currency',
            value: currency,
            items: AppConstants.currencies,
            onChanged: (value) {
              if (value != null) {
                _updateCurrency(value);
              }
            },
            itemLabelBuilder: (item) => item,
          ),

          // 暗色主题切换
          SwitchTile(
            title: 'Dark Theme',
            value: themeViewModel.isDarkMode,
            onChanged: (v) {
              themeViewModel.toggleTheme();
            },
          ),

          // 开关选项
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        enableFeedback: true,
        reactToRouteChange: true,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
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
