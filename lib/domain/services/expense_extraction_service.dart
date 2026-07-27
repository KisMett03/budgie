import 'dart:async';
import 'package:flutter/foundation.dart';

import '../entities/category.dart' as app_category;
import '../../data/models/expense_detection_models.dart';
import '../../data/infrastructure/services/gemini_api_client.dart';
import '../../data/infrastructure/services/notification_service.dart';

/// Abstract interface for expense detail extraction using hybrid approach
/// Classification uses local TensorFlow models, extraction uses API backend
abstract class ExpenseExtractionService {
  /// Classify if notification contains expense data using local TensorFlow model
  Future<bool> classifyNotification({
    required String title,
    required String content,
    String? source,
    String? packageName,
  });

  /// Extract detailed expense information from notification text using API backend
  /// This assumes the text has already been classified as containing expense data by local TensorFlow model
  Future<ExpenseExtractionResult?> extractExpenseDetails({
    required String title,
    required String content,
    required String source,
    String? packageName,
    Map<String, dynamic>? additionalContext,
    required List<String> availableCategories,
  });

  /// Check if the services (local TensorFlow model and API backend) are healthy
  Future<bool> isHealthy();
}

/// Domain service for hybrid expense detail extraction
///
/// This service handles the business logic for extracting detailed expense information
/// from notification text using a hybrid approach:
/// 1. Local TensorFlow model for classification (determines if notification contains expense data)
/// 2. API backend for detailed extraction (extracts structured expense information)
/// It defines what constitutes valid extracted data and how extraction should work.
///
/// Usage example:
/// ```dart
/// final service = serviceLocator<ExpenseExtractionDomainService>();
/// await service.initialize();
///
/// // Option 1: Complete hybrid processing (recommended)
/// final result = await service.processNotification(
///   title: "Payment Notification",
///   content: "You spent RM15.50 at McDonald's via card",
///   source: "banking_app",
///   packageName: "com.maybank.app",
/// );
///
/// // Option 2: Step-by-step processing
/// final isExpense = await service.classifyNotification(
///   title: "Payment Notification",
///   content: "You spent RM15.50 at McDonald's via card",
///   source: "banking_app",
/// );
/// if (isExpense) {
///   final result = await service.extractExpenseDetails(
///     notificationText: "Payment Notification: You spent RM15.50 at McDonald's via card",
///     source: "banking_app",
///   );
/// }
/// ```
class ExpenseExtractionDomainService {
  ExpenseExtractionDomainService({
    required ExpenseExtractionService extractionService,
    required NotificationService notificationService,
    required GeminiApiClient apiClient,
  })  : _extractionService = extractionService,
        _notificationService = notificationService,
        _apiClient = apiClient;

  // Dependencies (injected from infrastructure)
  final ExpenseExtractionService _extractionService;
  final NotificationService _notificationService;
  final GeminiApiClient _apiClient;
  bool _isInitialized = false;

  // Business rules and configuration
  static const double _minimumConfidenceThreshold = 0.5;
  static const Duration _maxProcessingTime = Duration(seconds: 10);

  /// Initialize the expense extraction service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🤖 ExpenseExtractionDomainService: Initializing...');

      // Initialize GeminiApiClient with connectivity service
      try {
        await _apiClient.initialize(modelPreset: 'gemma3_27b');
        debugPrint(
            '✅ ExpenseExtractionDomainService: Gemini API client initialized');
      } catch (e) {
        debugPrint('expense_extraction_service: Diagnostic output redacted');
      }

      // Verify extraction service is healthy
      final isHealthy = await _extractionService.isHealthy();
      if (!isHealthy) {
        debugPrint(
            '⚠️ ExpenseExtractionDomainService: Extraction service is not healthy');
      }

      _isInitialized = true;
      debugPrint('✅ ExpenseExtractionDomainService: Initialization completed');
    } catch (_) {
      debugPrint('ExpenseExtractionDomainService: Initialization failed');
      // Service should fail gracefully if models are not available
      _isInitialized = true;
    }
  }

  /// Classify notification using TFLite model
  Future<bool> classifyNotification({
    required String title,
    required String content,
    String? source,
    String? packageName,
  }) async {
    if (title.trim().isEmpty && content.trim().isEmpty) {
      debugPrint('🤖 ExpenseExtractionDomainService: Empty notification text');
      return false;
    }

    try {
      await _ensureInitialized();

      debugPrint('expense_extraction_service: Diagnostic output redacted');

      final result = await _extractionService.classifyNotification(
        title: title,
        content: content,
        source: source,
        packageName: packageName,
      );

      debugPrint('expense_extraction_service: Diagnostic output redacted');
      return result;
    } catch (_) {
      debugPrint('ExpenseExtractionDomainService: Classification failed');
      return false;
    }
  }

  /// Complete hybrid processing: classify notification and extract details if needed
  /// Returns ExpenseExtractionResult if notification is classified as expense and extraction succeeds
  /// Returns null if notification is not an expense or extraction fails
  Future<ExpenseExtractionResult?> processNotification({
    required String title,
    required String content,
    required String source,
    String? packageName,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      await _ensureInitialized();

      // Step 1: Classify notification using local TensorFlow model
      final isExpense = await classifyNotification(
        title: title,
        content: content,
        source: source,
        packageName: packageName,
      );

      if (!isExpense) {
        debugPrint(
            '🤖 ExpenseExtractionDomainService: Notification classified as non-expense, skipping extraction');
        return null;
      }

      // Step 2: Extract expense details using API
    // ignore: unused_local_variable
    final notificationText = title.isNotEmpty && content.isNotEmpty
      ? '$title: $content'
      : (title.isNotEmpty ? title : content);

      return await extractExpenseDetails(
        title: title,
        content: content,
        source: source,
        packageName: packageName,
        additionalContext: additionalContext,
      );
    } catch (_) {
      debugPrint('ExpenseExtractionDomainService: Processing failed');
      return null;
    }
  }

  /// Extract detailed expense information from notification text
  /// Returns the raw ExpenseExtractionResult if extraction is successful, null otherwise
  /// Also records API extraction data for model improvement if enabled
  /// NOTE: This assumes the notification has already been classified as containing expense data
  Future<ExpenseExtractionResult?> extractExpenseDetails({
    required String title,
    required String content,
    required String source,
    String? packageName,
    Map<String, dynamic>? additionalContext,
  }) async {
    if (title.trim().isEmpty && content.trim().isEmpty) {
      debugPrint('🤖 ExpenseExtractionDomainService: Empty notification text');
      return null;
    }

    try {
      await _ensureInitialized();

      debugPrint('expense_extraction_service: Diagnostic output redacted');
      debugPrint('ExpenseExtractionDomainService: Extraction request started');

      final startTime = DateTime.now();

      // Get available categories for analysis
      final availableCategories = _getAvailableCategories();

      // Delegate to API extraction service
      final extractionResult = await _extractionService.extractExpenseDetails(
        title: title,
        content: content,
        source: source,
        packageName: packageName,
        additionalContext: additionalContext,
        availableCategories: availableCategories,
      );

      final processingTime = DateTime.now().difference(startTime);

      // Apply business rules to validate the extraction result
      final validatedResult =
          _validateExtractionResult(extractionResult, processingTime);

      if (validatedResult != null) {
        debugPrint('expense_extraction_service: Diagnostic output redacted');

        // Record the detection and send actionable notification
        await _recordAndNotify(
          result: validatedResult,
          title: title,
          content: content,
          source: source,
          packageName: packageName ?? 'unknown',
        );

        return validatedResult;
      }

      debugPrint(
          '🔍 ExpenseExtractionDomainService: Extraction validation failed');
      return null;
    } catch (_) {
      debugPrint('ExpenseExtractionDomainService: Extraction failed');
      return null;
    }
  }

  // Private business logic methods

  /// Send actionable notification for detected expense
  Future<void> _recordAndNotify({
    required ExpenseExtractionResult result,
    required String title,
    required String content,
    required String source,
    required String packageName,
  }) async {
    try {
      // Generate a simple detection ID for notification payload
      final detectionId = DateTime.now().millisecondsSinceEpoch.toString();

      await _notificationService.sendExpenseDetectedNotification(
        detectionId: detectionId,
        extractionResult: result,
      );
    } catch (_) {
      debugPrint('ExpenseExtractionDomainService: Failed to send notification');
    }
  }

  /// Validate API extraction result against business rules
  ExpenseExtractionResult? _validateExtractionResult(
    ExpenseExtractionResult? extractionResult,
    Duration processingTime,
  ) {
    if (extractionResult == null) {
      debugPrint('🔍 ExpenseExtractionDomainService: API returned null result');
      return null;
    }

    // Business Rule 1: Must meet minimum confidence threshold
    if (extractionResult.confidence < _minimumConfidenceThreshold) {
      debugPrint('expense_extraction_service: Diagnostic output redacted');
      return null;
    }

    // Business Rule 2: Must have essential data (amount or merchant)
    if (!extractionResult.hasEssentialData) {
      debugPrint(
          '🔍 ExpenseExtractionDomainService: Missing essential data (amount or merchant)');
      return null;
    }

    // Business Rule 3: Processing time should be reasonable
    if (processingTime > _maxProcessingTime) {
      debugPrint('expense_extraction_service: Diagnostic output redacted');
      // Don't reject, just warn for API calls
    }

    debugPrint(
        '✅ ExpenseExtractionDomainService: Extraction result validated successfully');
    return extractionResult;
  }

  /// Get available expense categories for analysis
  List<String> _getAvailableCategories() {
    return app_category.Category.values
        .map((cat) => cat.id.toLowerCase())
        .toList();
  }

  /// Extract title from notification text (simple heuristic)
  // ignore: unused_element
  String _extractTitleFromText(String notificationText) {
    // If text contains a colon, assume everything before it is the title
    if (notificationText.contains(':')) {
      return notificationText.split(':').first.trim();
    }
    // Otherwise, take first line or first 50 characters
    final lines = notificationText.split('\n');
    if (lines.isNotEmpty && lines.first.length <= 50) {
      return lines.first.trim();
    }
    return notificationText.length > 50
        ? '${notificationText.substring(0, 50).trim()}...'
        : notificationText.trim();
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Check if service is properly initialized
  bool get isInitialized => _isInitialized;

  /// Clean up resources
  void dispose() {
    _isInitialized = false;
    debugPrint('🤖 ExpenseExtractionDomainService: Disposed');
  }
}
