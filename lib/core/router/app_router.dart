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
  /// Enhanced navigation direction detection with smoother transitions
  static NavDirection _getNavigationDirection(
      String? fromRoute, String toRoute) {
    // Enhanced page hierarchy for better transition logic
    final pagePositions = {
      Routes.home: 0, // Main hub
      Routes.analytic: 1, // Right of home
      Routes.settings: 2, // Further right
      Routes.profile: 3, // Rightmost main screen
      Routes.expenses: 10, // Modal-style (special handling)
      Routes.splash: -10, // Initial screen
      Routes.login: -5, // Auth screen
    };

    // Handle special cases first
    if (toRoute == Routes.expenses) {
      return NavDirection.forward; // Always slide up for modal
    }

    // Default to forward for unknown routes
    if (fromRoute == null ||
        !pagePositions.containsKey(fromRoute) ||
        !pagePositions.containsKey(toRoute)) {
      return NavDirection.forward;
    }

    final fromPosition = pagePositions[fromRoute]!;
    final toPosition = pagePositions[toRoute]!;

    // Enhanced logic for smoother transitions
    if (toPosition > fromPosition) {
      return NavDirection.forward;
    } else {
      return NavDirection.backward;
    }
  }

  /// Get appropriate transition type based on screen context
  static TransitionType _getTransitionForScreen(
      String? routeName, NavDirection direction) {
    switch (routeName) {
      case Routes.splash:
        return TransitionType.smoothFadeSlide;
      case Routes.login:
        return TransitionType.materialPageRoute;
      case Routes.expenses:
        return TransitionType.slideAndFadeVertical;
      case Routes.home:
        // Use different transitions based on direction
        return direction == NavDirection.forward
            ? TransitionType.smoothSlideRight
            : TransitionType.smoothSlideLeft;
      case Routes.analytic:
        return TransitionType.smoothFadeSlide;
      case Routes.profile:
        return TransitionType.smoothScale;
      case Routes.settings:
        return TransitionType.materialPageRoute;
      default:
        return direction == NavDirection.forward
            ? TransitionType.smoothSlideRight
            : TransitionType.smoothSlideLeft;
    }
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Get current route for direction calculation
    final fromRoute = navigatorKey.currentContext != null
        ? ModalRoute.of(navigatorKey.currentContext!)?.settings.name
        : null;

    final direction = _getNavigationDirection(fromRoute, settings.name ?? '');
    final transitionType = _getTransitionForScreen(settings.name, direction);

    // Special handling for expense screen (modal behavior)
    if (settings.name == Routes.expenses) {
      return PageTransition(
        child: const AddExpenseScreen(),
        type: TransitionType.slideAndFadeVertical,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        settings: settings,
      );
    }

    switch (settings.name) {
      case Routes.splash:
        return PageTransition(
          child: const SplashScreen(),
          type: TransitionType.smoothFadeSlide,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          settings: settings,
        );

      case Routes.login:
        return PageTransition(
          child: const LoginScreen(),
          type: TransitionType.materialPageRoute,
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
          settings: settings,
        );

      case Routes.home:
        return createRoute(
          const HomeScreen(),
          settings: settings,
          direction: direction,
          forwardTransition: TransitionType.smoothSlideRight,
          backwardTransition: TransitionType.smoothSlideLeft,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );

      case Routes.analytic:
        return PageTransition(
          child: const AnalyticScreen(),
          type: TransitionType.smoothFadeSlide,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
          settings: settings,
        );

      case Routes.profile:
        return PageTransition(
          child: const ProfileScreen(),
          type: TransitionType.smoothScale,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutBack,
          settings: settings,
        );

      case Routes.settings:
        return PageTransition(
          child: const SettingScreen(),
          type: TransitionType.materialPageRoute,
          duration: const Duration(milliseconds: 350),
          curve: Curves.fastOutSlowIn,
          settings: settings,
        );

      default:
        return PageTransition(
          child: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Page Not Found',
                    style: Theme.of(navigatorKey.currentContext!)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No route defined for ${settings.name}',
                    style: Theme.of(navigatorKey.currentContext!)
                        .textTheme
                        .bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          type: TransitionType.smoothFadeSlide,
          settings: settings,
        );
    }
  }
}

/// Global navigation key for accessing Navigator without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
