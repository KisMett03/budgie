# Budgie App - 组件库

本文档总结了Budgie应用中的可重用组件和工具类，以帮助开发者更好地理解和使用这些组件。

## 工具类

### AppTheme

`lib/presentation/utils/app_theme.dart`

集中管理应用的主题样式，包括颜色、字体、圆角半径等。提供了亮色和暗色两种主题。

```dart
// 使用示例
final primaryColor = AppTheme.primaryColor;
final themeData = AppTheme.lightTheme;
```

### AppConstants

`lib/presentation/utils/app_constants.dart`

集中管理应用中的常量，包括货币列表、支付方式、日期格式、消息文本等。

```dart
// 使用示例
final currencies = AppConstants.currencies;
final dateFormat = AppConstants.dateFormat;
```

### CategoryManager

`lib/presentation/utils/category_manager.dart`

统一的类别管理工具类，提供类别相关的颜色、图标、名称等属性和方法。

```dart
// 使用示例
final color = CategoryManager.getColor(Category.food);
final icon = CategoryManager.getIcon(Category.food);
final name = CategoryManager.getName(Category.food);

// 从ID获取类别
final category = CategoryManager.getCategoryFromId('food');

// 获取所有类别
final allCategories = CategoryManager.allCategories;
```

## 类别系统

应用使用统一的类别系统，定义在 `lib/domain/entities/category.dart` 文件中：

```dart
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
```

类别系统的主要优点：
- 统一管理所有类别的颜色、图标和名称
- 易于添加、移除或修改类别
- 支持在不同场景下过滤类别
- 通过字符串ID支持在预算和其他需要字符串键的地方使用

详细说明请参考 `lib/domain/entities/README.md`。

## 可重用组件

### CustomTextField

`lib/presentation/widgets/custom_text_field.dart`

通用的文本输入字段组件，支持多种类型的输入，如普通文本、数字、货币等。

```dart
// 基本使用
CustomTextField(
  labelText: '标签',
  prefixIcon: Icons.person,
  isRequired: true,
)

// 数字输入
CustomTextField.number(
  labelText: '金额',
  allowDecimal: true,
  isRequired: true,
)

// 货币输入
CustomTextField.currency(
  labelText: '预算',
  currencySymbol: 'MYR',
  isRequired: true,
)
```

### CustomDropdownField

`lib/presentation/widgets/custom_dropdown_field.dart`

通用的下拉选择器组件，可用于选择货币、支付方式等。

```dart
CustomDropdownField<String>(
  value: selectedValue,
  items: itemsList,
  labelText: '标签',
  onChanged: (value) => setState(() => selectedValue = value!),
  itemLabelBuilder: (item) => item,
  prefixIcon: Icons.payment,
)
```

### DateTimePickerField

`lib/presentation/widgets/date_time_picker_field.dart`

日期和时间选择器组件，提供日期和时间的选择功能，以及"当前时间"按钮。

```dart
DateTimePickerField(
  dateTime: selectedDateTime,
  onDateChanged: (date) => setState(() => selectedDateTime = date),
  onTimeChanged: (time) => setState(() => selectedDateTime = time),
  onCurrentTimePressed: () => setState(() => selectedDateTime = DateTime.now()),
)
```

### CategorySelector

`lib/presentation/widgets/category_selector.dart`

类别选择器组件，用于选择类别，显示类别图标和名称。

```dart
CategorySelector(
  selectedCategory: selectedCategory,
  onCategorySelected: (category) => setState(() => selectedCategory = category),
  // 可选：过滤类别
  categories: [Category.food, Category.entertainment, Category.others],
)
```

### SubmitButton

`lib/presentation/widgets/submit_button.dart`

提交按钮组件，支持加载状态和图标。

```dart
SubmitButton(
  text: '保存',
  loadingText: '保存中...',
  isLoading: isSubmitting,
  onPressed: submit,
  icon: Icons.save,
)
```

### CustomCard

`lib/presentation/widgets/custom_card.dart`

自定义卡片组件，提供一致的卡片样式，支持点击事件、标题和操作按钮。

```dart
// 基本卡片
CustomCard(
  child: Text('内容'),
  onTap: () => print('点击了卡片'),
)

// 带标题的卡片
CustomCard.withTitle(
  title: '标题',
  icon: Icons.info,
  child: Text('内容'),
)

// 带操作按钮的卡片
CustomCard.withAction(
  child: Text('内容'),
  actionText: '查看更多',
  onActionPressed: () => print('点击了操作按钮'),
)
```

## 示例页面

### AddExpenseScreen

`lib/presentation/screens/add_expense_screen.dart`

添加支出页面，展示了如何使用各种可重用组件构建表单页面。

### AddBudgetScreen

`lib/presentation/screens/add_budget_screen.dart`

添加预算页面，展示了如何使用各种可重用组件构建表单页面，以及如何使用ValueNotifier管理状态。

## 使用建议

1. 优先使用可重用组件，而不是重新创建类似功能的组件
2. 遵循应用的主题和样式指南，使用AppTheme中定义的颜色和样式
3. 使用AppConstants中定义的常量，而不是硬编码字符串
4. 使用CategoryManager管理所有类别相关的操作
5. 如果需要创建新的可重用组件，请遵循现有组件的设计模式和命名规范 