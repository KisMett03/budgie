import 'package:flutter/material.dart';
import 'dart:io';

class NotificationPermissionGuideDialog extends StatelessWidget {
  const NotificationPermissionGuideDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Access Required'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To detect expenses from notifications, Budgie needs special permission to read your notifications.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (Platform.isAndroid) ...[
              const Text('Follow these steps:'),
              const SizedBox(height: 8),
              _buildStep(
                1,
                'In the next screen, find "Notification access" or "Notification listener"',
                Icons.notifications_active,
                context,
              ),
              _buildStep(
                2,
                'Look for "Budgie Notification Listener" in the list',
                Icons.search,
                context,
              ),
              _buildStep(
                3,
                'Toggle it ON (If it\'s grayed out, tap on it first)',
                Icons.toggle_on,
                context,
              ),
              _buildStep(
                4,
                'Confirm any permission dialogs that appear',
                Icons.check_circle,
                context,
              ),
              _buildStep(
                5,
                'Return to Budgie app when done',
                Icons.arrow_back,
                context,
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: A persistent notification will appear while the app is monitoring for expenses. This is required to keep the app running in the background.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              const Text(
                'Some devices may require additional steps depending on your Android version and manufacturer.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ] else ...[
              const Text(
                'Please enable notifications for Budgie in your device settings.',
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CONTINUE TO SETTINGS'),
        ),
      ],
    );
  }

  Widget _buildStep(
      int number, String text, IconData icon, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
