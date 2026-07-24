import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode

import 'permission_handler_service.dart';
import '../../../domain/services/expense_extraction_service.dart';
import '../../../di/injection_container.dart' as di;
import 'settings_service.dart'; // Added for SettingsService

/// Service responsible for listening to system notifications
/// Handles notification capture and processing workflow
///
/// IMPORTANT: This service should be initialized and started by a higher-level
/// service (e.g., DataCollectionService) at app startup ONLY if the user
/// has enabled expense detection in the app settings.
class NotificationListenerService {
  NotificationListenerService({required PermissionHandlerService permissionHandler})
      : _permissionHandler = permissionHandler;

  // Method channel for native communication
  static const platform = MethodChannel('com.kai.budgie/notification_listener');

  // Callback for notification events
  Function(String title, String content, String packageName)?
      _onNotificationReceived;
  bool _isListening = false;
  bool _isInitialized = false;
  bool _isServiceEnabled = false;
  bool _hasPermissions = false;

  // Dependencies
  final PermissionHandlerService _permissionHandler;
  SettingsService? _settingsService;

  bool get _notificationsEnabled => _settingsService?.allowNotification ?? false;

  /// Initialize the notification listener service
  Future<void> initialize({SettingsService? settingsService}) async {
    _settingsService ??= settingsService;
    if (_isInitialized) {
      debugPrint(
          '🔔 NotificationListenerService: Already initialized, skipping');
      return;
    }

    try {
      debugPrint('🔔 NotificationListenerService: Initializing...');

      // Check current state
      await _updateServiceState();

      // Setup background processing
      await _setupBackgroundProcessing();

      // Mark as initialized
      _isInitialized = true;

      debugPrint('✅ NotificationListenerService: Initialization completed');
      debugPrint('📊 Service State: $_getDetailedStateString()');
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationListenerService: Initialization failed: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Set callback for notification events
  void setNotificationCallback(
      Function(String title, String content, String packageName) callback) {
    _onNotificationReceived = (title, content, packageName) {
      // Check if notifications are enabled before processing
      if (!_notificationsEnabled) {
        debugPrint(
            '🔔 NotificationListenerService: Notifications are disabled in settings. Skipping processing.');
        return;
      }
      callback(title, content, packageName);
    };
    debugPrint('🔔 NotificationListenerService: Callback set');
  }

  /// Start notification listening service
  Future<bool> startListening() async {
    if (_isListening) {
      debugPrint('⚠️ NotificationListenerService: Already listening');
      return true;
    }

    try {
      debugPrint(
          '🔔 NotificationListenerService: Starting notification listener...');

      // Update service state before starting
      await _updateServiceState();

      // Check for native permissions before attempting to start
      final bool hasPermission =
          await platform.invokeMethod('isNotificationServiceEnabled');
      if (!hasPermission) {
        debugPrint(
            '❌ NotificationListenerService: Notification listener permission not granted at system level.');
        _isServiceEnabled = false;
        return false;
      }

      // Check permissions first
      final hasPermissions = await _permissionHandler
          .hasPermissionsForFeature(PermissionFeature.notifications);
      if (!hasPermissions) {
        debugPrint('❌ NotificationListenerService: Insufficient permissions');
        _hasPermissions = false;
        return false;
      }

      // Setup background service for Android
      if (Platform.isAndroid) {
        await _enableBackgroundService();
      }

      // Start platform-specific listener
      await _startPlatformListener();

      // Add a small delay to ensure the platform listener is fully started
      if (Platform.isAndroid) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      _isListening = true;
      debugPrint(
          '✅ NotificationListenerService: Notification listening started');
      debugPrint('📊 Service State: $_getDetailedStateString()');
      return true;
    } catch (e) {
      debugPrint(
          '❌ NotificationListenerService: Failed to start listening: $e');
      _isListening = false;
      return false;
    }
  }

  /// Stop notification listening service
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      debugPrint(
          '🔔 NotificationListenerService: Stopping notification listener...');

      // Stop platform listener with error handling
      try {
        await platform.invokeMethod('stopListening');
        debugPrint('✅ NotificationListenerService: Platform listener stopped');
      } catch (e) {
        debugPrint(
            '⚠️ NotificationListenerService: Error stopping platform listener: $e');
      }

      // No background execution to disable since we're not using FlutterBackground
      debugPrint('✅ NotificationListenerService: Background cleanup completed');

      _isListening = false;
      debugPrint(
          '✅ NotificationListenerService: Notification listening stopped');
      debugPrint('📊 Service State: $_getDetailedStateString()');
    } catch (e) {
      debugPrint('❌ NotificationListenerService: Error stopping listener: $e');
      // Force stop even if there were errors
      _isListening = false;
    }
  }

  /// Check service health status with detailed information
  Future<Map<String, dynamic>> getHealthStatus() async {
    await _updateServiceState();

    // Check if the listener is actually connected and working
    bool isActuallyListening = _isListening;
    if (Platform.isAndroid && _isListening) {
      try {
        // Try to verify the connection by checking if the service is responding
        final isServiceEnabled = await checkNotificationServiceEnabled();
        isActuallyListening = isServiceEnabled && _isListening;
      } catch (e) {
        debugPrint(
            '⚠️ NotificationListenerService: Could not verify connection: $e');
        isActuallyListening = false;
      }
    }

    return {
      'isInitialized': _isInitialized,
      'isListening': _isListening,
      'isActuallyListening': isActuallyListening,
      'isServiceEnabled': _isServiceEnabled,
      'hasPermissions': _hasPermissions,
      'hasBasicPermission':
          await _permissionHandler.hasNotificationPermission(),
      'hasListenerPermission':
          await _permissionHandler.hasNotificationListenerPermission(),
      'backgroundServiceEnabled':
          true, // Always true since we don't use FlutterBackground
      'detailedState': _getDetailedStateString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Check if notification permission is granted
  Future<bool> checkNotificationPermission() async {
    final hasPermission = await _permissionHandler.hasNotificationPermission();
    debugPrint(
        '🔐 NotificationListenerService: Basic permission check: $hasPermission');
    return hasPermission;
  }

  /// Check if notification listener permission is granted (Android only)
  Future<bool> checkNotificationListenerPermission() async {
    final hasPermission =
        await _permissionHandler.hasNotificationListenerPermission();
    debugPrint(
        '🔐 NotificationListenerService: Listener permission check: $hasPermission');
    return hasPermission;
  }

  /// Check if notification service is enabled at system level
  Future<bool> checkNotificationServiceEnabled() async {
    try {
      if (Platform.isAndroid) {
        final result =
            await platform.invokeMethod<bool>('isNotificationServiceEnabled');
        final enabled = result ?? false;
        debugPrint(
            '⚙️ NotificationListenerService: Service enabled check: $enabled');
        return enabled;
      }
      return true; // Non-Android platforms don't need this
    } catch (e) {
      debugPrint(
          '❌ NotificationListenerService: Error checking service enabled: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<PermissionStatus> requestNotificationPermissions(
      BuildContext? context) async {
    debugPrint('🔐 NotificationListenerService: Requesting permissions...');
    final result = await _permissionHandler.requestPermissionsForFeature(
        PermissionFeature.notifications, context);

    // Update state after permission request
    await _updateServiceState();

    debugPrint(
        '🔐 NotificationListenerService: Permission request result: ${result.message}');
    return result;
  }

  /// Update internal service state
  Future<void> _updateServiceState() async {
    try {
      _hasPermissions = await _permissionHandler
          .hasPermissionsForFeature(PermissionFeature.notifications);
      _isServiceEnabled = await checkNotificationServiceEnabled();

      debugPrint(
          '📊 NotificationListenerService: State updated - Permissions: $_hasPermissions, Service: $_isServiceEnabled');
    } catch (e) {
      debugPrint('❌ NotificationListenerService: Error updating state: $e');
    }
  }

  /// Get detailed state string for logging
  String _getDetailedStateString() {
    return 'Initialized: $_isInitialized, Listening: $_isListening, Permissions: $_hasPermissions, Service: $_isServiceEnabled';
  }

  /// Process notification with hybrid detection (TFLite + Gemini)
  Future<void> processNotificationWithHybridDetection({
    required String title,
    required String content,
    String? packageName,
    required DateTime timestamp,
  }) async {
    // Check if notifications are enabled before processing
    if (!_notificationsEnabled) {
      debugPrint(
          '🔔 NotificationListenerService: Notifications are disabled in settings. Skipping hybrid detection.');
      return;
    }
    try {
      if (!di.sl.isRegistered<ExpenseExtractionDomainService>()) {
        if (kDebugMode) {
          debugPrint(
              '� NotificationListener: Expense extraction service not registered, skipping processing');
        }
        return;
      }

      final extractionService = di.sl<ExpenseExtractionDomainService>();

      // Ensure the service itself is initialized (loads TFLite model)
      if (!extractionService.isInitialized) {
        debugPrint(
            '⚠️ NotificationListener: Expense extraction service not initialized, skipping');
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '🔔 NotificationListener: Processing notification with hybrid detection');
        debugPrint('📱 Package: $packageName');
        debugPrint('📝 Title: "$title"');
        debugPrint('📄 Content: "$content"');
      }

      // Only track performance in debug mode
      Stopwatch? stopwatch;
      if (kDebugMode) {
        stopwatch = Stopwatch()..start();
      }

      // Use the complete hybrid processing (recommended approach)
      final extractionResult = await extractionService.processNotification(
        title: title,
        content: content,
        source: packageName ?? 'unknown_source',
        packageName: packageName,
      );

      if (kDebugMode) {
        stopwatch?.stop();
      }

      if (extractionResult != null) {
        debugPrint('✅ NotificationListener: Expense detected and extracted!');
        debugPrint(
            '💰 Amount: ${extractionResult.amount} ${extractionResult.currency ?? 'MYR'}');
        debugPrint('🏪 Merchant: ${extractionResult.merchantName}');
        debugPrint('💳 Payment Method: ${extractionResult.paymentMethod}');
        debugPrint(
            '🏷️ Suggested Category: ${extractionResult.suggestedCategory}');
        debugPrint(
            '🎯 Confidence: ${(extractionResult.confidence * 100).toStringAsFixed(1)}%');
        if (kDebugMode && stopwatch != null) {
          debugPrint('⏱️ Processing Time: ${stopwatch.elapsedMilliseconds}ms');
        }

        // The service automatically:
        // 1. Records the detection for analytics
        // 2. Sends actionable notification to user
        // 3. Collects data for model improvement

        debugPrint(
            '📊 NotificationListener: Hybrid processing completed successfully');
      } else {
        debugPrint(
            '📱 NotificationListener: Notification classified as non-expense or extraction failed');
        if (kDebugMode && stopwatch != null) {
          debugPrint(
              '⏱️ Classification Time: ${stopwatch.elapsedMilliseconds}ms');
        }
      }
    } catch (e) {
      debugPrint('❌ NotificationListener: Hybrid processing failed: $e');
    }
  }

  /// Alternative: Step-by-step processing for custom flows
  Future<void> processNotificationStepByStep({
    required String title,
    required String content,
    required String packageName,
  }) async {
    try {
      final expenseService = di.sl<ExpenseExtractionDomainService>();

      if (!expenseService.isInitialized) return;

      debugPrint('🔔 NotificationListener: Step-by-step processing');

      // Step 1: Classify using TensorFlow model
      Stopwatch? classificationStopwatch;
      if (kDebugMode) {
        classificationStopwatch = Stopwatch()..start();
      }
      
      final isExpense = await expenseService.classifyNotification(
        title: title,
        content: content,
        source: packageName,
        packageName: packageName,
      );
      
      if (kDebugMode) {
        classificationStopwatch?.stop();
        debugPrint(
            '🤖 Classification: ${isExpense ? "EXPENSE" : "NOT EXPENSE"} (${classificationStopwatch?.elapsedMilliseconds ?? 0}ms)');
      }

      if (isExpense) {
        // Step 2: Extract details using API
        Stopwatch? extractionStopwatch;
        if (kDebugMode) {
          extractionStopwatch = Stopwatch()..start();
        }

        final extractionResult = await expenseService.extractExpenseDetails(
          title: title,
          content: content,
          source: packageName,
          packageName: packageName,
        );
        
        if (kDebugMode) {
          extractionStopwatch?.stop();
        }

        if (extractionResult != null) {
          if (kDebugMode) {
            debugPrint(
                '✅ Extraction: SUCCESS (${extractionStopwatch?.elapsedMilliseconds ?? 0}ms)');
            debugPrint(
                '💰 Details: ${extractionResult.amount} at ${extractionResult.merchantName}');
          }
        } else {
          if (kDebugMode) {
            debugPrint(
                '❌ Extraction: FAILED (${extractionStopwatch?.elapsedMilliseconds ?? 0}ms)');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ NotificationListener: Step-by-step processing failed: $e');
    }
  }

  // Private methods

  Future<void> _setupBackgroundProcessing() async {
    if (!Platform.isAndroid) return;

    try {
      // Set up method channel without FlutterBackground foreground service
      // NotificationListenerService can run without a foreground service
      platform.setMethodCallHandler(_handleNotificationData);
      debugPrint(
          '✅ NotificationListenerService: Method channel setup completed');
    } catch (e) {
      debugPrint('❌ NotificationListenerService: Background setup failed: $e');
    }
  }

  Future<void> _enableBackgroundService() async {
    try {
      // NotificationListenerService doesn't need FlutterBackground to function
      // It's a system service that runs independently
      debugPrint(
          '✅ NotificationListenerService: Background service setup completed (system service)');
    } catch (e) {
      debugPrint(
          '❌ NotificationListenerService: Background service failed: $e');
    }
  }

  Future<void> _startPlatformListener() async {
    try {
      await platform.invokeMethod('startListening');
      debugPrint('✅ NotificationListenerService: Platform listener started');
    } catch (e) {
      debugPrint('❌ NotificationListenerService: Platform listener failed: $e');
      rethrow;
    }
  }

  Future<void> _handleNotificationData(MethodCall call) async {
    if (call.method == 'onNotificationReceived') {
      final Map<dynamic, dynamic> data = call.arguments;
      final packageName = data['packageName'] ?? '';
      final title = data['title'] ?? '';
      final content = data['content'] ?? '';

      debugPrint(
          '🔔 NotificationListenerService: Raw notification received from $packageName');

      // Filter out system notifications and other irrelevant sources
      if (_shouldIgnoreNotification(packageName, title, content)) {
        debugPrint(
            '🔔 NotificationListenerService: Ignoring filtered notification from $packageName - $title');
        return;
      }

      if (_onNotificationReceived != null) {
        debugPrint(
            '🔔 NotificationListenerService: Processing notification - $title: $content (from $packageName)');
        _onNotificationReceived!(title, content, packageName);
      } else {
        debugPrint(
            '⚠️ NotificationListenerService: No callback set for notification processing');
      }
    }
  }

  /// Check if notification should be ignored based on package name and content
  bool _shouldIgnoreNotification(
      String packageName, String title, String content) {
    // Always ignore our own app notifications to prevent processing loops
    if (packageName == 'com.kai.budgie') {
      return true;
    }

    // Ignore system notifications
    final systemPackages = [
      'android',
      'com.android.systemui',
      'com.android.settings',
      'system',
    ];

    if (systemPackages.any((pkg) => packageName.startsWith(pkg))) {
      return true;
    }

    // Ignore notifications that are clearly not expense-related
    final irrelevantKeywords = [
      'system update',
      'battery',
      'charging',
      'wifi',
      'bluetooth',
      'volume',
      'screenshot',
      'media',
      'incoming call', // Changed from 'call' to 'incoming call' to be more specific
      'missed call', // Added for call-related notifications
      'call ended', // Added for call-related notifications
      'sms',
      'email',
      'calendar',
      'reminder',
      'alarm',
      'weather',
      'expense detected', // Ignore our own expense detection notifications
    ];

    final combinedText = '$title $content'.toLowerCase();

    // Check for exact keyword matches to avoid false positives
    // For expense-related notifications that might contain words like "call" in banking instructions
    if (irrelevantKeywords.any((keyword) => combinedText.contains(keyword))) {
      // Additional check: if it contains financial keywords, don't filter it out
      final financialKeywords = [
        'payment',
        'transfer',
        'transaction',
        'balance',
        'account',
        'bank',
        'debit',
        'credit',
        'purchase',
        'receipt',
        'charged',
        'fpx',
        'rm', // Malaysian Ringgit
        'usd',
        'eur',
        'sgd',
      ];

      final hasFinancialContent =
          financialKeywords.any((keyword) => combinedText.contains(keyword));

      if (hasFinancialContent) {
        debugPrint(
            '🔔 NotificationListenerService: Contains irrelevant keyword but has financial content, processing anyway');
        return false; // Don't ignore financial notifications
      }

      return true; // Ignore non-financial notifications with irrelevant keywords
    }

    return false;
  }

  /// Getters for service state
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  bool get isServiceEnabled => _isServiceEnabled;
  bool get hasPermissions => _hasPermissions;

  /// Cleanup resources
  void dispose() {
    _isListening = false;
    _isInitialized = false;
    _isServiceEnabled = false;
    _hasPermissions = false;
  }
}
