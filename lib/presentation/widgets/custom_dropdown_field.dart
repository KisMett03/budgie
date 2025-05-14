import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// 自定义下拉选择器组件
class CustomDropdownField<T> extends StatelessWidget {
  /// 当前选择的值
  final T value;

  /// 可选项列表
  final List<T> items;

  /// 标签文本
  final String labelText;

  /// 值变更回调
  final Function(T?) onChanged;

  /// 项目标签构建器
  final String Function(T) itemLabelBuilder;

  /// 前缀图标
  final IconData? prefixIcon;

  /// 是否必填
  final bool isRequired;

  /// 验证器
  final String? Function(T?)? validator;

  /// 边框圆角
  final double borderRadius;

  const CustomDropdownField({
    Key? key,
    required this.value,
    required this.items,
    required this.labelText,
    required this.onChanged,
    required this.itemLabelBuilder,
    this.prefixIcon,
    this.isRequired = false,
    this.validator,
    this.borderRadius = 15.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  itemLabelBuilder(item),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator ??
          (isRequired
              ? (value) => value == null ? 'Please select $labelText' : null
              : null),
      iconEnabledColor: Theme.of(context).colorScheme.primary,
      dropdownColor: Theme.of(context).cardColor,
    );
  }
}
