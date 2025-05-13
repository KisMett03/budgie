import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget to display the current budget month
class MonthDisplay extends StatelessWidget {
  final DateTime date;
  final Color? themeColor;
  final String? prefix;

  const MonthDisplay({
    Key? key,
    required this.date,
    this.themeColor,
    this.prefix = 'Budget for',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = themeColor ?? Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: effectiveColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: effectiveColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '$prefix ${DateFormat('MMMM yyyy').format(date)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
