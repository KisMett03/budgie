# 统一类别系统

本文档说明了Budgie应用中统一的类别系统，以及如何使用和修改它。

## 类别定义

类别定义在 `lib/domain/entities/category.dart` 文件中，使用了Dart的枚举类型：

```dart
enum Category {
  food,
  transportation,
  rental,
  utilities,
  shopping,
  entertainment,
  health,
  education,
  travel,
  medical,
  others,
}
```

## 类别管理

类别的颜色、图标和名称等属性在 `lib/presentation/utils/category_manager.dart` 文件中定义：

```dart
class CategoryManager {
  static const Map<Category, Color> categoryColors = {
    Category.food: Color(0xFFF57C00), // 橙色
    // ... 其他类别颜色
  };

  static const Map<Category, IconData> categoryIcons = {
    Category.food: Icons.restaurant,
    // ... 其他类别图标
  };

  static const Map<Category, String> categoryNames = {
    Category.food: 'Food',
    // ... 其他类别名称
  };
  
  // ... 其他方法
}
```

## 如何修改类别

### 添加新类别

1. 在 `lib/domain/entities/category.dart` 文件中的 `Category` 枚举中添加新类别：

```dart
enum Category {
  food,
  // ... 其他类别
  newCategory, // 添加新类别
}
```

2. 在 `lib/presentation/utils/category_manager.dart` 文件中为新类别添加颜色、图标和名称：

```dart
static const Map<Category, Color> categoryColors = {
  // ... 现有类别
  Category.newCategory: Color(0xFF00BCD4), // 添加新类别颜色
};

static const Map<Category, IconData> categoryIcons = {
  // ... 现有类别
  Category.newCategory: Icons.new_releases, // 添加新类别图标
};

static const Map<Category, String> categoryNames = {
  // ... 现有类别
  Category.newCategory: 'New Category', // 添加新类别名称
};
```

### 移除类别

1. 从 `lib/domain/entities/category.dart` 文件中的 `Category` 枚举中移除类别：

```dart
enum Category {
  food,
  // ... 其他类别
  // 移除不需要的类别
}
```

2. 从 `lib/presentation/utils/category_manager.dart` 文件中的映射中移除相应的条目：

```dart
static const Map<Category, Color> categoryColors = {
  // ... 保留的类别
  // 移除不需要的类别
};

static const Map<Category, IconData> categoryIcons = {
  // ... 保留的类别
  // 移除不需要的类别
};

static const Map<Category, String> categoryNames = {
  // ... 保留的类别
  // 移除不需要的类别
};
```

### 修改类别属性

要修改类别的颜色、图标或名称，只需在 `lib/presentation/utils/category_manager.dart` 文件中更新相应的映射：

```dart
static const Map<Category, Color> categoryColors = {
  // ... 其他类别
  Category.food: Color(0xFFFF5722), // 修改食物类别的颜色
};

static const Map<Category, IconData> categoryIcons = {
  // ... 其他类别
  Category.food: Icons.fastfood, // 修改食物类别的图标
};

static const Map<Category, String> categoryNames = {
  // ... 其他类别
  Category.food: 'Meals', // 修改食物类别的名称
};
```

## 过滤类别

在某些情况下，您可能希望只显示部分类别。例如，在支出添加屏幕中，您可以通过以下方式过滤类别：

```dart
CategorySelector(
  selectedCategory: _selectedCategory,
  onCategorySelected: (category) {
    setState(() {
      _selectedCategory = category;
    });
  },
  // 只显示部分类别
  categories: [
    Category.food,
    Category.entertainment,
    Category.others,
  ],
)
```

## 预算类别

对于预算功能，您可以通过修改 `CategoryManager.getBudgetCategoryIds()` 方法来控制哪些类别可用于预算：

```dart
static List<String> getBudgetCategoryIds() {
  // 返回所有类别
  return allCategories.map((category) => category.id).toList();
  
  // 或者，返回过滤后的类别
  return [
    Category.food.id,
    Category.utilities.id,
    Category.rent.id,
    // ... 其他需要的类别
  ];
}
```

## 类别ID

类别ID是类别枚举值的字符串表示，用于在预算和其他需要字符串键的地方使用。例如，`Category.food` 的ID是 `"food"`。

您可以使用以下方法获取类别ID或从ID获取类别：

```dart
// 获取类别ID
String id = Category.food.id;

// 从ID获取类别
Category? category = CategoryManager.getCategoryFromId("food");
``` 