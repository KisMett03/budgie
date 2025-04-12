import 'package:flutter/material.dart';

/// A reusable SliverList that builds transaction items
/// You can pass in itemCount and a builder callback to customize each item.
class SilverList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  // Optionally, you can pass other arguments or data models here.

  const SilverList({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        itemBuilder,
        childCount: itemCount,
      ),
    );
  }
}
