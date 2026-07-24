import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../models/exceptions.dart';
import 'gemini_api_client.dart';
import '../network/connectivity_service.dart';
import '../../models/expense_detection_models.dart';
import '../../../domain/services/expense_extraction_service.dart';

/// Infrastructure implementation of Expense Extraction using hybrid approach
///
/// This service handles the technical details of:
/// 1. Local TensorFlow model classification (determines if notification contains expense data)
/// 2. FastAPI backend communication for detailed expense information extraction
/// Classification is done locally, extraction uses the BudgieAI FastAPI backend.
class ExpenseExtractionServiceImpl implements ExpenseExtractionService {
  ExpenseExtractionServiceImpl({
    required GeminiApiClient apiClient,
    required ConnectivityService connectivityService,
  })  : _apiClient = apiClient,
        _connectivityService = connectivityService;

  // Services
  final GeminiApiClient _apiClient;
  final ConnectivityService _connectivityService;
  bool _isInitialized = false;

  // TensorFlow Lite model components
  Interpreter? _interpreter;
  Map<String, int>? _vocabulary;

  // Model specifications
  static const int _titleMaxLength = 16;
  static const int _contentMaxLength = 64;
  static const double _confidenceThreshold = 0.5;
  static const String _modelPath =
      'assets/models/classifier/notification_classifier.tflite';
  static const String _vocabPath = 'assets/models/classifier/vocab_best.json';

  /// Initialize the FastAPI backend client
  @override
  Future<bool> isHealthy() async {
    try {
      if (!_isInitialized) {
        await _initialize();
      }

      if (!_isInitialized) return false;

      final healthStatus = await _apiClient.checkServicesHealth();
      return healthStatus['expense_detection'] == true;
    } catch (e) {
      debugPrint('🤖 ExpenseExtractionServiceImpl: Health check failed: $e');
      return false;
    }
  }

  /// Initialize the service with FastAPI backend client and TensorFlow Lite model
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint(
          '🤖 ExpenseExtractionServiceImpl: Initializing FastAPI client and TensorFlow model...');

      // Initialize the API client
      await _apiClient.initialize();

      // Initialize TensorFlow Lite model
      await _initializeTensorFlowModel();

      _isInitialized = true;
      debugPrint('✅ ExpenseExtractionServiceImpl: Initialization completed');
    } catch (e) {
      debugPrint('❌ ExpenseExtractionServiceImpl: Initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Initialize TensorFlow Lite model and vocabulary
  Future<void> _initializeTensorFlowModel() async {
    try {
      debugPrint(
          '🤖 ExpenseExtractionServiceImpl: Loading TensorFlow Lite model...');

      // Load the TensorFlow Lite model
      _interpreter = await Interpreter.fromAsset(_modelPath);

      debugPrint('🤖 ExpenseExtractionServiceImpl: Model loaded successfully');
      debugPrint('🤖 Input tensors: ${_interpreter!.getInputTensors()}');
      debugPrint('🤖 Output tensors: ${_interpreter!.getOutputTensors()}');

      // Load vocabulary
      final vocabJson = await rootBundle.loadString(_vocabPath);
      final vocabData = json.decode(vocabJson) as Map<String, dynamic>;
      _vocabulary = Map<String, int>.from(vocabData['word2idx'] as Map);

      debugPrint(
          '🤖 ExpenseExtractionServiceImpl: Vocabulary loaded with ${_vocabulary!.length} tokens');
    } catch (e) {
      debugPrint(
          '❌ ExpenseExtractionServiceImpl: Failed to load TensorFlow model: $e');
      rethrow;
    }
  }

  @override
  Future<bool> classifyNotification({
    required String title,
    required String content,
    String? source,
    String? packageName,
  }) async {
    try {
      await _ensureInitialized();

      if (_interpreter == null || _vocabulary == null) {
        debugPrint(
            '🤖 ExpenseExtractionServiceImpl: TensorFlow model not properly initialized, falling back to keyword classification');
        return _simpleKeywordClassification('$title: $content');
      }

      debugPrint(
          '🤖 ExpenseExtractionServiceImpl: Classifying notification using TensorFlow model');
      debugPrint('🤖 Title: "$title"');
      debugPrint('🤖 Content: "$content"');

      // Tokenize title and content
      final titleTokens = _tokenizeText(title, _titleMaxLength);
      final contentTokens = _tokenizeText(content, _contentMaxLength);

      debugPrint('🤖 Title tokens (${titleTokens.length}): $titleTokens');
      debugPrint('🤖 Content tokens (${contentTokens.length}): $contentTokens');

      // Prepare input tensors
      final titleInput = [Int32List.fromList(titleTokens)];
      final contentInput = [Int32List.fromList(contentTokens)];

      // Prepare output tensor
      final output = List.filled(1, 0.0).reshape([1, 1]);

      // Run inference
      _interpreter!
          .runForMultipleInputs([titleInput, contentInput], {0: output});

      final probability = output[0][0] as double;
      final isExpense = probability >= _confidenceThreshold;

      debugPrint(
          '🤖 ExpenseExtractionServiceImpl: TensorFlow classification result: $isExpense (probability: ${probability.toStringAsFixed(4)})');

      return isExpense;
    } catch (e) {
      debugPrint(
          '🤖 ExpenseExtractionServiceImpl: TensorFlow classification failed: $e');
      debugPrint('🤖 Falling back to keyword-based classification');

      // Fallback to simple classification
      final notificationText = title.isNotEmpty && content.isNotEmpty
          ? '$title: $content'
          : (title.isNotEmpty ? title : content);
      return _simpleKeywordClassification(notificationText);
    }
  }

  /// Tokenize text using the loaded vocabulary
  List<int> _tokenizeText(String text, int maxLength) {
    if (_vocabulary == null) {
      throw StateError('Vocabulary not loaded');
    }

    // Convert to lowercase and split into tokens
    final tokens = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\-\.\:\$]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();

    // Convert tokens to indices
    final indices = <int>[];
    for (final token in tokens) {
      if (indices.length >= maxLength) break;

      final index = _vocabulary![token] ?? _vocabulary!['<UNK>'] ?? 1;
      indices.add(index);
    }

    // Pad with <PAD> tokens (index 0) to reach maxLength
    while (indices.length < maxLength) {
      indices.add(0); // <PAD> token
    }

    return indices.take(maxLength).toList();
  }

  /// Placeholder keyword-based classification as fallback
  bool _simpleKeywordClassification(String text) {
    final expenseKeywords = [
      'spent',
      'purchase',
      'transaction',
      'payment',
      'charged',
      'debit',
      'rm',
      'myr',
      'ringgit',
      'card',
      'bank',
      'wallet',
      'pay',
      'buy',
      'bill',
      'receipt',
      'transfer',
      'withdraw',
      'shopping',
      'store'
    ];

    final lowerText = text.toLowerCase();
    return expenseKeywords.any((keyword) => lowerText.contains(keyword));
  }

  @override
  Future<ExpenseExtractionResult?> extractExpenseDetails({
    required String title,
    required String content,
    required String source,
    String? packageName,
    Map<String, dynamic>? additionalContext,
    required List<String> availableCategories,
  }) async {
    try {
      await _ensureInitialized();

      // Check network connectivity first
      if (!await _connectivityService.isConnected) {
        debugPrint(
            '🤖 ExpenseExtractionServiceImpl: No network connection available for extraction');
        return null;
      }

      debugPrint(
          '🤖 ExpenseExtractionServiceImpl: Extracting expense details from FastAPI...');

      if (title.trim().isEmpty && content.trim().isEmpty) {
        debugPrint('🤖 ExpenseExtractionServiceImpl: Empty notification text');
        return null;
      }

      // Create the structured API request object
      final apiRequest = NotificationApiRequest(
        title: title,
        content: content,
        timestamp: DateTime.now(),
        source: source,
        packageName: packageName,
      );

      // Call FastAPI backend with the request object
      final response = await _apiClient.extractExpenseFromNotification(
        request: apiRequest,
      );

      debugPrint(
          '✅ ExpenseExtractionServiceImpl: FastAPI response received: $response');

      if (response['success'] != true) {
        debugPrint(
            '❌ ExpenseExtractionServiceImpl: FastAPI extraction failed - success=false');
        return null;
      }

      // Check if response has extraction_result field or if data is directly in response
      Map<String, dynamic> extractionData;
      if (response.containsKey('extraction_result')) {
        // New format with extraction_result wrapper
        extractionData = response['extraction_result'] as Map<String, dynamic>;
      } else {
        // Direct format - extraction data is in the response itself
        extractionData = Map<String, dynamic>.from(response);
        // Remove non-extraction fields
        extractionData.remove('success');
        extractionData.remove('errorMessage');
      }

      // Convert FastAPI response to ExpenseExtractionResult
      return ExpenseExtractionResult.fromJson(extractionData);
    } catch (e) {
      debugPrint(
          '❌ ExpenseExtractionServiceImpl: FastAPI extraction failed: $e');
      if (e is AIApiException) {
        debugPrint('Details: ${e.details}');
      }
      return null;
    }
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initialize();
    }
  }

  /// Clean up resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _vocabulary = null;
    _isInitialized = false;
    debugPrint('🤖 ExpenseExtractionServiceImpl: Disposed');
  }
}
