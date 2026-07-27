import 'package:flutter/foundation.dart';
import '../../entities/budget.dart';
import '../../repositories/budget_repository.dart';
import '../../../data/infrastructure/services/currency_conversion_service.dart';

/// Use case for converting budget currency
class ConvertBudgetCurrencyUseCase {
  final BudgetRepository _budgetRepository;
  final CurrencyConversionService _currencyConversionService;

  // Flag to track if a currency conversion is in progress
  bool _isConvertingCurrency = false;

  ConvertBudgetCurrencyUseCase({
    required BudgetRepository budgetRepository,
    required CurrencyConversionService currencyConversionService,
  })  : _budgetRepository = budgetRepository,
        _currencyConversionService = currencyConversionService;

  /// Execute currency conversion for a budget
  Future<Budget?> execute(String monthId, String targetCurrency) async {
    try {
      final budget = await _budgetRepository.getBudget(monthId);

      // If no budget, return null
      if (budget == null) {
        debugPrint('ConvertBudgetCurrencyUseCase: Budget not found');
        return null;
      }

      // If already converting or currencies match, return existing budget
      if (_isConvertingCurrency) {
        debugPrint(
            'ConvertBudgetCurrencyUseCase: Conversion already in progress');
        return budget;
      }

      if (budget.currency == targetCurrency) {
        debugPrint(
            'ConvertBudgetCurrencyUseCase: Budget already uses target currency');
        return budget;
      }

      debugPrint('ConvertBudgetCurrencyUseCase: Conversion started');

      // Perform conversion
      final convertedBudget =
          await _convertBudget(budget, targetCurrency, monthId);

      if (convertedBudget != null) {
        debugPrint('ConvertBudgetCurrencyUseCase: Conversion completed');
      } else {
        debugPrint('ConvertBudgetCurrencyUseCase: Conversion failed');
      }

      return convertedBudget;
    } catch (_) {
      debugPrint('ConvertBudgetCurrencyUseCase: Currency conversion failed');
      // Reset the conversion flag in case of error to prevent deadlock
      _isConvertingCurrency = false;
      // Return the original budget on error
      try {
        return await _budgetRepository.getBudget(monthId);
      } catch (_) {
        debugPrint('ConvertBudgetCurrencyUseCase: Budget recovery failed');
        return null;
      }
    }
  }

  /// Convert budget to new currency
  Future<Budget?> _convertBudget(
      Budget budget, String newCurrency, String monthId) async {
    // Check if the currency is already the same
    if (budget.currency == newCurrency) {
      if (kDebugMode) {
        debugPrint(
            'ConvertBudgetCurrencyUseCase: Budget already uses target currency');
      }
      return budget;
    }

    // Check if a conversion is already in progress
    if (_isConvertingCurrency) {
      if (kDebugMode) {
        debugPrint('ConvertBudgetCurrencyUseCase: Duplicate conversion skipped');
      }
      return budget;
    }

    try {
      // Set the conversion flag to prevent duplicate conversions
      _isConvertingCurrency = true;

      if (kDebugMode) {
        debugPrint('ConvertBudgetCurrencyUseCase: Budget conversion started');
      }

      // Convert the budget using our enhanced CurrencyConversionService
      final oldCurrency = budget.currency;

      // Create a new Budget object with converted values
      final newCategories = <String, CategoryBudget>{};

      // Convert each category budget
      for (final entry in budget.categories.entries) {
        final categoryId = entry.key;
        final categoryBudget = entry.value;

        // Convert budget and left amounts
        final convertedCategoryBudget = await _currencyConversionService
            .convertCurrency(categoryBudget.budget, oldCurrency, newCurrency);

        final convertedCategoryLeft =
            await _currencyConversionService.convertCurrency(
                categoryBudget.left, oldCurrency, newCurrency);

        newCategories[categoryId] = CategoryBudget(
          budget: convertedCategoryBudget,
          left: convertedCategoryLeft,
        );

        if (kDebugMode) {
          debugPrint(
              'ConvertBudgetCurrencyUseCase: Category conversion completed');
        }
      }

      // Convert total, left, and saving amounts
      final convertedTotal = await _currencyConversionService.convertCurrency(
          budget.total, oldCurrency, newCurrency);

      final convertedLeft = await _currencyConversionService.convertCurrency(
          budget.left, oldCurrency, newCurrency);

      final convertedSaving = await _currencyConversionService.convertCurrency(
          budget.saving, oldCurrency, newCurrency);

      // Create the new budget with converted values
      final convertedBudget = Budget(
        total: convertedTotal,
        left: convertedLeft,
        categories: newCategories,
        saving: convertedSaving,
        currency: newCurrency,
      );

      if (kDebugMode) {
        debugPrint(
            'ConvertBudgetCurrencyUseCase: Aggregate conversion completed');
      }

      // Save the converted budget
      if (kDebugMode) {
        debugPrint('ConvertBudgetCurrencyUseCase: Saving converted budget');
      }
      await _budgetRepository.setBudget(monthId, convertedBudget);

      if (kDebugMode) {
        debugPrint('ConvertBudgetCurrencyUseCase: Converted budget saved');
      }

      return convertedBudget;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('ConvertBudgetCurrencyUseCase: Budget conversion failed');
      }
      rethrow;
    } finally {
      // Reset the conversion flag
      _isConvertingCurrency = false;
    }
  }
}
