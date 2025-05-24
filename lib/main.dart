import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'core/constants/firebase_options.dart';
import 'core/constants/routes.dart';
import 'core/router/app_router.dart';
import 'presentation/viewmodels/expenses_viewmodel.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/budget_viewmodel.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';
import 'di/injection_container.dart' as di;
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/analytic_screen.dart';
import 'presentation/screens/setting_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/widgets/animated_float_button.dart';
import 'presentation/utils/app_theme.dart';

Future<void> main() async {
  // Ensure we can call async code before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with proper error handling
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Check Firebase Auth status
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    debugPrint('Current Firebase user: ${currentUser?.uid ?? 'Not signed in'}');

    // Set up persistence for Auth
    try {
      await auth.setPersistence(Persistence.LOCAL);
      debugPrint('Firebase Auth persistence set to LOCAL');
    } catch (e) {
      debugPrint('Failed to set persistence: $e');
    }

    // Initialize dependency injection
    debugPrint('Initializing dependency injection...');
    await di.init();
    debugPrint('Dependency injection initialized');

    // Wrap your entire app in all the providers you'll need
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => di.sl<AuthViewModel>()),
          ChangeNotifierProvider(create: (_) => di.sl<ExpensesViewModel>()),
          ChangeNotifierProvider(create: (_) => di.sl<BudgetViewModel>()),
          ChangeNotifierProvider.value(value: di.sl<ThemeViewModel>()),
          // TODO: add more providers here as you build out other features
        ],
        child: const BudgieApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint(stackTrace.toString());
    // Show error UI
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 48.0),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Initialization Error',
                    style:
                        TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Failed to initialize app: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: () => main(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BudgieApp extends StatelessWidget {
  const BudgieApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context);

    return MaterialApp(
      title: 'Budgie',
      theme: themeViewModel.theme,
      debugShowCheckedModeBanner: false,

      // 添加导航键
      navigatorKey: navigatorKey,

      // 注册路由观察者
      navigatorObservers: [
        fabRouteObserver,
      ],

      // 定义主要路由
      routes: {
        Routes.home: (context) => ChangeNotifierProvider(
              create: (_) => di.sl<ExpensesViewModel>(),
              child: const HomeScreen(),
            ),
        Routes.analytic: (context) => const AnalyticScreen(),
        Routes.settings: (context) => const SettingScreen(),
        Routes.profile: (context) => const ProfileScreen(),
      },

      // 使用自定义路由生成器处理其他路由
      onGenerateRoute: AppRouter.generateRoute,

      // 初始路由
      initialRoute: Routes.splash,
    );
  }
}
