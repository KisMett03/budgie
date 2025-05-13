import 'package:flutter/material.dart';
import '../../core/constants/routes.dart';

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
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Custom painted background with notch
          Positioned.fill(
            child: CustomPaint(
              painter: _NavBarPainter(),
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
                    switch (idx) {
                      case 0:
                        Navigator.pushReplacementNamed(context, Routes.home);
                        break;
                      case 1:
                        Navigator.pushReplacementNamed(context, Routes.analytic);
                        break;
                      case 2:
                        Navigator.pushReplacementNamed(context, Routes.settings);
                        break;
                      case 3:
                        Navigator.pushReplacementNamed(context, Routes.profile);
                        break;
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 18),
                      Icon(
                        icons[idx],
                        color: isSelected ? const Color(0xFFF57C00) : Colors.black54,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[idx],
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFF57C00) : Colors.black54,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFBFCF8)
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
      notchCenterX - notchRadius, notchTop,
      notchCenterX - notchRadius * 0.8, notchTop + notchRadius * 0.3,
    );
    path.arcToPoint(
      Offset(notchCenterX + notchRadius * 0.8, notchTop + notchRadius * 0.3),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.quadraticBezierTo(
      notchCenterX + notchRadius, notchTop,
      notchCenterX + notchRadius + 12, notchTop,
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
