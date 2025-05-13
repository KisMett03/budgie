import 'package:flutter/material.dart';
import 'month_display.dart';

/// A reusable date picker button that provides a consistent UI across the app
class DatePickerButton extends StatelessWidget {
  /// Current selected date
  final DateTime date;

  /// Theme color for the component
  final Color? themeColor;

  /// Prefix text to show before the date
  final String? prefix;

  /// Callback when date is changed
  final Function(DateTime) onDateChanged;

  /// First date available in picker
  final DateTime? firstDate;

  /// Last date available in picker
  final DateTime? lastDate;

  const DatePickerButton({
    Key? key,
    required this.date,
    required this.onDateChanged,
    this.themeColor,
    this.prefix,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveThemeColor = themeColor ?? Theme.of(context).primaryColor;
    final effectiveFirstDate = firstDate ?? DateTime(2020);
    final effectiveLastDate = lastDate ?? DateTime(2100);

    return GestureDetector(
      onTap: () => _showDatePicker(
          context, effectiveThemeColor, effectiveFirstDate, effectiveLastDate),
      child: MonthDisplay(
        date: date,
        themeColor: effectiveThemeColor,
        prefix: prefix,
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, Color themeColor,
      DateTime firstDate, DateTime lastDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Month',
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null &&
        (picked.year != date.year || picked.month != date.month)) {
      onDateChanged(picked);
    }
  }
}
