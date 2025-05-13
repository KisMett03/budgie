import 'package:flutter/material.dart';

/// A reusable widget for section headers with an icon and title
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final double iconSize;
  final TextStyle? titleStyle;

  const SectionHeader({
    Key? key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.iconSize = 28,
    this.titleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = Theme.of(context).primaryColor;

    return Row(
      children: [
        Icon(
          icon,
          color: iconColor ?? defaultColor,
          size: iconSize,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: titleStyle ??
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
