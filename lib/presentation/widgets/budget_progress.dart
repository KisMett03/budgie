import 'package:flutter/material.dart';

/// A widget to display budget allocation progress
class BudgetProgress extends StatelessWidget {
  final double? totalBudget;
  final double allocatedBudget;
  final Color? themeColor;

  const BudgetProgress({
    Key? key,
    required this.totalBudget,
    required this.allocatedBudget,
    this.themeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).primaryColor;
    final color = themeColor ?? defaultColor;

    final allocatedPercentage = totalBudget != null && totalBudget! > 0
        ? (allocatedBudget / totalBudget! * 100).clamp(0, 100)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Allocated Budget'),
            Text(
              '${allocatedBudget.toStringAsFixed(2)} / ${totalBudget?.toStringAsFixed(2) ?? '0.00'} MYR',
              style: TextStyle(
                color: allocatedPercentage > 100
                    ? Colors.red
                    : allocatedPercentage == 100
                        ? Colors.green
                        : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: totalBudget != null && totalBudget! > 0
                ? (allocatedBudget / totalBudget!).clamp(0, 1)
                : 0,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              allocatedPercentage > 100
                  ? Colors.red
                  : allocatedPercentage == 100
                      ? Colors.green
                      : color,
            ),
          ),
        ),
      ],
    );
  }
}
