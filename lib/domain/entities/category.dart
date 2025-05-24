/// Defines all available categories in the application
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

/// Category-related extension methods
extension CategoryExtension on Category {
  /// Gets the string identifier for the category
  String get id {
    return toString().split('.').last;
  }

  /// Creates a category from a string ID
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
