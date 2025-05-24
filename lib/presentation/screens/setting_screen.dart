import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/settings_service.dart';
import '../../di/injection_container.dart' as di;
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
  bool _loading = true;

  // Get services
  final _notificationService = di.sl<NotificationService>();
  final _settingsService = di.sl<SettingsService>();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Listen to settings changes
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Settings are already loaded by AuthViewModel, just update the UI
      setState(() {
        _loading = false;
      });

      // Check if permissions match settings
      await _checkNotificationPermissionStatus();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _checkNotificationPermissionStatus() async {
    final hasNotificationPermission =
        await _notificationService.checkNotificationPermission();

    if (hasNotificationPermission != _settingsService.allowNotification) {
      await _settingsService
          .updateNotificationSetting(hasNotificationPermission);
    }
  }

  Future<void> _updateCurrency(String value) async {
    try {
      await _settingsService.updateCurrency(value);
      debugPrint('Currency updated to: $value');
    } catch (e) {
      debugPrint('Error updating currency: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update currency: $e')),
        );
      }
    }
  }

  Future<void> _handleNotificationPermission(bool value) async {
    try {
      if (value) {
        // Request notification permission
        final granted =
            await _notificationService.requestNotificationPermission();

        await _settingsService.updateNotificationSetting(granted);

        // Start or stop notification listener based on permission
        if (granted) {
          await _notificationService.startNotificationListener();
          if (mounted) {
            _notificationService.showSnackBarNotification(context,
                'Notification permission granted and listener started');
          }
        }
      } else {
        // User wants to disable notifications
        await _settingsService.updateNotificationSetting(false);

        // Stop notification listener
        await _notificationService.stopNotificationListener();
      }
    } catch (e) {
      debugPrint('Error handling notification permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update notification setting: $e')),
        );
      }
    }
  }

  Future<void> _updateAutoBudget(bool value) async {
    try {
      await _settingsService.updateAutoBudgetSetting(value);
      debugPrint('Auto budget updated to: $value');
    } catch (e) {
      debugPrint('Error updating auto budget: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update auto budget: $e')),
        );
      }
    }
  }

  Future<void> _updateImproveAccuracy(bool value) async {
    try {
      await _settingsService.updateImproveAccuracySetting(value);
      debugPrint('Improve accuracy updated to: $value');
    } catch (e) {
      debugPrint('Error updating improve accuracy: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update improve accuracy: $e')),
        );
      }
    }
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
          // Currency selection
          DropdownTile<String>(
            title: 'Currency',
            value: _settingsService.currency,
            items: AppConstants.currencies,
            onChanged: (value) {
              if (value != null) {
                _updateCurrency(value);
              }
            },
            itemLabelBuilder: (item) => item,
          ),

          // Dark theme toggle
          SwitchTile(
            title: 'Dark Theme',
            value: themeViewModel.isDarkMode,
            onChanged: (v) {
              themeViewModel.toggleTheme();
            },
          ),

          // Switch options
          SwitchTile(
            title: 'Auto budget rebalance',
            value: _settingsService.autoBudget,
            onChanged: _updateAutoBudget,
          ),
          SwitchTile(
            title: 'Allow notification',
            value: _settingsService.allowNotification,
            onChanged: _handleNotificationPermission,
            subtitle:
                'Enable notification monitoring for automatic expense detection',
          ),
          SwitchTile(
            title: 'Improve model accuracy',
            value: _settingsService.improveAccuracy,
            onChanged: _updateImproveAccuracy,
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
