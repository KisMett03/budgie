import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/notification_detection_api_service.dart';
import '../../core/services/api_models.dart';
import '../utils/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../di/injection_container.dart' as di;

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  _NotificationTestScreenState createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final _notificationService = di.sl<NotificationService>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String _status = 'No test performed yet.';

  // Logs for tracking
  List<String> _logs = [];
  ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Budgie Test';
    _messageController.text =
        'Payment of RM 25.50 at Starbucks has been processed';
    _checkPermission();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final hasPermission =
        await _notificationService.checkNotificationPermission();
    final hasListenerPermission = Platform.isAndroid
        ? await _notificationService.checkNotificationListenerPermission()
        : true;

    _addLog('Notification permission: $hasPermission');
    _addLog('Notification listener permission: $hasListenerPermission');

    setState(() {
      _status = 'Notification permission: $hasPermission\n'
          'Notification listener permission: $hasListenerPermission';
    });
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _status = 'Requesting permissions...';
    });

    try {
      final result =
          await _notificationService.requestAllNotificationPermissions();
      _addLog('Permission request result: $result');

      setState(() {
        _status = 'Permission request result: $result';
      });

      // Re-check permissions after request
      await _checkPermission();
    } catch (e) {
      _addLog('Error requesting permissions: $e');
      setState(() {
        _status = 'Error requesting permissions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Start the notification listener service
  Future<void> _startNotificationListener() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting notification listener...';
    });

    try {
      await _notificationService.startNotificationListener();
      final isListening = _notificationService.isListening;
      _addLog('Notification listener started, isListening: $isListening');

      setState(() {
        _status = 'Notification listener started: $isListening';
      });
    } catch (e) {
      _addLog('Error starting notification listener: $e');
      setState(() {
        _status = 'Error starting notification listener: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test sending a notification
  Future<void> _sendTestExpenseNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Sending test expense notification...';
    });

    try {
      await _notificationService.sendTestExpenseNotification();
      _addLog('Test expense notification sent');

      setState(() {
        _status = 'Test expense notification sent. Check if it was detected.';
      });
    } catch (e) {
      _addLog('Error sending test notification: $e');
      setState(() {
        _status = 'Error sending test notification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Send custom notification
  Future<void> _sendCustomNotification() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      setState(() {
        _status = 'Title and message cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Sending custom notification...';
    });

    try {
      await _notificationService.sendTestCustomNotification(
        title: title,
        body: message,
      );
      _addLog('Custom notification sent: $title - $message');

      setState(() {
        _status = 'Custom notification sent. Check if it was detected.';
      });
    } catch (e) {
      _addLog('Error sending custom notification: $e');
      setState(() {
        _status = 'Error sending custom notification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test the notification service without sending a notification
  Future<void> _testExpenseSimulation() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing expense simulation...';
    });

    try {
      await _notificationService.simulateExpenseWorkflow();
      _addLog('Expense simulation completed');

      setState(() {
        _status = 'Expense simulation completed.';
      });
    } catch (e) {
      _addLog('Error in expense simulation: $e');
      setState(() {
        _status = 'Error in expense simulation: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addLog(String log) {
    setState(() {
      _logs.add('[${DateTime.now().toString()}] $log');

      // Scroll to bottom after adding log
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  // Clear logs
  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Test'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 8),
                            Text(_status),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Permissions',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _requestPermission,
                              icon: Icon(Icons.security),
                              label: Text('Request Notification Permissions'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _checkPermission,
                              icon: Icon(Icons.check_circle),
                              label: Text('Check Permissions'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notification Service',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _startNotificationListener,
                              icon: Icon(Icons.play_arrow),
                              label: Text('Start Notification Listener'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Test Notifications',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _sendTestExpenseNotification,
                              icon: Icon(Icons.notification_important),
                              label: Text('Send Test Expense Notification'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Notification Title',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                labelText: 'Notification Message',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _sendCustomNotification,
                              icon: Icon(Icons.send),
                              label: Text('Send Custom Notification'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _testExpenseSimulation,
                              icon: Icon(Icons.run_circle),
                              label: Text('Simulate Expense Processing'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Log',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                IconButton(
                                  icon: Icon(Icons.copy),
                                  onPressed: () {
                                    final text = _logs.join('\n');
                                    Clipboard.setData(
                                        ClipboardData(text: text));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Logs copied to clipboard')),
                                    );
                                  },
                                  tooltip: 'Copy logs',
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListView.builder(
                                  controller: _logScrollController,
                                  itemCount: _logs.length,
                                  itemBuilder: (context, index) {
                                    return Text(
                                      _logs[index],
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
