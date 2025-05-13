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
import 'page_transition.dart';

class AppRouter {
  /// 确定页面之间的导航方向
  static NavDirection _getNavigationDirection(
      String? fromRoute, String toRoute) {
    // 定义页面的逻辑顺序和位置 - 数字越小表示越靠左
    final pagePositions = {
      Routes.home: 0,
      Routes.analytic: 1,
      Routes.settings: 2,
      Routes.profile: 3,
      Routes.expenses: 4,
      Routes.splash: -1,
      Routes.login: -1,
    };

    // 如果起始页或目标页不在定义的位置中，默认使用前进动画
    if (fromRoute == null ||
        !pagePositions.containsKey(fromRoute) ||
        !pagePositions.containsKey(toRoute)) {
      return NavDirection.forward;
    }

    // 计算位置差来决定方向
    final fromPosition = pagePositions[fromRoute]!;
    final toPosition = pagePositions[toRoute]!;

    // 如果目标位置更靠右，则前进（从右侧滑入）
    // 如果目标位置更靠左，则后退（从左侧滑入）
    if (toPosition > fromPosition) {
      return NavDirection.forward; // 向右
    } else {
      return NavDirection.backward; // 向左
    }
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // 获取当前路由
    final fromRoute =
        ModalRoute.of(navigatorKey.currentContext!)?.settings.name;
    final direction = _getNavigationDirection(fromRoute, settings.name ?? '');

    // 使用淡入淡出+滑动的组合动画效果
    const forwardTransition = TransitionType.fadeAndSlideRight;
    const backwardTransition = TransitionType.fadeAndSlideLeft;

    // 特殊情况：添加支出页面使用从底部滑入的动画
    if (settings.name == Routes.expenses) {
      return PageTransition(
        child: const AddExpenseScreen(),
        type: TransitionType.fadeAndSlideUp, // 从底部淡入并滑入
        settings: settings,
      );
    }

    switch (settings.name) {
      case Routes.splash:
        return createRoute(
          const SplashScreen(),
          settings: settings,
          forwardTransition: TransitionType.fade,
        );
      case Routes.login:
        return createRoute(const LoginScreen(),
            settings: settings,
            direction: direction,
            forwardTransition: forwardTransition,
            backwardTransition: backwardTransition);
      case Routes.home:
        return createRoute(
            ChangeNotifierProvider(
              create: (_) => di.sl<ExpensesViewModel>(),
              child: const HomeScreen(),
            ),
            settings: settings,
            direction: direction,
            forwardTransition: forwardTransition,
            backwardTransition: backwardTransition);
      case Routes.analytic:
        return createRoute(const AnalyticScreen(),
            settings: settings,
            direction: direction,
            forwardTransition: forwardTransition,
            backwardTransition: backwardTransition);
      case Routes.profile:
        return createRoute(const ProfileScreen(),
            settings: settings,
            direction: direction,
            forwardTransition: forwardTransition,
            backwardTransition: backwardTransition);
      case Routes.settings:
        return createRoute(const SettingScreen(),
            settings: settings,
            direction: direction,
            forwardTransition: forwardTransition,
            backwardTransition: backwardTransition);
      default:
        return createRoute(
            Scaffold(
              body: Center(
                child: Text('No route defined for ${settings.name}'),
              ),
            ),
            settings: settings);
    }
  }
}

/// 全局导航键，用于在没有上下文的情况下访问Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
