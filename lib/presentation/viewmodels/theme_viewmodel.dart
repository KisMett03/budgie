import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ThemeViewModel extends ChangeNotifier {
  bool _isDarkMode = false;
  String _currentTheme = 'light';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isDarkMode => _isDarkMode;
  String get currentTheme => _currentTheme;

  ThemeData get theme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  ThemeViewModel() {
    _loadThemeFromUser();
  }

  Future<void> _loadThemeFromUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final userData = doc.data();
        if (userData != null && userData.containsKey('theme')) {
          setTheme(userData['theme'] as String);
        }
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setTheme(String theme) async {
    if (theme == _currentTheme) return;

    _currentTheme = theme;
    _isDarkMode = theme == 'dark';
    notifyListeners();

    debugPrint('Theme changed to: $theme');

    // 保存主题设置到用户记录
    await _saveThemeToUser();
  }

  Future<void> _saveThemeToUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'theme': _currentTheme,
        }, SetOptions(merge: true));
        debugPrint('Theme saved to user record');
      }
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    final newTheme = _isDarkMode ? 'light' : 'dark';
    await setTheme(newTheme);
  }

  // 根据具体主题模式返回相应颜色
  Color getThemeColor(Color lightColor, Color darkColor) {
    return _isDarkMode ? darkColor : lightColor;
  }
}
