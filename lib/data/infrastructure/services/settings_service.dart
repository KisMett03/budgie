import 'package:flutter/foundation.dart';

import 'permission_handler_service.dart';
import 'notification_listener_service.dart';
import '../storage/settings_storage.dart';

/// Service responsible for managing all app settings and preferences
/// Acts as the single source of truth for user settings
class SettingsService extends ChangeNotifier {
  bool _hasLoadedPersistedSettings = false;
  bool _hasCompletedInitialization = false;

  // Settings values
  late String _theme;
  late bool _allowNotification;
  late bool _autoBudget;
  late bool _syncEnabled;
  late String _currency;
  late bool _locationEnabled;
  late bool _cameraEnabled;
  late bool _storageEnabled;
  late bool _biometricEnabled;

  // Services
  final SettingsStorage _storage;
  final PermissionHandlerService _permissionHandler;
  final NotificationListenerService _notificationListenerService;
  final Future<void> Function() _initializeExpenseExtraction;

  // Getters
  String get theme => _theme;
  bool get allowNotification => _allowNotification;
  bool get autoBudget => _autoBudget;
  bool get syncEnabled => _syncEnabled;
  String get currency => _currency;
  bool get locationEnabled => _locationEnabled;
  bool get cameraEnabled => _cameraEnabled;
  bool get storageEnabled => _storageEnabled;
  bool get biometricEnabled => _biometricEnabled;

  SettingsService({
    required SettingsStorage storage,
    required PermissionHandlerService permissionHandler,
    required NotificationListenerService notificationListenerService,
    required Future<void> Function() initializeExpenseExtraction,
  })  : _storage = storage,
        _permissionHandler = permissionHandler,
        _notificationListenerService = notificationListenerService,
        _initializeExpenseExtraction = initializeExpenseExtraction {
    _theme = 'light';
    _allowNotification = false;
    _autoBudget = false;
    _syncEnabled = false;
    _currency = 'MYR';
    _locationEnabled = false;
    _cameraEnabled = false;
    _storageEnabled = false;
    _biometricEnabled = false;
  }

  Map<String, dynamic> get currentSettings => {
        'currency': _currency,
        'theme': _theme,
        'settings': {
          'allowNotification': _allowNotification,
          'autoBudget': _autoBudget,
          'syncEnabled': _syncEnabled,
          'locationEnabled': _locationEnabled,
          'cameraEnabled': _cameraEnabled,
          'storageEnabled': _storageEnabled,
          'biometricEnabled': _biometricEnabled,
        },
      };

  Future<void> loadPersistedSettings() async {
    if (_hasLoadedPersistedSettings) {
      return;
    }

    try {
      await _loadSettings();
      _hasLoadedPersistedSettings = true;
      notifyListeners();
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    }
  }

  Future<void> initialize() async {
    if (_hasCompletedInitialization) {
      return;
    }

    await loadPersistedSettings();

    try {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Initializing settings');
      }

      await _permissionHandler.initialize();

      try {
        await _notificationListenerService.initialize(settingsService: this);
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: NotificationListenerService initialized');
        }
      } catch (_) {
        if (kDebugMode) {
          debugPrint('SettingsService: Diagnostic output redacted');
        }
      }

      await _verifyPermissionSettings();

      // Auto-start notification listener if setting is enabled
      if (_allowNotification) {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Notification setting is enabled - auto-starting listener...');
        }
        await _startNotificationListener();
      } else {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Notification setting is disabled - listener will not start');
        }
      }

      notifyListeners();
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Initialization completed');
      }
      _hasCompletedInitialization = true;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final persisted = await _storage.loadAll();
      _theme = persisted['theme'] as String;
      _allowNotification = persisted['allowNotification'] as bool;
      _autoBudget = persisted['autoBudget'] as bool;
      _syncEnabled = persisted['syncEnabled'] as bool;
      _currency = persisted['currency'] as String;
      _locationEnabled = persisted['locationEnabled'] as bool;
      _cameraEnabled = persisted['cameraEnabled'] as bool;
      _storageEnabled = persisted['storageEnabled'] as bool;
      _biometricEnabled = persisted['biometricEnabled'] as bool;

      if (kDebugMode) {
        debugPrint('SettingsService: Persisted settings loaded');
      }
      _hasLoadedPersistedSettings = true;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    }
  }

  Future<void> _verifyPermissionSettings() async {
    try {
      // The notification permission check has been moved to _startNotificationListener
      // to avoid race conditions on app startup. This method will now only
      // verify other permissions if needed in the future.

      if (_locationEnabled) {
        final hasPermission = await _permissionHandler.hasLocationPermission();
        if (!hasPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Location permission mismatch, updating setting');
          }
          await updateLocationSetting(false);
        }
      }
      if (_cameraEnabled) {
        final hasPermission = await _permissionHandler.hasCameraPermission();
        if (!hasPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Camera permission mismatch, updating setting');
          }
          await updateCameraSetting(false);
        }
      }
      if (_storageEnabled) {
        final hasPermission = await _permissionHandler.hasStoragePermission();
        if (!hasPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Storage permission mismatch, updating setting');
          }
          await updateStorageSetting(false);
        }
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    }
  }

  Future<void> resetToDefaults() async {
    try {
      await _storage.clearAll();
      _hasLoadedPersistedSettings = false;
      await loadPersistedSettings();
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Settings reset to defaults');
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    }
  }

  Future<void> updateCurrency(String newCurrency) async {
    try {
      _currency = newCurrency;
      await _storage.saveCurrency(newCurrency);
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
      notifyListeners();
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
      _currency = 'MYR';
    }
  }

  Future<void> updateTheme(String newTheme) async {
    try {
      _theme = newTheme;
      await _storage.saveTheme(newTheme);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    }
  }

  Future<bool> updateNotificationSetting(bool enabled) async {
    try {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }

      // Check permissions if enabling
      if (enabled) {
        final hasPermissions = await _permissionHandler
            .hasPermissionsForFeature(PermissionFeature.notifications);
        if (!hasPermissions) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Cannot enable notifications without permissions');
          }
          return false;
        }
      }

      final previousValue = _allowNotification;

      // Update the setting
      _allowNotification = enabled;
      await _storage.saveNotificationEnabled(enabled);

      // Manage notification listener based on setting
      if (enabled && !previousValue) {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Notification enabled - starting listener...');
        }
        await _startNotificationListener();
      } else if (!enabled && previousValue) {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Notification disabled - stopping listener...');
        }
        await _stopNotificationListener();
      } else if (enabled && previousValue) {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Notification already enabled - ensuring listener is running...');
        }
        // Ensure listener is running if it should be
        if (!_notificationListenerService.isListening) {
          await _startNotificationListener();
        }
      }

      notifyListeners();
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
      return true;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
      return false;
    }
  }

  Future<void> updateAutoBudgetSetting(bool enabled) async {
    try {
      _autoBudget = enabled;
      await _storage.saveAutoBudget(enabled);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    }
  }

  Future<void> updateSyncSetting(bool enabled) async {
    try {
      _syncEnabled = enabled;
      await _storage.saveSyncEnabled(enabled);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    }
  }

  Future<bool> updateLocationSetting(bool enabled) async {
    try {
      if (enabled) {
        final hasPermission = await _permissionHandler.hasLocationPermission();
        if (!hasPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Cannot enable location without permission');
          }
          return false;
        }
      }
      _locationEnabled = enabled;
      await _storage.saveLocationEnabled(enabled);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
      return true;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
      return false;
    }
  }

  Future<bool> updateCameraSetting(bool enabled) async {
    try {
      if (enabled) {
        final hasPermission = await _permissionHandler.hasCameraPermission();
        if (!hasPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Cannot enable camera without permission');
          }
          return false;
        }
      }
      _cameraEnabled = enabled;
      await _storage.saveCameraEnabled(enabled);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
      return true;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
      return false;
    }
  }

  Future<bool> updateStorageSetting(bool enabled) async {
    try {
      if (enabled) {
        final hasPermission = await _permissionHandler.hasStoragePermission();
        if (!hasPermission) {
          if (kDebugMode) {
            debugPrint(
                '🔧 SettingsService: Cannot enable storage without permission');
          }
          return false;
        }
      }
      _storageEnabled = enabled;
      await _storage.saveStorageEnabled(enabled);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
      return true;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
      return false;
    }
  }

  Future<void> updateBiometricSetting(bool enabled) async {
    try {
      _biometricEnabled = enabled;
      await _storage.saveBiometricEnabled(enabled);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    }
  }

  Future<void> _startNotificationListener() async {
    try {
      // First, verify that we have the necessary permissions before proceeding.
      // This is the correct place to check, right before execution.
      final hasPermissions = await _permissionHandler
          .hasPermissionsForFeature(PermissionFeature.notifications);
      if (!hasPermissions) {
        if (kDebugMode) {
          debugPrint(
              '❌ SettingsService: Cannot start listener, required permissions are missing. The user setting remains ON.');
        }
        return; // Abort starting the listener
      }

      await _notificationListenerService.initialize(settingsService: this);

      // Proactively check for "run in background" permission
      final hasIgnoreBatteryPermission =
          await _permissionHandler.hasIgnoreBatteryOptimizationsPermission();
      if (!hasIgnoreBatteryPermission) {
        if (kDebugMode) {
          debugPrint(
              '🔧 SettingsService: Missing "run in background" permission, requesting...');
        }
        await _permissionHandler.requestIgnoreBatteryOptimizationsPermission();
      }

      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Starting notification listener...');
      }

      try {
        await _initializeExpenseExtraction();
        if (kDebugMode) {
          debugPrint('SettingsService: Expense extraction service ready');
        }
      } catch (_) {
        if (kDebugMode) {
          debugPrint('SettingsService: Expense extraction service unavailable');
        }
      }

      // Set up notification callback
      _notificationListenerService
          .setNotificationCallback((title, content, packageName) {
        _notificationListenerService.processNotificationWithHybridDetection(
          title: title,
          content: content,
          packageName: packageName,
          timestamp: DateTime.now(),
        );
      });

      // Start listening with retry logic
      bool started = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          started = await _notificationListenerService.startListening();
          if (started) {
            if (kDebugMode) {
              debugPrint('SettingsService: Diagnostic output redacted');
            }
            break;
          } else {
            if (kDebugMode) {
              debugPrint('SettingsService: Diagnostic output redacted');
            }
            if (attempt < 3) {
              await Future.delayed(Duration(milliseconds: 500 * attempt));
            }
          }
        } catch (_) {
          if (kDebugMode) {
            debugPrint('SettingsService: Diagnostic output redacted');
          }
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          }
        }
      }

      if (!started) {
        if (kDebugMode) {
          debugPrint(
              '❌ SettingsService: Failed to start notification listener after all attempts');
        }
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Error starting notification listener');
      }
    }
  }

  Future<void> _stopNotificationListener() async {
    try {
      if (kDebugMode) {
        debugPrint('🔧 SettingsService: Stopping notification listener...');
      }

      // Stop listening with retry logic
      bool stopped = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          await _notificationListenerService.stopListening();
          stopped = true;
          if (kDebugMode) {
            debugPrint('SettingsService: Diagnostic output redacted');
          }
          break;
        } catch (_) {
          if (kDebugMode) {
            debugPrint('SettingsService: Diagnostic output redacted');
          }
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 200 * attempt));
          }
        }
      }

      if (!stopped) {
        if (kDebugMode) {
          debugPrint(
              '❌ SettingsService: Failed to stop notification listener after all attempts');
        }
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Error stopping notification listener');
      }
    }
  }

  /// Synchronizes service states with stored settings on app resume.
  /// This is crucial for handling permissions that were changed while the app
  /// was in the background.
  Future<void> syncServicesOnResume() async {
    if (kDebugMode) {
      debugPrint('🔄 SettingsService: Syncing services on app resume...');
    }
    try {
      // 1. Reload the user's intended settings from storage to get the true state.
      await _loadSettings();

      // 2. Attempt to start services based on the reloaded settings.
      // The _startNotificationListener method already contains the necessary logic
      // to check for OS permissions before it runs.
      if (_allowNotification) {
        if (kDebugMode) {
          debugPrint(
              '🔄 SettingsService: Notification setting is ON, attempting to ensure listener is running.');
        }
        await _startNotificationListener();
      } else {
        if (kDebugMode) {
          debugPrint(
              '🔄 SettingsService: Notification setting is OFF, ensuring listener is stopped.');
        }
        await _stopNotificationListener();
      }

      notifyListeners();
    } catch (_) {
      if (kDebugMode) {
        debugPrint('SettingsService: Diagnostic output redacted');
      }
    }
  }

  @override
  void dispose() {
    _notificationListenerService.dispose();
    super.dispose();
  }
}
