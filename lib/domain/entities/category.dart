/// 定义应用中所有可用的类别
enum Category {
  food,
  transportation,
  rental,
  utilities,
  shopping,
  entertainment,
  education,
  travel,
  medical,
  others,
}

/// 类别相关扩展方法
extension CategoryExtension on Category {
  /// 获取类别的字符串标识符
  String get id {
    return toString().split('.').last;
  }

  /// 从字符串ID创建类别
  static Category? fromId(String id) {
    try {
      return Category.values.firstWhere(
        (category) => category.id == id,
      );
    } catch (e) {
      return null;
    }
  }
}
