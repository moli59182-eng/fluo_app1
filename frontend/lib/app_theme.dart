import 'package:flutter/material.dart';

class AppTheme {
  // 精致小清新配色
  static const primaryColor = Color(0xFF5B9FED); // 清新蓝
  static const secondaryColor = Color(0xFFFF9A8B); // 柔和橙粉
  static const accentColor = Color(0xFFA8B5FF); // 淡紫蓝
  static const successColor = Color(0xFF7FD8BE); // 薄荷绿
  static const warningColor = Color(0xFFFFCB77); // 柔和黄
  static const errorColor = Color(0xFFFF8B94); // 柔和红
  
  // 背景色
  static const backgroundColor = Color(0xFFF7F8FC); // 极淡蓝灰
  static const surfaceColor = Color(0xFFFFFFFF);
  static const cardColor = Color(0xFFFAFBFF);
  
  // 文字颜色
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
  static const textTertiary = Color(0xFFCBD5E0);
  
  // 分割线
  static const dividerColor = Color(0xFFE2E8F0);
  
  // 柔和渐变
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF5B9FED), Color(0xFF7DB8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const warmGradient = LinearGradient(
    colors: [Color(0xFFFF9A8B), Color(0xFFFFB4A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const purpleGradient = LinearGradient(
    colors: [Color(0xFFA8B5FF), Color(0xFFC0CBFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const greenGradient = LinearGradient(
    colors: [Color(0xFF7FD8BE), Color(0xFF9FE7D0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surfaceColor,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
  
  // 精致阴影
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];
}
