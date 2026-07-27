import 'dart:async';
import 'package:flutter/foundation.dart';

import '../entities/expense.dart';
import '../entities/budget.dart';
import '../entities/financial_goal.dart';
import '../entities/user_behavior_profile.dart';
import '../../data/models/spending_behavior_models.dart';
import '../../data/models/exceptions.dart';
import '../../data/infrastructure/network/connectivity_service.dart';
import '../../data/infrastructure/services/gemini_api_client.dart';

/// Comprehensive service for analyzing user spending behavior and providing AI-driven insights
///
/// This unified service combines:
/// - User behavior profile analysis
/// - Historical spending pattern analysis
/// - Budget optimization recommendations
/// - Financial goal achievement analysis
/// - Personalized insights and alerts
/// - Anomaly detection
class SpendingBehaviorAnalysisService {
  SpendingBehaviorAnalysisService({
    required GeminiApiClient apiClient,
    required ConnectivityService connectivityService,
  })  : _apiClient = apiClient,
        _connectivityService = connectivityService;

  // Services
  final GeminiApiClient _apiClient;
  final ConnectivityService _connectivityService;
  bool _isInitialized = false;

  /// Initialize the spending behavior analysis service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('💡 SpendingBehaviorAnalysisService: Initializing...');

      // Initialize the API client
      await _apiClient.initialize();

      _isInitialized = true;
      debugPrint(
          '💡 SpendingBehaviorAnalysisService: Initialized successfully');
    } catch (e) {
      debugPrint('spending_behavior_analysis_service: Diagnostic output redacted');
      throw AIApiException(
        'Failed to initialize spending behavior analysis service: $e',
        code: 'INITIALIZATION_ERROR',
      );
    }
  }

  /// Comprehensive spending behavior analysis with user profile integration
  ///
  /// This method provides a complete analysis including:
  /// - Spending pattern analysis based on user behavior profile
  /// - Budget reallocation recommendations
  /// - Goal achievement analysis
  /// - Personalized financial insights
  /// - Anomaly detection
  Future<SpendingBehaviorAnalysisResult> analyzeSpendingBehavior({
    required List<Expense> historicalExpenses,
    required Budget currentBudget,
    required UserBehaviorProfile userProfile,
    List<FinancialGoal>? goals,
  }) async {
    try {
      await _ensureInitialized();
      await _checkConnectivity();
      _validateInputData(historicalExpenses, currentBudget, userProfile);

      debugPrint('💡 Starting comprehensive spending behavior analysis...');

      final request = _prepareComprehensiveAnalysisRequest(
        historicalExpenses,
        currentBudget,
        userProfile,
        goals,
      );

      final response = await _callFastAPIBackend(request);
      final analysisResult = await _parseComprehensiveResponse(response);

      debugPrint(
          '💡 Comprehensive spending behavior analysis completed successfully');
      return analysisResult;
    } catch (e) {
      debugPrint('Spending behavior analysis failed');

      if (e is AIApiException) {
        rethrow;
      }

      throw AIApiException(
        'Failed to analyze spending behavior',
        code: 'ANALYSIS_ERROR',
      );
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await _connectivityService.isConnected;
    if (!isConnected) {
      throw AIApiException(
        'Internet connection required for spending behavior analysis',
        code: 'NO_CONNECTIVITY',
      );
    }
  }

  void _validateInputData(
    List<Expense> historicalExpenses,
    Budget currentBudget,
    UserBehaviorProfile userProfile,
  ) {
    if (historicalExpenses.isEmpty) {
      throw AIApiException(
        'Historical expense data is required for spending behavior analysis',
        code: 'INSUFFICIENT_DATA',
      );
    }

    if (currentBudget.total <= 0) {
      throw AIApiException(
        'Valid budget data is required for analysis',
        code: 'INVALID_BUDGET',
      );
    }

    if (!userProfile.isComplete) {
      throw AIApiException(
        'Complete user behavior profile is required for personalized analysis',
        code: 'INCOMPLETE_PROFILE',
      );
    }

    // Check if we have enough data for meaningful analysis (past 30 days)
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final relevantExpenses = historicalExpenses
        .where((expense) => expense.date.isAfter(cutoffDate))
        .toList();

    if (relevantExpenses.length < 5) {
      throw AIApiException(
        'Not enough recent expense data for meaningful analysis (minimum 5 expenses required in the last 30 days)',
        code: 'INSUFFICIENT_RECENT_DATA',
      );
    }
  }

  SpendingBehaviorAnalysisRequest _prepareComprehensiveAnalysisRequest(
    List<Expense> historicalExpenses,
    Budget currentBudget,
    UserBehaviorProfile userProfile,
    List<FinancialGoal>? goals,
  ) {
    // Filter expenses to the last 30 days for analysis
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final relevantExpenses = historicalExpenses
        .where((expense) => expense.date.isAfter(cutoffDate))
        .toList();

    // Sort by date for pattern analysis
    relevantExpenses.sort((a, b) => a.date.compareTo(b.date));

    debugPrint('Spending analysis request prepared');
    debugPrint('spending_behavior_analysis_service: Diagnostic output redacted');
    debugPrint('spending_behavior_analysis_service: Diagnostic output redacted');

    return SpendingBehaviorAnalysisRequest(
      historicalExpenses: relevantExpenses
          .map((e) => AnalysisExpenseData.fromExpense(e))
          .toList(),
      currentBudget: AnalysisBudgetData.fromBudget(currentBudget),
      userProfile: AnalysisUserProfileData.fromProfile(userProfile),
      financialGoals:
          goals?.map((g) => AnalysisFinancialGoalData.fromGoal(g)).toList() ??
              [], // Ensure it's an empty list, not null
      analysisDate: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> _callFastAPIBackend(
      SpendingBehaviorAnalysisRequest request) async {
    try {
      debugPrint('💡 Calling FastAPI backend for comprehensive analysis...');

      final response = await _apiClient.analyzeSpendingBehavior(
        request: request,
      );

      debugPrint('💡 FastAPI backend response received successfully');
      return response;
    } catch (_) {
      debugPrint('Spending behavior backend request failed');
      throw AIApiException(
        'AI analysis failed',
        code: 'API_ERROR',
      );
    }
  }

  Future<SpendingBehaviorAnalysisResult> _parseComprehensiveResponse(
      Map<String, dynamic> response) async {
    try {
      debugPrint('💡 [AI COMPREHENSIVE RESPONSE - SIMPLIFIED] ===============');
      debugPrint('💡 Raw response received');
      debugPrint('spending_behavior_analysis_service: Diagnostic output redacted');

      // Log the main response components
      if (response.containsKey('categoryInsights')) {
        debugPrint('SpendingBehaviorAnalysisService: Category insights received');
      }

      if (response.containsKey('keyInsights')) {
        debugPrint('SpendingBehaviorAnalysisService: Key insights received');
      }

      if (response.containsKey('actionableRecommendations')) {
        debugPrint(
            'SpendingBehaviorAnalysisService: Recommendations received');
      }

      if (response.containsKey('summary')) {
        debugPrint('SpendingBehaviorAnalysisService: Summary received');
      }

      final analysisResult = SpendingBehaviorAnalysisResult.fromJson(response);

      debugPrint('💡 Simplified response parsed successfully');
      debugPrint('SpendingBehaviorAnalysisService: Response parsed');

      return analysisResult;
    } catch (_) {
      debugPrint('Spending behavior response parsing failed');
      throw AIApiException(
        'Failed to parse comprehensive analysis',
        code: 'PARSE_ERROR',
      );
    }
  }

  /// Clean up resources
  void dispose() {
    _isInitialized = false;
    debugPrint('💡 SpendingBehaviorAnalysisService: Disposed');
  }
}
