import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/util/native/platform_check.dart';

class LinkDropColors {
  // Primary - Teal
  static const teal500 = Color(0xFF14B8A6);
  static const teal600 = Color(0xFF0D9488);

  // Backgrounds
  static const zinc50 = Color(0xFFFAFAFA);
  static const white = Color(0xFFFFFFFF);
  static const zinc950 = Color(0xFF09090B);
  static const zinc900 = Color(0xFF18181B);

  // Neutrals / Borders
  static const zinc200 = Color(0xFFE4E4E7);
  static const zinc300 = Color(0xFFD4D4D8);
  static const zinc400 = Color(0xFFA1A1AA);
  static const zinc700 = Color(0xFF3F3F46);
  static const zinc800 = Color(0xFF27272A);
  
  // Text
  static const zinc500 = Color(0xFF71717A); // Secondary text
}

ThemeData getLinkDropTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // Define ColorScheme
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: LinkDropColors.teal500, 
    onPrimary: Colors.white,
    secondary: LinkDropColors.teal500,
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: isDark ? LinkDropColors.zinc900 : LinkDropColors.white,
    onSurface: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF18181B), // Zinc-200 : Zinc-900
    surfaceContainer: isDark ? LinkDropColors.zinc950 : LinkDropColors.zinc50, // Background
  );

  // Font Family Logic (Copied from original theme.dart)
  final String? fontFamily;
  if (checkPlatform([TargetPlatform.windows])) {
    fontFamily = switch (LocaleSettings.currentLocale) {
      AppLocale.ja => 'Yu Gothic UI',
      AppLocale.ko => 'Malgun Gothic',
      AppLocale.zhCn => 'Microsoft YaHei UI',
      AppLocale.zhHk || AppLocale.zhTw => 'Microsoft JhengHei UI',
      _ => 'Segoe UI Variable Display',
    };
  } else if (checkPlatform([TargetPlatform.linux])) {
    fontFamily = switch (LocaleSettings.currentLocale) {
      AppLocale.ja => 'Noto Sans CJK JP',
      AppLocale.ko => 'Noto Sans CJK KR',
      AppLocale.zhCn => 'Noto Sans CJK SC',
      AppLocale.zhHk || AppLocale.zhTw => 'Noto Sans CJK TC',
      _ => 'Noto Sans',
    };
  } else {
    fontFamily = null;
  }

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark ? LinkDropColors.zinc950 : LinkDropColors.zinc50,
    fontFamily: fontFamily,
    
    // Card Theme
    cardTheme: CardThemeData(
      color: isDark ? LinkDropColors.zinc900 : LinkDropColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Squircle-ish
        side: BorderSide(
          color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200,
          width: 1,
        ),
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? LinkDropColors.zinc950 : LinkDropColors.zinc50,
      foregroundColor: isDark ? Colors.white : const Color(0xFF18181B),
      elevation: 0,
      centerTitle: false,
    ),

    // Navigation Bar (Bottom)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? LinkDropColors.zinc950 : LinkDropColors.white,
      indicatorColor: isDark ? LinkDropColors.zinc800 : LinkDropColors.teal500.withOpacity(0.1),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: isDark ? Colors.white : LinkDropColors.teal600);
        }
        return IconThemeData(color: LinkDropColors.zinc500);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: isDark ? Colors.white : LinkDropColors.teal600,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          );
        }
        return const TextStyle(
          color: LinkDropColors.zinc500,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        );
      }),
    ),
    
    // Divider
    dividerTheme: DividerThemeData(
      color: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc200,
      thickness: 1,
    ),
  );
}
