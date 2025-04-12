import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/dashboard_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => LoginScreen(),
  '/home': (context) => HomeScreen(),
  '/expenses': (context) => ExpensesScreen(),
  '/settings': (context) => SettingsScreen(),
  '/dashboard': (context) => DashboardScreen(),
};
