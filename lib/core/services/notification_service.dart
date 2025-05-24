import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const platform = MethodChannel('com.kai.budgie/notification_listener');
  bool _isListening = false;
  StreamSubscription<dynamic>? _notificationSubscription;

  // Initialize the service
  Future<void> init() async {
    debugPrint('Notification service initialized');

    await _checkAndStartListener();
  }

  // Check user settings and start listener if enabled
  Future<void> _checkAndStartListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Use SettingsService instead of direct Firebase access
      final settingsService = SettingsService.instance;
      if (settingsService != null) {
        final allowNotification = settingsService.allowNotification;

        if (allowNotification) {
          final hasPermission = await checkNotificationPermission();
          if (hasPermission) {
            await startNotificationListener();
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking notification settings: $e');
    }
  }

  // Request notification permission using permission_handler
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }

    // Request notification permission
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  // Check if notification permission is granted
  Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Start the notification listener
  Future<void> startNotificationListener() async {
    if (_isListening) return;

    try {
      // For Android, we need to check notification access permission
      if (Platform.isAndroid) {
        final hasAccess = await _checkNotificationAccessPermission();
        if (!hasAccess) {
          debugPrint('Notification access permission not granted');
          return;
        }
      }

      _isListening = true;

      // Set up method channel listener for notifications
      platform.setMethodCallHandler(_handleNotificationData);

      // Start listening for notifications
      await platform.invokeMethod('startListening');

      debugPrint('Notification listener started');
    } catch (e) {
      debugPrint('Error starting notification listener: $e');
      _isListening = false;
    }
  }

  // Stop the notification listener
  Future<void> stopNotificationListener() async {
    if (!_isListening) return;

    try {
      await platform.invokeMethod('stopListening');
      _isListening = false;
      debugPrint('Notification listener stopped');
    } catch (e) {
      debugPrint('Error stopping notification listener: $e');
    }
  }

  // Handle incoming notification data
  Future<void> _handleNotificationData(MethodCall call) async {
    if (call.method == 'onNotificationReceived') {
      final Map<dynamic, dynamic> data = call.arguments;
      final String title = data['title'] ?? '';
      final String content = data['content'] ?? '';
      final String packageName = data['packageName'] ?? '';

      debugPrint('Received notification: $title - $content from $packageName');

      // Combine title and content for analysis
      final fullText = '$title $content'.trim();

      if (fullText.isNotEmpty) {
        await _analyzeNotificationForExpense(fullText, packageName);
      }
    }
  }

  // Analyze notification text using API to determine if it's an expense
  Future<void> _analyzeNotificationForExpense(
      String notificationText, String packageName) async {
    try {
      // Call your API service to classify the notification
      final expenseData = await _callExpenseClassificationAPI(notificationText);

      if (expenseData != null && expenseData['amount'] != null) {
        // This is an expense notification
        debugPrint(
            'Expense detected: ${expenseData['amount']} from ${expenseData['merchant'] ?? 'Unknown'}');

        // Save the expense to Firebase or handle it as needed
        await _saveAutoDetectedExpense(expenseData, packageName);
      } else {
        debugPrint('Not an expense notification');
      }
    } catch (e) {
      debugPrint('Error analyzing notification: $e');
    }
  }

  // Call the API service for expense classification
  Future<Map<String, dynamic>?> _callExpenseClassificationAPI(
      String text) async {
    try {
      // TODO: Replace with your actual API endpoint
      // This is a mock implementation

      // Simple pattern matching as fallback (replace with actual API call)
      RegExp amountPattern =
          RegExp(r'(?:RM|MYR|\$|USD)\s*(\d+(?:\.\d+)?)', caseSensitive: false);
      RegExp merchantPattern = RegExp(
          r'(?:at|from|to)\s+([A-Za-z\s]+?)(?:\s|$)',
          caseSensitive: false);

      final amountMatch = amountPattern.firstMatch(text);
      final merchantMatch = merchantPattern.firstMatch(text);

      // Check if this looks like a payment notification
      final paymentKeywords = [
        'paid',
        'payment',
        'transaction',
        'purchase',
        'spent',
        'debit',
        'charged'
      ];
      final hasPaymentKeyword = paymentKeywords
          .any((keyword) => text.toLowerCase().contains(keyword));

      if (amountMatch != null && hasPaymentKeyword) {
        return {
          'amount': double.tryParse(amountMatch.group(1) ?? '0') ?? 0,
          'merchant': merchantMatch?.group(1)?.trim() ?? 'Unknown',
          'date': DateTime.now().toIso8601String(),
          'category': 'Auto-detected',
          'currency': 'MYR', // Default currency
        };
      }

      return null; // Not an expense
    } catch (e) {
      debugPrint('Error calling expense classification API: $e');
      return null;
    }
  }

  // Save auto-detected expense to Firebase
  Future<void> _saveAutoDetectedExpense(
      Map<String, dynamic> expenseData, String source) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Add metadata about auto-detection
      expenseData['isAutoDetected'] = true;
      expenseData['source'] = source;
      expenseData['userId'] = user.uid;
      expenseData['createdAt'] = FieldValue.serverTimestamp();

      // Save to a separate collection for auto-detected expenses
      // User can review and approve these later
      await FirebaseFirestore.instance
          .collection('auto_detected_expenses')
          .add(expenseData);

      debugPrint('Auto-detected expense saved: ${expenseData['amount']}');
    } catch (e) {
      debugPrint('Error saving auto-detected expense: $e');
    }
  }

  // Check notification access permission (Android specific)
  Future<bool> _checkNotificationAccessPermission() async {
    try {
      final result = await platform.invokeMethod('checkNotificationAccess');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking notification access: $e');
      return false;
    }
  }

  // Request notification access permission (opens settings)
  Future<void> requestNotificationAccessPermission() async {
    try {
      await platform.invokeMethod('requestNotificationAccess');
    } catch (e) {
      debugPrint('Error requesting notification access: $e');
    }
  }

  // Show a simple snackbar instead of a notification (for demonstration)
  void showSnackBarNotification(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Get the current listening status
  bool get isListening => _isListening;

  // Clean up resources
  void dispose() {
    _notificationSubscription?.cancel();
    _isListening = false;
  }
}
