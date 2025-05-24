import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/local_data_source.dart';
import '../network/connectivity_service.dart';

class SettingsService extends ChangeNotifier {
  static SettingsService? _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  String _currency = 'MYR';
  String _theme = 'dark';
  bool _allowNotification = true;
  bool _autoBudget = false;
  bool _improveAccuracy = false;

  String get currency => _currency;
  String get theme => _theme;
  bool get allowNotification => _allowNotification;
  bool get autoBudget => _autoBudget;
  bool get improveAccuracy => _improveAccuracy;

  SettingsService({
    required LocalDataSource localDataSource,
    required ConnectivityService connectivityService,
  })  : _localDataSource = localDataSource,
        _connectivityService = connectivityService {
    _instance = this;
  }

  // Static getter to access the current instance
  static SettingsService? get instance => _instance;

  // Get all current settings as a map
  Map<String, dynamic> get currentSettings => {
        'currency': _currency,
        'theme': _theme,
        'settings': {
          'allowNotification': _allowNotification,
          'autoBudget': _autoBudget,
          'improveAccuracy': _improveAccuracy,
        },
      };

  // Initialize settings for a specific user with offline support
  Future<void> initializeForUser(String userId) async {
    try {
      debugPrint('🔧 SettingsService: Initializing settings for user: $userId');

      // Try to load from local storage first
      final localSettings = await _localDataSource.getUserSettings(userId);

      if (localSettings != null) {
        debugPrint('🔧 SettingsService: Loading settings from local storage');
        await _loadUserSettings(localSettings);
        notifyListeners();

        // Try to sync with Firebase in the background if connected
        _backgroundSyncWithFirebase(userId);
        return;
      }

      // If no local settings, check connectivity and try Firebase
      final isConnected = await _connectivityService.isConnected;
      if (isConnected) {
        debugPrint(
            '🔧 SettingsService: No local settings, fetching from Firebase');
        await _loadFromFirebaseAndSave(userId);
      } else {
        debugPrint('🔧 SettingsService: Offline - using default settings');
        await _createDefaultSettings(userId);
      }

      notifyListeners();
      debugPrint(
          '🔧 SettingsService: Initialization completed for user: $userId');
    } catch (e) {
      debugPrint(
          '🔧 SettingsService: Error initializing settings for user $userId: $e');
      // Use default settings if everything fails
      await _createDefaultSettings(userId);
      notifyListeners();
    }
  }

  // Load settings from Firebase and save to local storage
  Future<void> _loadFromFirebaseAndSave(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final userData = doc.data();

      if (userData != null) {
        debugPrint(
            '🔧 SettingsService: Found existing user settings in Firebase');
        await _loadUserSettings(userData);

        // Save to local storage
        await _localDataSource.saveUserSettings(userId, userData);
        await _localDataSource.markUserSettingsAsSynced(userId);
      } else {
        debugPrint(
            '🔧 SettingsService: No Firebase settings found, creating defaults');
        await _createDefaultSettings(userId);
      }
    } catch (e) {
      debugPrint('🔧 SettingsService: Error loading from Firebase: $e');
      await _createDefaultSettings(userId);
    }
  }

  // Background sync with Firebase (non-blocking)
  void _backgroundSyncWithFirebase(String userId) async {
    try {
      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) return;

      final doc = await _firestore.collection('users').doc(userId).get();
      final firebaseData = doc.data();

      if (firebaseData != null) {
        final localSettings = await _localDataSource.getUserSettings(userId);

        // Compare timestamps or force sync (simplified approach: always sync from Firebase)
        await _loadUserSettings(firebaseData);
        await _localDataSource.saveUserSettings(userId, firebaseData);
        await _localDataSource.markUserSettingsAsSynced(userId);
        notifyListeners();

        debugPrint('🔧 SettingsService: Background sync completed');
      }
    } catch (e) {
      debugPrint('🔧 SettingsService: Background sync failed: $e');
    }
  }

  // Load user settings from data map
  Future<void> _loadUserSettings(Map<String, dynamic> userData) async {
    try {
      _currency = userData['currency'] ?? 'MYR';
      _theme = userData['theme'] ?? 'dark';

      final settings = userData['settings'] as Map<String, dynamic>? ?? {};
      _allowNotification = settings['allowNotification'] ?? true;
      _autoBudget = settings['autoBudget'] ?? false;
      _improveAccuracy = settings['improveAccuracy'] ?? false;

      debugPrint(
          '🔧 SettingsService: Loaded settings - currency=$_currency, theme=$_theme, allowNotification=$_allowNotification, autoBudget=$_autoBudget, improveAccuracy=$_improveAccuracy');
    } catch (e) {
      debugPrint('🔧 SettingsService: Error loading user settings: $e');
      rethrow;
    }
  }

  // Create default settings for new users with offline support
  Future<void> _createDefaultSettings(String userId) async {
    try {
      // Set the default values
      const defaultCurrency = 'MYR';
      const defaultTheme = 'dark';
      const defaultAllowNotification = true;
      const defaultAutoBudget = false;
      const defaultImproveAccuracy = false;

      final defaultSettings = {
        'currency': defaultCurrency,
        'theme': defaultTheme,
        'settings': {
          'allowNotification': defaultAllowNotification,
          'autoBudget': defaultAutoBudget,
          'improveAccuracy': defaultImproveAccuracy,
        },
      };

      // Save to local storage first
      await _localDataSource.saveUserSettings(userId, defaultSettings);

      // Try to sync with Firebase if connected
      final isConnected = await _connectivityService.isConnected;
      if (isConnected) {
        await _firestore.collection('users').doc(userId).set({
          'currency': defaultCurrency,
          'theme': defaultTheme,
          'settings': {
            'allowNotification': defaultAllowNotification,
            'autoBudget': defaultAutoBudget,
            'improveAccuracy': defaultImproveAccuracy,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _localDataSource.markUserSettingsAsSynced(userId);
      }

      // Update local state
      _currency = defaultCurrency;
      _theme = defaultTheme;
      _allowNotification = defaultAllowNotification;
      _autoBudget = defaultAutoBudget;
      _improveAccuracy = defaultImproveAccuracy;

      debugPrint(
          '🔧 SettingsService: Default settings created for user $userId');
    } catch (e) {
      debugPrint(
          '🔧 SettingsService: Error creating default settings for user $userId: $e');
      rethrow;
    }
  }

  // Reset all settings to default with offline support
  Future<void> resetToDefaults() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _createDefaultSettings(user.uid);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error resetting settings: $e');
    }
  }

  // Sync pending settings changes to Firebase when connection is restored
  Future<void> syncPendingChanges() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final isConnected = await _connectivityService.isConnected;
      if (!isConnected) return;

      debugPrint('🔧 SettingsService: Syncing pending settings changes');

      // Force sync current settings to Firebase
      await _firestore.collection('users').doc(user.uid).set({
        'currency': _currency,
        'theme': _theme,
        'settings': {
          'allowNotification': _allowNotification,
          'autoBudget': _autoBudget,
          'improveAccuracy': _improveAccuracy,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _localDataSource.markUserSettingsAsSynced(user.uid);

      debugPrint('🔧 SettingsService: Settings sync completed');
    } catch (e) {
      debugPrint('🔧 SettingsService: Error syncing settings: $e');
    }
  }

  // Update currency setting with offline support
  Future<void> updateCurrency(String newCurrency) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _currency = newCurrency;

        // Save to local storage first
        final settings = currentSettings;
        settings['currency'] = newCurrency;
        await _localDataSource.saveUserSettings(user.uid, settings);

        // Try to sync with Firebase if connected
        final isConnected = await _connectivityService.isConnected;
        if (isConnected) {
          await _firestore.collection('users').doc(user.uid).set({
            'currency': newCurrency,
          }, SetOptions(merge: true));

          await _localDataSource.markUserSettingsAsSynced(user.uid);
        }

        notifyListeners();
        debugPrint('Currency updated to: $newCurrency');
      }
    } catch (e) {
      debugPrint('Error updating currency: $e');
    }
  }

  // Update theme setting with offline support
  Future<void> updateTheme(String newTheme) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _theme = newTheme;

        // Save to local storage first
        final settings = currentSettings;
        settings['theme'] = newTheme;
        await _localDataSource.saveUserSettings(user.uid, settings);

        // Try to sync with Firebase if connected
        final isConnected = await _connectivityService.isConnected;
        if (isConnected) {
          await _firestore.collection('users').doc(user.uid).set({
            'theme': newTheme,
          }, SetOptions(merge: true));

          await _localDataSource.markUserSettingsAsSynced(user.uid);
        }

        notifyListeners();
        debugPrint('Theme updated to: $newTheme');
      }
    } catch (e) {
      debugPrint('Error updating theme: $e');
    }
  }

  // Update notification setting with offline support
  Future<void> updateNotificationSetting(bool allowNotification) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _allowNotification = allowNotification;

        // Save to local storage first
        await _localDataSource.saveUserSettings(user.uid, currentSettings);

        // Try to sync with Firebase if connected
        final isConnected = await _connectivityService.isConnected;
        if (isConnected) {
          await _firestore.collection('users').doc(user.uid).set({
            'settings': {
              'allowNotification': allowNotification,
              'autoBudget': _autoBudget,
              'improveAccuracy': _improveAccuracy,
            },
          }, SetOptions(merge: true));

          await _localDataSource.markUserSettingsAsSynced(user.uid);
        }

        notifyListeners();
        debugPrint('Notification setting updated to: $allowNotification');
      }
    } catch (e) {
      debugPrint('Error updating notification setting: $e');
    }
  }

  // Update auto budget setting with offline support
  Future<void> updateAutoBudgetSetting(bool autoBudget) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _autoBudget = autoBudget;

        // Save to local storage first
        await _localDataSource.saveUserSettings(user.uid, currentSettings);

        // Try to sync with Firebase if connected
        final isConnected = await _connectivityService.isConnected;
        if (isConnected) {
          await _firestore.collection('users').doc(user.uid).set({
            'settings': {
              'allowNotification': _allowNotification,
              'autoBudget': autoBudget,
              'improveAccuracy': _improveAccuracy,
            },
          }, SetOptions(merge: true));

          await _localDataSource.markUserSettingsAsSynced(user.uid);
        }

        notifyListeners();
        debugPrint('Auto budget setting updated to: $autoBudget');
      }
    } catch (e) {
      debugPrint('Error updating auto budget setting: $e');
    }
  }

  // Update improve accuracy setting with offline support
  Future<void> updateImproveAccuracySetting(bool improveAccuracy) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _improveAccuracy = improveAccuracy;

        // Save to local storage first
        await _localDataSource.saveUserSettings(user.uid, currentSettings);

        // Try to sync with Firebase if connected
        final isConnected = await _connectivityService.isConnected;
        if (isConnected) {
          await _firestore.collection('users').doc(user.uid).set({
            'settings': {
              'allowNotification': _allowNotification,
              'autoBudget': _autoBudget,
              'improveAccuracy': improveAccuracy,
            },
          }, SetOptions(merge: true));

          await _localDataSource.markUserSettingsAsSynced(user.uid);
        }

        notifyListeners();
        debugPrint('Improve accuracy setting updated to: $improveAccuracy');
      }
    } catch (e) {
      debugPrint('Error updating improve accuracy setting: $e');
    }
  }
}
