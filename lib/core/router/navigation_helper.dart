import 'package:flutter/material.dart';
import 'app_router.dart';
import 'page_transition.dart';
import '../constants/routes.dart';

/// Enhanced navigation helper with smooth transitions
class NavigationHelper {
  /// Navigate with smooth slide transition
  static Future<T?> navigateWithSlide<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
    TransitionType? customTransition,
  }) async {
    final route = PageTransition(
      child: _getScreenWidget(routeName),
      type: customTransition ?? TransitionType.smoothSlideRight,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      settings: RouteSettings(name: routeName, arguments: arguments),
    );

    if (replace) {
      return Navigator.pushReplacement<T, void>(context, route as Route<T>);
    } else {
      return Navigator.push<T>(context, route as Route<T>);
    }
  }

  /// Navigate with fade transition for subtle changes
  static Future<T?> navigateWithFade<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) async {
    final route = PageTransition(
      child: _getScreenWidget(routeName),
      type: TransitionType.smoothFadeSlide,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      settings: RouteSettings(name: routeName, arguments: arguments),
    );

    if (replace) {
      return Navigator.pushReplacement<T, void>(context, route as Route<T>);
    } else {
      return Navigator.push<T>(context, route as Route<T>);
    }
  }

  /// Navigate with scale transition for important screens
  static Future<T?> navigateWithScale<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) async {
    final route = PageTransition(
      child: _getScreenWidget(routeName),
      type: TransitionType.smoothScale,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutBack,
      settings: RouteSettings(name: routeName, arguments: arguments),
    );

    if (replace) {
      return Navigator.pushReplacement<T, void>(context, route as Route<T>);
    } else {
      return Navigator.push<T>(context, route as Route<T>);
    }
  }

  /// Navigate with modal-style transition (from bottom)
  static Future<T?> navigateModal<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    final route = PageTransition(
      child: _getScreenWidget(routeName),
      type: TransitionType.slideAndFadeVertical,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      settings: RouteSettings(name: routeName, arguments: arguments),
    );

    return Navigator.push<T>(context, route as Route<T>);
  }

  /// Navigate to home with special transition
  static Future<void> navigateToHome(BuildContext context,
      {bool replace = false}) async {
    await navigateWithSlide(
      context,
      Routes.home,
      replace: replace,
      customTransition: TransitionType.smoothSlideRight,
    );
  }

  /// Navigate to settings with Material Design transition
  static Future<void> navigateToSettings(BuildContext context) async {
    await navigateWithFade(context, Routes.settings);
  }

  /// Navigate to profile with scale transition
  static Future<void> navigateToProfile(BuildContext context) async {
    await navigateWithScale(context, Routes.profile);
  }

  /// Navigate to analytics with fade transition
  static Future<void> navigateToAnalytics(BuildContext context) async {
    await navigateWithFade(context, Routes.analytic);
  }

  /// Navigate to add expense as modal
  static Future<void> navigateToAddExpense(BuildContext context) async {
    await navigateModal(context, Routes.expenses);
  }

  /// Go back with smooth transition
  static void goBack(BuildContext context, [Object? result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  /// Replace current route with smooth transition
  static Future<T?> replace<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
    TransitionType? transition,
  }) async {
    final route = PageTransition(
      child: _getScreenWidget(routeName),
      type: transition ?? TransitionType.smoothSlideRight,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      settings: RouteSettings(name: routeName, arguments: arguments),
    );

    return Navigator.pushReplacement<T, TO>(context, route as Route<T>,
        result: result);
  }

  /// Clear stack and navigate to route
  static Future<T?> navigateAndClearStack<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TransitionType? transition,
  }) async {
    final route = PageTransition(
      child: _getScreenWidget(routeName),
      type: transition ?? TransitionType.smoothFadeSlide,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      settings: RouteSettings(name: routeName, arguments: arguments),
    );

    return Navigator.pushAndRemoveUntil<T>(
      context,
      route as Route<T>,
      (Route<dynamic> route) => false,
    );
  }

  /// Helper method to get screen widget by route name
  static Widget _getScreenWidget(String routeName) {
    // This is a simplified version - in a real app you might want to
    // use the same logic as in AppRouter.generateRoute
    switch (routeName) {
      case Routes.home:
        return Container(); // Replace with actual HomeScreen
      case Routes.settings:
        return Container(); // Replace with actual SettingScreen
      case Routes.profile:
        return Container(); // Replace with actual ProfileScreen
      case Routes.analytic:
        return Container(); // Replace with actual AnalyticScreen
      case Routes.expenses:
        return Container(); // Replace with actual AddExpenseScreen
      default:
        return const Scaffold(
          body: Center(
            child: Text('Screen not found'),
          ),
        );
    }
  }
}

/// Extension methods for Navigator for easier smooth transitions
extension NavigatorExtensions on BuildContext {
  /// Navigate with smooth slide transition
  Future<T?> navigateSlide<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) =>
      NavigationHelper.navigateWithSlide<T>(
        this,
        routeName,
        arguments: arguments,
        replace: replace,
      );

  /// Navigate with fade transition
  Future<T?> navigateFade<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) =>
      NavigationHelper.navigateWithFade<T>(
        this,
        routeName,
        arguments: arguments,
        replace: replace,
      );

  /// Navigate with scale transition
  Future<T?> navigateScale<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) =>
      NavigationHelper.navigateWithScale<T>(
        this,
        routeName,
        arguments: arguments,
        replace: replace,
      );

  /// Navigate as modal
  Future<T?> navigateModal<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) =>
      NavigationHelper.navigateModal<T>(
        this,
        routeName,
        arguments: arguments,
      );
}
