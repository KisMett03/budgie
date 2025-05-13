// lib/widgets/legend_card.dart
import 'package:flutter/material.dart';
import 'legend_item.dart';

class LegendCard extends StatelessWidget {
  final List<String> categories;

  const LegendCard({
    Key? key,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categories',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: categories.map((category) {
                return LegendItem(category: category);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
