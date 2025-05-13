import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A text field for currency input
class CurrencyTextField extends StatelessWidget {
  final String? initialValue;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final String? currencySymbol;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final String? errorText;

  const CurrencyTextField({
    Key? key,
    this.initialValue,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.currencySymbol = 'MYR',
    this.onChanged,
    this.validator,
    this.controller,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null
          ? initialValue
          : null, // Use initialValue only if controller is null
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.attach_money),
        suffixText: currencySymbol,
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}
