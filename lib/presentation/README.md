# Budgie App - Component Library

This document summarizes the reusable components and utility classes in the Budgie application to help developers better understand and use these components.

## Utility Classes

### AppTheme

`lib/presentation/utils/app_theme.dart`

Centrally manages the application's theme styles, including colors, fonts, border radius, etc. Provides both light and dark themes.

```dart
// Usage example
final primaryColor = AppTheme.primaryColor;
final themeData = AppTheme.lightTheme;
```

### AppConstants

`lib/presentation/utils/app_constants.dart`

Centrally manages constants in the application, including currency lists, payment methods, date formats, message texts, etc.

```dart
// Usage example
final currencies = AppConstants.currencies;
final dateFormat = AppConstants.dateFormat;
```

### CategoryManager

`lib/presentation/utils/category_manager.dart`

Unified category management utility class that provides category-related colors, icons, names, and other properties and methods.

```dart
// Usage example
final color = CategoryManager.getColor(Category.food);
final icon = CategoryManager.getIcon(Category.food);
final name = CategoryManager.getName(Category.food);

// Get category from ID
final category = CategoryManager.getCategoryFromId('food');

// Get all categories
final allCategories = CategoryManager.allCategories;
```

## Category System

The application uses a unified category system, defined in the `lib/domain/entities/category.dart` file:

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

Main advantages of the category system:
- Unified management of all category colors, icons, and names
- Easy to add, remove, or modify categories
- Supports filtering categories in different scenarios
- Supports use in budgets and other places that require string keys through string IDs

For detailed information, please refer to `lib/domain/entities/README.md`.

## Reusable Components

### CustomTextField

`lib/presentation/widgets/custom_text_field.dart`

Universal text input field component that supports multiple types of input, such as plain text, numbers, currency, etc.

```dart
// Basic usage
CustomTextField(
  labelText: 'Label',
  prefixIcon: Icons.person,
  isRequired: true,
)

// Number input
CustomTextField.number(
  labelText: 'Amount',
  allowDecimal: true,
  isRequired: true,
)

// Currency input
CustomTextField.currency(
  labelText: 'Budget',
  currencySymbol: 'MYR',
  isRequired: true,
)
```

### CustomDropdownField

`lib/presentation/widgets/custom_dropdown_field.dart`

Universal dropdown selector component that can be used to select currency, payment methods, etc.

```dart
CustomDropdownField<String>(
  value: selectedValue,
  items: itemsList,
  labelText: 'Label',
  onChanged: (value) => setState(() => selectedValue = value!),
  itemLabelBuilder: (item) => item,
  prefixIcon: Icons.payment,
)
```

### DateTimePickerField

`lib/presentation/widgets/date_time_picker_field.dart`

Date and time picker component that provides date and time selection functionality, as well as a "Current Time" button.

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

Category selector component used to select categories, displaying category icons and names.

```dart
CategorySelector(
  selectedCategory: selectedCategory,
  onCategorySelected: (category) => setState(() => selectedCategory = category),
  // Optional: filter categories
  categories: [Category.food, Category.entertainment, Category.others],
)
```

### SubmitButton

`lib/presentation/widgets/submit_button.dart`

Submit button component that supports loading states and icons.

```dart
SubmitButton(
  text: 'Save',
  loadingText: 'Saving...',
  isLoading: isSubmitting,
  onPressed: submit,
  icon: Icons.save,
)
```

### CustomCard

`lib/presentation/widgets/custom_card.dart`

Custom card component that provides consistent card styling, supports click events, titles, and action buttons.

```dart
// Basic card
CustomCard(
  child: Text('Content'),
  onTap: () => print('Card clicked'),
)

// Card with title
CustomCard.withTitle(
  title: 'Title',
  icon: Icons.info,
  child: Text('Content'),
)

// Card with action button
CustomCard.withAction(
  child: Text('Content'),
  actionText: 'View More',
  onActionPressed: () => print('Action button clicked'),
)
```

## Example Pages

### AddExpenseScreen

`lib/presentation/screens/add_expense_screen.dart`

Add expense page that demonstrates how to use various reusable components to build form pages.

### AddBudgetScreen

`lib/presentation/screens/add_budget_screen.dart`

Add budget page that demonstrates how to use various reusable components to build form pages, and how to use ValueNotifier to manage state.

## Usage Guidelines

1. Prioritize using reusable components instead of recreating similar functionality
2. Follow the application's theme and style guidelines, using colors and styles defined in AppTheme
3. Use constants defined in AppConstants instead of hardcoding strings
4. Use CategoryManager to manage all category-related operations
5. If you need to create new reusable components, please follow the design patterns and naming conventions of existing components 