import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/unused/expenses_screen.dart';
import '../../presentation/screens/setting_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/analytic_screen.dart';
import '../../presentation/viewmodels/expenses_viewmodel.dart';

/// Holds all route names used in the app
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String expenses = '/expenses';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String analytic = '/analytic';
}
