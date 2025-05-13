import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/add_expense_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/setting_screen.dart';
import '../../presentation/viewmodels/expenses_viewmodel.dart';
import '../../presentation/screens/analytic_screen.dart';
import '../constants/routes.dart';
import '../../di/injection_container.dart' as di;

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.home:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => di.sl<ExpensesViewModel>(),
            child: const HomeScreen(),
          ),
        );
      case Routes.expenses:
        return MaterialPageRoute(builder: (_) => const AddExpenseScreen());
      case Routes.analytic:
        return MaterialPageRoute(builder: (_) => const AnalyticScreen());
      case Routes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case Routes.settings:
        return MaterialPageRoute(builder: (_) => const SettingScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
