import 'package:flutter/material.dart';

/// A widget for entering category budget
class CategoryBudgetField extends StatelessWidget {
  final String category;
  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const CategoryBudgetField({
    Key? key,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.controller,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: category[0].toUpperCase() + category.substring(1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: Icon(
            icon,
            color: iconColor,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType: TextInputType.number,
        validator: validator ??
            (v) => (v == null || v.isEmpty) ? 'Please enter budget' : null,
        onChanged: onChanged,
      ),
    );
  }
}
