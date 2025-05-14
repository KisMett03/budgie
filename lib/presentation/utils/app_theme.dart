import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';
import 'category_manager.dart';

/// 应用主题管理类
class AppTheme {
  /// 亮色主题颜色
  static const Color primaryColor = Color(0xFFF57C00);
  static const Color secondaryColor = Color(0xFF2196F3);
  static const Color errorColor = Color(0xFFE91E63);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color backgroundLight = Color(0xFFF7FCFC);
  static const Color darkBackgroundLight = Color(0xFF333333);
  static const Color cardBackgroundLight = Color(0xfffafafa);
  static const Color lightTextLight = Color(0xFFFBFCF8);
  static const Color darkTextLight = Color(0xFF1A1A19);
  static const Color greyTextLight = Color(0xFF607D8B);
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color profileBackgroundLight = Color(0xff1A1A19);
  static const Color appBarBackgroundLight = Color(0xFFF5F5F5);
  static const Color appBarForegroundLight = Color(0xFF333333);

  /// 暗色主题颜色
  static const Color primaryColorDark = Color(0xFFF57C00);
  static const Color secondaryColorDark = Color(0xFF64B5F6);
  static const Color errorColorDark = Color(0xFFF06292);
  static const Color successColorDark = Color(0xFF81C784);
  static const Color warningColorDark = Color(0xFFFFD54F);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardBackgroundDark = Color(0xFF1E1E1E);
  static const Color lightTextDark = Color(0xFFFFFFFF);
  static const Color darkTextDark = Color(0xFFE0E0E0);
  static const Color greyTextDark = Color(0xFFB0BEC5);
  static const Color dividerDark = Color(0xFF424242);
  static const Color profileBackgroundDark = Color(0xff121212);
  static const Color appBarBackgroundDark = Color(0xFF1D1D1D);
  static const Color appBarForegroundDark = Color(0xFFFFFFFF);

  /// 字体
  static const String fontFamily = 'Lexend';

  /// 圆角半径
  static const double borderRadius = 15.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 25.0;

  /// 获取类别颜色
  static Color getCategoryColor(Category category) {
    return CategoryManager.getColor(category);
  }

  /// 获取应用的亮色主题
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundLight,
      canvasColor: backgroundLight,
      cardColor: cardBackgroundLight,
      dividerColor: dividerLight,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundLight,
        surface: cardBackgroundLight,
        onPrimary: lightTextLight,
        onSecondary: lightTextLight,
        onBackground: darkTextLight,
        onSurface: darkTextLight,
        onError: lightTextLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBackgroundLight,
        foregroundColor: appBarForegroundLight,
        elevation: 0,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(color: appBarForegroundLight),
        actionsIconTheme: IconThemeData(color: appBarForegroundLight),
        titleTextStyle: TextStyle(
          color: appBarForegroundLight,
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkTextLight),
        displayMedium: TextStyle(color: darkTextLight),
        displaySmall: TextStyle(color: darkTextLight),
        headlineMedium: TextStyle(color: darkTextLight),
        headlineSmall: TextStyle(color: darkTextLight),
        titleLarge: TextStyle(color: darkTextLight),
        titleMedium: TextStyle(color: darkTextLight),
        titleSmall: TextStyle(color: darkTextLight),
        bodyLarge: TextStyle(color: darkTextLight),
        bodyMedium: TextStyle(color: darkTextLight),
        bodySmall: TextStyle(color: greyTextLight),
        labelLarge: TextStyle(color: lightTextLight),
        labelMedium: TextStyle(color: greyTextLight),
      ),
      fontFamily: fontFamily,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: lightTextLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: greyTextLight),
        hintStyle: TextStyle(color: greyTextLight.withOpacity(0.7)),
      ),
      cardTheme: CardTheme(
        color: cardBackgroundLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) return primaryColor;
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected))
            return primaryColor.withOpacity(0.5);
          return Colors.grey.shade300;
        }),
      ),
      iconTheme: IconThemeData(color: greyTextLight),
      primaryIconTheme: IconThemeData(color: primaryColor),
    );
  }

  /// 获取应用的暗色主题
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      brightness: Brightness.dark,
      primaryColor: primaryColorDark,
      scaffoldBackgroundColor: backgroundDark,
      canvasColor: backgroundDark,
      cardColor: cardBackgroundDark,
      dividerColor: dividerDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColorDark,
        secondary: secondaryColorDark,
        error: errorColorDark,
        background: backgroundDark,
        surface: cardBackgroundDark,
        onPrimary: lightTextDark,
        onSecondary: lightTextDark,
        onBackground: darkTextDark,
        onSurface: darkTextDark,
        onError: lightTextDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBackgroundDark,
        foregroundColor: appBarForegroundDark,
        elevation: 0,
        shadowColor: Colors.black26,
        iconTheme: IconThemeData(color: appBarForegroundDark),
        actionsIconTheme: IconThemeData(color: appBarForegroundDark),
        titleTextStyle: TextStyle(
          color: appBarForegroundDark,
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: lightTextDark),
        displayMedium: TextStyle(color: lightTextDark),
        displaySmall: TextStyle(color: lightTextDark),
        headlineMedium: TextStyle(color: lightTextDark),
        headlineSmall: TextStyle(color: lightTextDark),
        titleLarge: TextStyle(color: lightTextDark),
        titleMedium: TextStyle(color: lightTextDark),
        titleSmall: TextStyle(color: lightTextDark),
        bodyLarge: TextStyle(color: lightTextDark),
        bodyMedium: TextStyle(color: lightTextDark),
        bodySmall: TextStyle(color: greyTextDark),
        labelLarge: TextStyle(color: lightTextDark),
        labelMedium: TextStyle(color: greyTextDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColorDark,
          foregroundColor: lightTextDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        filled: true,
        fillColor: cardBackgroundDark,
        labelStyle: TextStyle(color: greyTextDark),
        hintStyle: TextStyle(color: greyTextDark.withOpacity(0.7)),
      ),
      cardTheme: CardTheme(
        color: cardBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) return primaryColorDark;
          return Colors.grey.shade600;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected))
            return primaryColorDark.withOpacity(0.5);
          return Colors.grey.shade700;
        }),
      ),
      iconTheme: IconThemeData(color: greyTextDark),
      primaryIconTheme: IconThemeData(color: primaryColorDark),
    );
  }
}
