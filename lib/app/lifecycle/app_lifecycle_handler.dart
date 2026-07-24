import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/infrastructure/services/sync_service.dart';

/// Handles application lifecycle transitions that require service coordination.
class AppLifecycleHandler {
  AppLifecycleHandler({required SyncService syncService})
      : _syncService = syncService;

  final SyncService _syncService;

  void handleResume() {
    try {
      if (kDebugMode) {
        debugPrint('?? App resumed - checking for pending syncs');
      }

      unawaited(Future.delayed(const Duration(seconds: 1), () {
        unawaited(_syncService.syncData(fullSync: false));
      }));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('?? Resume sync failed: $e');
      }
    }
  }

  void handleDetached() {
    try {
      _syncService.dispose();
      if (kDebugMode) {
        debugPrint('?? App detached: disposed SyncService');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('?? Cleanup failed: $e');
      }
    }
  }
}
