import 'package:flutter/material.dart';

class DropdownTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabelBuilder;

  const DropdownTile({
    Key? key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabelBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(title, style: const TextStyle(fontSize: 16)),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<T>(
              value: value,
              onChanged: onChanged,
              underline: Container(),
              icon: Icon(Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary),
              isDense: true,
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabelBuilder(item),
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          indent: 18,
          endIndent: 25,
          color: Theme.of(context).dividerColor,
        ),
      ],
    );
  }
}
