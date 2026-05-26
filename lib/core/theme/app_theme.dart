import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // 纯灰度设计系统 - iOS 26 Liquid Glass 风格
  
  // 背景色
  static const Color bgPrimary = Color(0xFF000000);
  static const Color bgSecondary = Color(0xFF1C1C1E);
  static const Color bgTertiary = Color(0xFF2C2C2E);
  
  // 玻璃效果背景
  static const Color glassBg = Color(0x0FFFFFFF);  // 6% white
  static const Color glassBgHover = Color(0x14FFFFFF);  // 8% white
  static const Color glassBorder = Color(0x14FFFFFF);  // 8% white
  static const Color glassBorderStrong = Color(0x24FFFFFF);  // 14% white
  
  // 文字颜色
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF);  // 60% white
  static const Color textTertiary = Color(0x59FFFFFF);  // 35% white
  static const Color textQuaternary = Color(0x33FFFFFF);  // 20% white
  
  // 状态颜色（灰度）
  static const Color danger = Color(0xFFFF453A);  // 删除用红色（必需）
  static const Color success = Color(0xFF30D158);  // 成功用绿色（必需）
  
  // 间距系统
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacing2xl = 48;
  
  // 圆角系统
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 28;
  static const double radiusFull = 9999;
  
  // 字体系统 - 使用系统默认字体
  static const String fontFamily = '-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica, Arial, sans-serif';
  
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: textPrimary,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: textPrimary,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: textPrimary,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: textPrimary,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    color: textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textTertiary,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  // 玻璃按钮样式
  static BoxDecoration glassButton = BoxDecoration(
    color: glassBg,
    borderRadius: BorderRadius.circular(radiusFull),
    border: Border.all(
      color: glassBorder,
      width: 1,
    ),
  );
  
  static BoxDecoration glassButtonHover = BoxDecoration(
    color: glassBgHover,
    borderRadius: BorderRadius.circular(radiusFull),
    border: Border.all(
      color: glassBorderStrong,
      width: 1,
    ),
  );
  
  // 卡片玻璃效果
  static BoxDecoration glassCard = BoxDecoration(
    color: glassBg,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(
      color: glassBorder,
      width: 0.5,
    ),
  );
  
  static BoxDecoration glassCardStrong = BoxDecoration(
    color: glassBgHover,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(
      color: glassBorderStrong,
      width: 0.5,
    ),
  );
  
  // 主题数据
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: textPrimary,
        secondary: textSecondary,
        surface: bgSecondary,
        background: bgPrimary,
        error: danger,
        onPrimary: bgPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: titleMedium,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSecondary,
        selectedItemColor: textPrimary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: glassBorder,
        thickness: 0.5,
      ),
    );
  }
}
