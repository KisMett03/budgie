import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

/// 统一的类别管理工具类
class CategoryManager {
  /// 类别颜色映射
  static const Map<Category, Color> categoryColors = {
    Category.food: Color(0xFFF57C00), // 橙色
    Category.transportation: Color(0xFF3F51B5), // 靛蓝色
    Category.rental: Color(0xFF795548), // 棕色
    Category.utilities: Color(0xFF2196F3), // 蓝色
    Category.shopping: Color(0xFFE91E63), // 粉红色
    Category.entertainment: Color(0xFF9C27B0), // 紫色
    Category.education: Color(0xFF009688), // 青色
    Category.travel: Color(0xFF4CAF50), // 绿色
    Category.medical: Color(0xFFE91E63), // 粉红色
    Category.others: Color(0xFF607D8B), // 蓝灰色
  };

  /// 类别图标映射
  static const Map<Category, IconData> categoryIcons = {
    Category.food: Icons.restaurant,
    Category.transportation: Icons.directions_car,
    Category.rental: Icons.home,
    Category.utilities: Icons.power,
    Category.shopping: Icons.shopping_bag,
    Category.entertainment: Icons.movie,
    Category.education: Icons.school,
    Category.travel: Icons.flight_takeoff,
    Category.medical: Icons.local_hospital,
    Category.others: Icons.more_horiz,
  };

  /// 类别名称映射
  static const Map<Category, String> categoryNames = {
    Category.food: 'Food',
    Category.transportation: 'Transportation',
    Category.rental: 'Rental',
    Category.utilities: 'Utilities',
    Category.shopping: 'Shopping',
    Category.entertainment: 'Entertainment',
    Category.education: 'Education',
    Category.travel: 'Travel',
    Category.medical: 'Medical',
    Category.others: 'Others',
  };

  /// 获取所有可用的类别
  static List<Category> get allCategories => Category.values;

  /// 获取指定类别的颜色
  static Color getColor(Category category) =>
      categoryColors[category] ?? const Color(0xFF607D8B);

  /// 获取指定类别的图标
  static IconData getIcon(Category category) =>
      categoryIcons[category] ?? Icons.more_horiz;

  /// 获取指定类别的名称
  static String getName(Category category) =>
      categoryNames[category] ?? 'Unknown';

  /// 获取所有类别的详细信息
  static List<Map<String, dynamic>> getAllCategoriesDetails() {
    return allCategories.map((category) {
      return {
        'id': category.id,
        'name': getName(category),
        'icon': getIcon(category),
        'color': getColor(category),
      };
    }).toList();
  }

  /// 根据字符串ID获取类别
  static Category? getCategoryFromId(String id) {
    return CategoryExtension.fromId(id);
  }

  /// 根据字符串ID获取类别颜色
  static Color getColorFromId(String id) {
    final category = getCategoryFromId(id);
    return category != null ? getColor(category) : const Color(0xFF607D8B);
  }

  /// 根据字符串ID获取类别图标
  static IconData getIconFromId(String id) {
    final category = getCategoryFromId(id);
    return category != null ? getIcon(category) : Icons.more_horiz;
  }

  /// 根据字符串ID获取类别名称
  static String getNameFromId(String id) {
    final category = getCategoryFromId(id);
    return category != null
        ? getName(category)
        : id[0].toUpperCase() + id.substring(1);
  }

  /// 获取预算使用的类别ID列表
  static List<String> getBudgetCategoryIds() {
    // 可以根据需要过滤或调整类别列表
    return allCategories.map((category) => category.id).toList();
  }
}
