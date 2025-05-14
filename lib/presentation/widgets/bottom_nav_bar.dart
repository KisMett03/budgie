import 'package:flutter/material.dart';
import '../../core/constants/routes.dart';
import '../../core/router/app_router.dart';
import '../../core/router/page_transition.dart';

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

    // 页面映射
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
          // Nav bar icons
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (idx) {
                final isSelected = currentIndex == idx;
                return GestureDetector(
                  onTap: () {
                    onTap(idx);
                    // 如果点击的是当前已选中的标签，不执行导航操作
                    if (currentIndex == idx) {
                      return;
                    }

                    // 决定动画方向
                    final Widget targetPage;

                    switch (idx) {
                      case 0:
                        targetPage = navigatorKey.currentContext!
                            .findAncestorWidgetOfExactType<MaterialApp>()!
                            .routes![Routes.home]!(context);
                        break;
                      case 1:
                        targetPage = navigatorKey.currentContext!
                            .findAncestorWidgetOfExactType<MaterialApp>()!
                            .routes![Routes.analytic]!(context);
                        break;
                      case 2:
                        targetPage = navigatorKey.currentContext!
                            .findAncestorWidgetOfExactType<MaterialApp>()!
                            .routes![Routes.settings]!(context);
                        break;
                      case 3:
                        targetPage = navigatorKey.currentContext!
                            .findAncestorWidgetOfExactType<MaterialApp>()!
                            .routes![Routes.profile]!(context);
                        break;
                      default:
                        return;
                    }

                    // 直接确定动画方向
                    TransitionType transitionType;

                    // 从左边前往右边 - 从右滑入
                    if (currentIndex < idx) {
                      transitionType = TransitionType.fadeAndSlideRight;
                    }
                    // 从右边前往左边 - 从左滑入
                    else {
                      transitionType = TransitionType.fadeAndSlideLeft;
                    }

                    // 使用自定义页面转换
                    Navigator.pushReplacement(
                      context,
                      PageTransition(
                        child: targetPage,
                        type: transitionType,
                        settings: RouteSettings(name: routes[idx]),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 18),
                      Icon(
                        icons[idx],
                        color: isSelected
                            ? primaryColor
                            : textColor.withOpacity(0.6),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[idx],
                        style: TextStyle(
                          color: isSelected
                              ? primaryColor
                              : textColor.withOpacity(0.6),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
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
