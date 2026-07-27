import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../models/exceptions.dart';
import '../network/connectivity_service.dart';
import '../../models/expense_detection_models.dart';
import '../../models/budget_reallocation_models.dart';
import '../../models/spending_behavior_models.dart';

/// HTTP client for communicating with BudgieAI FastAPI backend
///
/// This service handles all communication with the BudgieAI FastAPI backend following clean architecture principles.
/// It provides a centralized, type-safe way to interact with AI-powered services through RESTful APIs.
class GeminiApiClient {
  GeminiApiClient({
    required http.Client client,
    required ConnectivityService connectivityService,
  })  : _client = client,
        _connectivityService = connectivityService;

  //         ? 'http://10.0.2.2:8000'
  //         : 'http://localhost:8000'

  static String get _apiBaseUrl =>
      '${AppConfig.apiBaseUrl}/${AppConfig.apiVersion}';

  // Timeouts
  static const Duration _receiveTimeout = Duration(seconds: 180);

  // HTTP Client
  final http.Client _client;
  final ConnectivityService _connectivityService;
  bool _isInitialized = false;

  /// Initialize the HTTP client service
  Future<void> initialize({
    String? modelPreset,
    Map<String, dynamic>? customConfig,
    List<Map<String, dynamic>>? customSafetySettings,
  }) async {
    if (_isInitialized) return;

    try {
      debugPrint('🤖 BudgieApiClient: Initializing HTTP client...');
      _isInitialized = true;
      debugPrint('🤖 BudgieApiClient: Initialized successfully');
    } catch (_) {
      debugPrint('BudgieApiClient: Initialization failed');
      throw AIApiException(
        'Failed to initialize BudgieAI API client: $e',
        code: 'CLIENT_INIT_ERROR',
      );
    }
  }

  /// Check network connectivity
  Future<bool> _hasConnection() async {
    return await _connectivityService.isConnected;
  }

  /// Generic API request handler with error handling
  Future<Map<String, dynamic>> _makeRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    // Check connectivity
    if (!await _hasConnection()) {
      throw AIApiException('No internet connection available',
          code: 'NO_CONNECTIVITY');
    }

    final url = Uri.parse('$_apiBaseUrl$endpoint');
    if (AppConfig.enableVerboseLogging && kDebugMode) {
      debugPrint('gemini_api_client: Diagnostic output redacted');
    }
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client
              .get(url, headers: defaultHeaders)
              .timeout(timeout ?? _receiveTimeout);
          break;
        case 'POST':
          response = await _client
              .post(
                url,
                headers: defaultHeaders,
                body: body != null ? json.encode(body) : null,
              )
              .timeout(timeout ?? _receiveTimeout);
          break;
        default:
          throw AIApiException('Unsupported HTTP method: $method');
      }
    } on SocketException {
      throw AIApiException('Network error: Unable to connect to server',
          code: 'NETWORK_ERROR');
    } on HttpException {
      throw AIApiException('HTTP error', code: 'HTTP_ERROR');
    } on TimeoutException {
      throw AIApiException('Request timeout: Server took too long to respond',
          code: 'TIMEOUT');
    } catch (_) {
      throw AIApiException('Unexpected API error', code: 'UNKNOWN_ERROR');
    }

    return _handleResponse(response);
  }

  /// Handle API response and errors
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    try {
      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (statusCode >= 200 && statusCode < 300) {
        return responseData;
      } else {
        throw AIApiException(
          _extractErrorMessage(responseData, statusCode),
          code: 'API_ERROR',
          statusCode: statusCode,
          details: {'statusCode': statusCode},
        );
      }
    } catch (e) {
      if (e is AIApiException) rethrow;
      throw AIApiException('Failed to parse server response',
          code: 'PARSE_ERROR');
    }
  }

  String _extractErrorMessage(Map<String, dynamic> data, int statusCode) {
    if (data.containsKey('detail')) {
      if (data['detail'] is String) {
        return data['detail'];
      } else if (data['detail'] is List) {
        return (data['detail'] as List).map((e) => e['msg']).join(', ');
      }
    }
    return 'Server error (HTTP $statusCode)';
  }

  /// Extract expense from notification using FastAPI backend
  Future<Map<String, dynamic>> extractExpenseFromNotification({
    required NotificationApiRequest request,
  }) async {
    try {
      await _ensureInitialized();

      debugPrint('🤖 BudgieApiClient: Extracting expense from notification...');
      // Use the structured request model directly
      final requestBody = request.toJson();

      final response = await _makeRequest(
        '/expense-detection/extract',
        'POST',
        body: requestBody,
        timeout: const Duration(seconds: 30),
      );

      debugPrint(
          '🤖 BudgieApiClient: Expense extraction response received successfully');
      return response;
    } catch (_) {
      debugPrint('BudgieApiClient: Expense extraction request failed');
      rethrow;
    }
  }

  /// Analyze budget reallocation using FastAPI backend
  Future<Map<String, dynamic>> analyzeBudgetReallocation({
    required BudgetReallocationRequest request,
  }) async {
    try {
      await _ensureInitialized();

      debugPrint('🤖 BudgieApiClient: Analyzing budget reallocation...');

      final response = await _makeRequest(
        '/budget-reallocation/analyze',
        'POST',
        body: request.toJson(),
        timeout: const Duration(seconds: 120),
      );

      debugPrint(
          '🤖 BudgieApiClient: Budget reallocation response received successfully');
      return response;
    } catch (_) {
      debugPrint('BudgieApiClient: Budget reallocation request failed');
      rethrow;
    }
  }

  /// Analyze spending behavior using FastAPI backend
  Future<Map<String, dynamic>> analyzeSpendingBehavior({
    required SpendingBehaviorAnalysisRequest request,
  }) async {
    try {
      await _ensureInitialized();

      debugPrint('🤖 BudgieApiClient: Analyzing spending behavior...');

      final response = await _makeRequest(
        '/spending-behavior/analyze',
        'POST',
        body: request.toJson(),
        timeout: const Duration(seconds: 90),
      );

      debugPrint(
          '🤖 BudgieApiClient: Spending behavior response received successfully');
      return response;
    } catch (_) {
      debugPrint('BudgieApiClient: Spending behavior request failed');
      rethrow;
    }
  }

  /// Check service health for all endpoints
  Future<Map<String, bool>> checkServicesHealth() async {
    try {
      await _ensureInitialized();

      final healthStatus = <String, bool>{};

      // Check expense detection health
      try {
        final expenseHealthResponse = await _makeRequest(
          '/expense-detection/health',
          'GET',
          timeout: const Duration(seconds: 10),
        );
        healthStatus['expense_detection'] =
            expenseHealthResponse['status'] == 'healthy';
      } catch (e) {
        healthStatus['expense_detection'] = false;
      }

      // Check budget reallocation health
      try {
        final budgetHealthResponse = await _makeRequest(
          '/budget-reallocation/health',
          'GET',
          timeout: const Duration(seconds: 10),
        );
        healthStatus['budget_reallocation'] =
            budgetHealthResponse['status'] == 'healthy';
      } catch (e) {
        healthStatus['budget_reallocation'] = false;
      }

      // Check spending behavior health
      try {
        final behaviorHealthResponse = await _makeRequest(
          '/spending-behavior/health',
          'GET',
          timeout: const Duration(seconds: 10),
        );
        healthStatus['spending_behavior'] =
            behaviorHealthResponse['status'] == 'healthy';
      } catch (e) {
        healthStatus['spending_behavior'] = false;
      }

      return healthStatus;
    } catch (_) {
      debugPrint('BudgieApiClient: Service health check failed');
      return {
        'expense_detection': false,
        'budget_reallocation': false,
        'spending_behavior': false,
      };
    }
  }

  /// Generate structured response (maintained for backward compatibility)
  @Deprecated('Use specific endpoint methods instead')
  Future<Map<String, dynamic>> generateStructuredResponse({
    required String prompt,
    required Map<String, dynamic> responseSchema,
    List<dynamic>? additionalParts,
    String? modelPreset,
    Duration? timeout,
  }) async {
    throw UnsupportedError(
        'generateStructuredResponse is deprecated. Use specific endpoint methods like extractExpenseFromNotification, analyzeBudgetReallocation, or analyzeSpendingBehavior instead.');
  }

  /// Check if the service is properly initialized
  bool get isInitialized => _isInitialized;

  /// Get the current API base URL
  String get currentApiUrl => _apiBaseUrl;

  /// Reset the service (useful for testing or changing configurations)
  void reset() {
    _isInitialized = false;
    debugPrint('🤖 BudgieApiClient: Service reset');
  }

  // Private helper methods

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
    _isInitialized = false;
    debugPrint('🤖 BudgieApiClient: Disposed');
  }
}
