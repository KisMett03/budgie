import '../entities/user.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  Future<User?> getCurrentUser();
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> updateProfile({String? displayName, String? photoUrl});
  Future<User> signInWithGoogle();
  Future<void> updateUserSettings({String? currency, String? theme});
}
