import 'package:flutter/material.dart';
import '../../core/constants/routes.dart';
import '../../core/router/app_router.dart';
import '../../core/router/page_transition.dart';
import '../../core/router/navigation_helper.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home,
      Icons.receipt_long,
      Icons.settings,
      Icons.person,
    ];
    final labels = [
      'Home',
      'Analytics',
      'Settings',
      'Profile',
    ];

    // Page routes mapping
    final routes = [
      Routes.home,
      Routes.analytic,
      Routes.settings,
      Routes.profile,
    ];

    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final backgroundColor = Theme.of(context).colorScheme.surface;

    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Custom painted background with notch
          Positioned.fill(
            child: CustomPaint(
              painter: _NavBarPainter(backgroundColor),
            ),
          ),
          // Enhanced nav bar icons with smooth animations
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (idx) {
                final isSelected = currentIndex == idx;
                return _buildNavItem(
                  context,
                  idx,
                  isSelected,
                  icons[idx],
                  labels[idx],
                  routes[idx],
                  primaryColor,
                  textColor,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    bool isSelected,
    IconData icon,
    String label,
    String route,
    Color primaryColor,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: () => _handleNavigation(context, index, route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(height: 18),
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                icon,
                color: isSelected ? primaryColor : textColor.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? primaryColor : textColor.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int targetIndex, String route) {
    // Don't navigate if already on the target tab
    if (currentIndex == targetIndex) {
      return;
    }

    // Update the tab index first for immediate visual feedback
    onTap(targetIndex);

    // Choose appropriate transition based on navigation direction and target
    _navigateWithSmoothTransition(context, targetIndex, route);
  }

  void _navigateWithSmoothTransition(
      BuildContext context, int targetIndex, String route) {
    // Determine transition type based on navigation pattern
    TransitionType transitionType;
    Duration duration;
    Curve curve;

    // Calculate navigation direction
    final isMovingRight = targetIndex > currentIndex;
    final distance = (targetIndex - currentIndex).abs();

    // Choose transition based on target screen and direction
    switch (targetIndex) {
      case 0: // Home
        transitionType = TransitionType.smoothSlideRight;
        duration = const Duration(milliseconds: 350);
        curve = Curves.easeInOutCubic;
        break;
      case 1: // Analytics
        transitionType = TransitionType.smoothFadeSlide;
        duration = const Duration(milliseconds: 400);
        curve = Curves.easeOutQuart;
        break;
      case 2: // Settings
        transitionType = TransitionType.materialPageRoute;
        duration = const Duration(milliseconds: 350);
        curve = Curves.fastOutSlowIn;
        break;
      case 3: // Profile
        transitionType = TransitionType.smoothScale;
        duration = const Duration(milliseconds: 450);
        curve = Curves.easeInOutBack;
        break;
      default:
        // Fallback based on direction
        transitionType = isMovingRight
            ? TransitionType.smoothSlideRight
            : TransitionType.smoothSlideLeft;
        duration = const Duration(milliseconds: 350);
        curve = Curves.easeInOutCubic;
    }

    // Adjust duration based on distance for larger jumps
    if (distance > 1) {
      duration =
          Duration(milliseconds: duration.inMilliseconds + (distance * 50));
    }

    // Navigate using the chosen transition
    Navigator.pushReplacementNamed(
      context,
      route,
    );
  }
}

class _NavBarPainter extends CustomPainter {
  final Color backgroundColor;

  _NavBarPainter(this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double notchRadius = 32;
    final double notchCenterX = size.width / 2;
    final double notchTop = 0;
    final double barHeight = size.height;

    final path = Path();
    path.moveTo(0, notchTop);
    // Left to notch
    path.lineTo(notchCenterX - notchRadius - 12, notchTop);
    // Notch curve
    path.quadraticBezierTo(
      notchCenterX - notchRadius,
      notchTop,
      notchCenterX - notchRadius * 0.8,
      notchTop + notchRadius * 0.3,
    );
    path.arcToPoint(
      Offset(notchCenterX + notchRadius * 0.8, notchTop + notchRadius * 0.3),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.quadraticBezierTo(
      notchCenterX + notchRadius,
      notchTop,
      notchCenterX + notchRadius + 12,
      notchTop,
    );
    // Right to end
    path.lineTo(size.width, notchTop);
    path.lineTo(size.width, barHeight);
    path.lineTo(0, barHeight);
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.15), 8, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
