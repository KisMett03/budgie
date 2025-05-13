import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/constants/firebase_options.dart';
import 'core/constants/routes.dart';
import 'core/router/app_router.dart';
import 'presentation/viewmodels/expenses_viewmodel.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/budget_viewmodel.dart';
import 'di/injection_container.dart' as di;

Future<void> main() async {
  // Ensure we can call async code before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize dependency injection
  await di.init();

  // Wrap your entire app in all the providers you'll need
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => di.sl<ExpensesViewModel>()),
        ChangeNotifierProvider(create: (_) => di.sl<BudgetViewModel>()),
        // TODO: add more providers here as you build out other features
      ],
      child: const BudgieApp(),
    ),
  );
}

class BudgieApp extends StatelessWidget {
  const BudgieApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budgie',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Lexend',
      ),
      debugShowCheckedModeBanner: false,

      // Use your router as before
      onGenerateRoute: AppRouter.generateRoute,

      // 🔥 Temporarily jump straight to home
      initialRoute: Routes.splash,
    );
  }
}
