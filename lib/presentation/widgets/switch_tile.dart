import 'package:flutter/material.dart';

class SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchTile({
    Key? key,
    required this.title,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(title, style: const TextStyle(fontSize: 16)),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFF57C00),
          ),
        ),
        const Divider(height: 1, thickness: 1, indent: 18, endIndent: 25),
      ],
    );
  }
}