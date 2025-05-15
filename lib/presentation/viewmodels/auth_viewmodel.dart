import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';
import '../../core/utils/performance_monitor.dart';
import '../../core/errors/app_error.dart';
import '../../core/services/sync_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SyncService _syncService;
  domain.User? _currentUser;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<domain.User?>? _authSubscription;

  AuthViewModel({
    required AuthRepository authRepository,
    required SyncService syncService,
  })  : _authRepository = authRepository,
        _syncService = syncService {
    _initAuth();
  }

  domain.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _initAuth() async {
    try {
      debugPrint('Initializing AuthViewModel');
      _isLoading = true;
      notifyListeners();

      // Get current user
      _currentUser = await _authRepository.getCurrentUser();

      // 如果用户已登录，初始化本地数据
      if (_currentUser != null) {
        await _syncService.initializeLocalDataOnLogin(_currentUser!.id);
      }

      // Listen for auth state changes
      _authSubscription = _authRepository.authStateChanges.listen((user) {
        debugPrint('Auth state changed: ${user?.id ?? 'Not logged in'}');
        _currentUser = user;

        // 当用户登录时，初始化本地数据
        if (user != null) {
          _syncService.initializeLocalDataOnLogin(user.id);
        }

        notifyListeners();
      }, onError: (error) {
        debugPrint('Auth state stream error: $error');
      });

      debugPrint(
          'Auth initialization complete. User: ${_currentUser?.id ?? 'Not logged in'}');
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _error = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh authentication state to ensure current user info is up-to-date
  Future<void> refreshAuthState() async {
    try {
      debugPrint('Refreshing auth state');
      PerformanceMonitor.startTimer('refresh_auth_state');
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get fresh user data
      _currentUser = await _authRepository.getCurrentUser();

      // Additional debug info
      debugPrint('Refreshed user: ${_currentUser?.id ?? 'Not logged in'}');
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      debugPrint('Firebase user: ${firebaseUser?.uid ?? 'Not logged in'}');

      // Handle potential state mismatch
      if (firebaseUser != null && _currentUser == null) {
        debugPrint(
            'State mismatch detected: Firebase user exists but domain user is null');
        await firebaseUser.reload();
        _currentUser = await _authRepository.getCurrentUser();
      }
    } catch (e) {
      debugPrint('Error refreshing auth state: $e');
      _error = 'Failed to refresh authentication state';
      _currentUser = null;
    } finally {
      _isLoading = false;
      PerformanceMonitor.stopTimer('refresh_auth_state');
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'Email and password cannot be empty';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Signing in with email: $email');
      final user =
          await _authRepository.signInWithEmailAndPassword(email, password);
      _currentUser = user;
      debugPrint('Successfully signed in: ${user.id}');

      // 登录成功后，初始化本地数据
      await _syncService.initializeLocalDataOnLogin(user.id);
    } catch (e) {
      debugPrint('Sign in error: $e');
      _error = 'Failed to sign in: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'Email and password cannot be empty';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Creating account with email: $email');
      final user =
          await _authRepository.createUserWithEmailAndPassword(email, password);
      _currentUser = user;
      debugPrint('Successfully created account: ${user.id}');
    } catch (e) {
      debugPrint('Sign up error: $e');
      _error = 'Failed to create account: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('AuthViewModel: Starting simplified Google sign-in');

      // Call repository for Google sign-in
      final user = await _authRepository.signInWithGoogle();

      // Set current user directly
      _currentUser = user;

      // Verify we have a valid user
      if (_currentUser == null || _currentUser!.id.isEmpty) {
        debugPrint('AuthViewModel: Invalid user returned from repository');
        throw Exception('Authentication failed - Invalid user');
      }

      debugPrint(
          'AuthViewModel: Sign-in successful - User ID: ${_currentUser!.id}');

      // 登录成功后，初始化本地数据
      await _syncService.initializeLocalDataOnLogin(_currentUser!.id);
    } catch (e) {
      debugPrint('AuthViewModel: Google sign-in error: $e');

      // Set appropriate error message
      if (e.toString().contains('network')) {
        _error =
            'Network connection issue. Please check your internet connection and try again.';
      } else if (e.toString().contains('cancel')) {
        _error = 'Sign-in was cancelled';
      } else if (e.toString().contains('credential')) {
        _error = 'Authentication failed. Please try again.';
      } else {
        _error = 'Failed to sign in with Google: ${e.toString()}';
      }

      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Signing out');
      await _authRepository.signOut();
      _currentUser = null;
      debugPrint('Successfully signed out');
    } catch (e) {
      debugPrint('Sign out error: $e');
      _error = 'Failed to sign out: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      _error = 'Email cannot be empty';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Sending password reset email to: $email');
      await _authRepository.resetPassword(email);
      debugPrint('Password reset email sent');
    } catch (e) {
      debugPrint('Password reset error: $e');
      _error = 'Failed to reset password: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 手动触发数据同步
  Future<void> syncData() async {
    if (_currentUser == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _syncService.syncData();
    } catch (e) {
      debugPrint('Sync error: $e');
      _error = 'Failed to sync data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Updating profile: name=$displayName, photo=$photoUrl');
      await _authRepository.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );

      // Refresh user data after update
      _currentUser = await _authRepository.getCurrentUser();
      debugPrint('Profile updated successfully');
    } catch (e) {
      debugPrint('Profile update error: $e');
      _error = 'Failed to update profile: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 用于更新用户设置
  Future<void> updateUserSettings({String? currency, String? theme}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Updating user settings: currency=$currency, theme=$theme');
      await _authRepository.updateUserSettings(
        currency: currency,
        theme: theme,
      );

      // 刷新用户数据
      _currentUser = await _authRepository.getCurrentUser();
      debugPrint('User settings updated successfully');
    } catch (e) {
      debugPrint('User settings update error: $e');
      _error = 'Failed to update user settings: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
