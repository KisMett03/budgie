import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? _initFirebaseAuth(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
            );

  // Initialize Firebase Auth with persistence settings
  static firebase_auth.FirebaseAuth _initFirebaseAuth() {
    final auth = firebase_auth.FirebaseAuth.instance;

    // Set persistence to LOCAL (this helps with auth state persistence)
    auth.setPersistence(firebase_auth.Persistence.LOCAL);

    debugPrint('Firebase Auth initialized with LOCAL persistence');
    return auth;
  }

  @override
  Stream<domain.User?> get authStateChanges =>
      _auth.authStateChanges().map((firebaseUser) {
        if (firebaseUser == null) return null;
        return _mapFirebaseUserToDomain(firebaseUser);
      });

  // Map Firebase user to domain User - handle potential null values
  domain.User _mapFirebaseUserToDomain(firebase_auth.User user) {
    final displayName = user.displayName?.isNotEmpty == true
        ? user.displayName
        : 'User ${user.uid.substring(0, 5)}';

    return domain.User(
      id: user.uid,
      email: user.email ?? '', // Handle null email
      displayName: displayName,
      photoUrl: user.photoURL,
    );
  }

  @override
  Future<domain.User?> getCurrentUser() async {
    try {
      // First reload to ensure we have the latest user data
      await _auth.currentUser?.reload();

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('getCurrentUser: No current user found');
        return null;
      }

      debugPrint(
          'getCurrentUser: Found user: ${user.uid}, email: ${user.email}');
      return _mapFirebaseUserToDomain(user);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      // Return null instead of throwing to avoid crashes
      return null;
    }
  }

  @override
  Future<domain.User> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in: No user returned');
      }
      return _mapFirebaseUserToDomain(user);
    } catch (e) {
      debugPrint('Email sign-in error: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  @override
  Future<domain.User> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user: No user returned');
      }
      return _mapFirebaseUserToDomain(user);
    } catch (e) {
      debugPrint('Create user error: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  @override
  Future<domain.User> signInWithGoogle() async {
    try {
      debugPrint('Starting simplified Google sign-in flow');

      // 1. Clear previous sessions
      try {
        await _googleSignIn.signOut();
        debugPrint('Cleared previous Google session');
      } catch (e) {
        debugPrint('Error clearing Google session: $e');
        // Continue anyway
      }

      // 2. Start Google sign-in process
      debugPrint('Showing Google sign-in dialog');
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('User canceled Google sign-in');
        throw Exception('Sign-in canceled');
      }

      debugPrint('Google sign-in successful: ${googleUser.email}');

      // 3. Get authentication tokens
      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint('Failed to get Google ID token');
        throw Exception('Authentication failed - missing ID token');
      }

      // 4. Create Firebase credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign in to Firebase
      debugPrint('Signing in to Firebase with Google credential');
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        debugPrint('Firebase sign-in failed - null user');
        throw Exception('Sign-in failed');
      }

      debugPrint('Firebase sign-in successful: ${user.uid}');

      // 6. Immediately return the mapped user without any additional processing
      final domainUser = domain.User(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? googleUser.displayName ?? 'User',
        photoUrl: user.photoURL ?? googleUser.photoUrl,
      );

      debugPrint('Returning user: ${domainUser.id}');
      return domainUser;
    } catch (e) {
      debugPrint('Google sign-in error: $e');

      if (e.toString().contains('network_error') ||
          e.toString().contains('ApiException: 7')) {
        throw Exception(
            'Network connection issue. Check your internet connection and try again.');
      }

      throw Exception('Failed to sign in with Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      debugPrint('Starting sign out process');

      // Sign out from Google first
      try {
        await _googleSignIn.signOut();
        debugPrint('Successfully signed out from Google');
      } catch (e) {
        debugPrint('Error signing out from Google: $e');
        // Continue with Firebase sign out
      }

      // Then sign out from Firebase
      await _auth.signOut();
      debugPrint('Successfully signed out from Firebase');
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to $email');
    } catch (e) {
      debugPrint('Password reset error: $e');
      throw Exception('Failed to reset password: $e');
    }
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Cannot update profile: No authenticated user');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      await user.reload();
      debugPrint('Profile updated successfully');
    } catch (e) {
      debugPrint('Update profile error: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
}
