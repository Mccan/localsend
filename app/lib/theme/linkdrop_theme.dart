import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/util/native/platform_check.dart';

/// LinkDrop 颜色定义
///
/// 主色调: 金棕色系 (#d4a574) - 与 Mute 播放器视觉统一
class LinkDropColors {
  // ===== 主色调 - 金棕色系 =====
  static const primary = Color(0xFFd4a574); // 金棕主色
  static const primaryDark = Color(0xFFc17f59); // 金棕深 (悬停)
  static const primaryLight = Color(0xFFfdfbf8); // 金棕浅 (选中背景)
  static const primaryBorder = Color(0xFFe8dfd3); // 金棕边框
  static const primaryText = Color(0xFFb8956a); // 金棕文字

  // ===== 背景色 =====
  static const white = Color(0xFFFFFFFF);
  static const backgroundLight = Color(0xFFFAFAFA); // Zinc-50
  static const backgroundDark = Color(0xFF09090B); // Zinc-950
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF18181B); // Zinc-900

  // ===== 文字色 =====
  static const textPrimary = Color(0xFF1a1a1a); // 深黑
  static const textSecondary = Color(0xFF666666); // 中灰
  static const textTertiary = Color(0xFF999999); // 浅灰
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFa0a0a0);

  // ===== 边框色 =====
  static const borderLight = Color(0xFFE8E8E8);
  static const borderDark = Color(0xFF27272A); // Zinc-800

  // ===== Zinc 色系 (中性色) =====
  static const zinc50 = Color(0xFFFAFAFA);
  static const zinc100 = Color(0xFFF4F4F5);
  static const zinc200 = Color(0xFFE4E4E7);
  static const zinc300 = Color(0xFFD4D4D8);
  static const zinc400 = Color(0xFFA1A1AA);
  static const zinc500 = Color(0xFF71717A); // Secondary text
  static const zinc600 = Color(0xFF52525B);
  static const zinc700 = Color(0xFF3F3F46);
  static const zinc800 = Color(0xFF27272A);
  static const zinc900 = Color(0xFF18181B);
  static const zinc950 = Color(0xFF09090B);

  // ===== 功能色 =====
  static const success = Color(0xFF18a058);
  static const error = Color(0xFFff6b6b);
  static const warning = Color(0xFFf0a020);
  static const info = Color(0xFF2080f0);

  // ===== 阴影色 =====
  static const shadowLight = Color(0x14000000); // 8% 黑色
  static const shadowPrimary = Color(0x26d4a574); // 15% 金棕

  // ===== 兼容旧代码的颜色别名 =====
  static const teal500 = primary; // 保持向后兼容
  static const teal600 = primaryDark; // 保持向后兼容
  static const red500 = error;
  static const orange500 = warning;

  // ===== 渐变 =====
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryLight, Color(0xFFf9f5f0)],
  );
}

/// 获取 LinkDrop 主题
ThemeData getLinkDropTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // Define ColorScheme
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: LinkDropColors.primary,
    onPrimary: Colors.white,
    secondary: LinkDropColors.primary,
    onSecondary: Colors.white,
    error: LinkDropColors.error,
    onError: Colors.white,
    surface: isDark ? LinkDropColors.cardDark : LinkDropColors.cardLight,
    onSurface: isDark ? LinkDropColors.textPrimaryDark : LinkDropColors.textPrimary,
    surfaceContainer: isDark ? LinkDropColors.backgroundDark : LinkDropColors.backgroundLight,
  );

  // Font Family Logic
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
    scaffoldBackgroundColor: isDark ? LinkDropColors.backgroundDark : LinkDropColors.backgroundLight,
    fontFamily: fontFamily,

    // Card Theme - 统一卡片样式
    cardTheme: CardThemeData(
      color: isDark ? LinkDropColors.cardDark : LinkDropColors.cardLight,
      elevation: 0,
      shadowColor: LinkDropColors.shadowPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? LinkDropColors.borderDark : LinkDropColors.borderLight,
          width: 1,
        ),
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? LinkDropColors.backgroundDark : LinkDropColors.backgroundLight,
      foregroundColor: isDark ? LinkDropColors.textPrimaryDark : LinkDropColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),

    // Navigation Bar Theme - 金棕选中色
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? LinkDropColors.backgroundDark : LinkDropColors.cardLight,
      indicatorColor: isDark
          ? LinkDropColors.primary.withValues(alpha: 0.15)
          : LinkDropColors.primaryLight,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: isDark ? Colors.white : LinkDropColors.primaryDark);
        }
        return IconThemeData(color: LinkDropColors.zinc500);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: isDark ? Colors.white : LinkDropColors.primaryDark,
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
      color: isDark ? LinkDropColors.borderDark : LinkDropColors.borderLight,
      thickness: 1,
    ),

    // Switch Theme - 金棕激活色
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return LinkDropColors.primary;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return LinkDropColors.primary.withValues(alpha: 0.5);
        }
        return null;
      }),
    ),

    // Elevated Button Theme - 金棕渐变
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LinkDropColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LinkDropColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? LinkDropColors.zinc800 : LinkDropColors.zinc100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? LinkDropColors.zinc700 : LinkDropColors.zinc200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: LinkDropColors.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    ),
  );
}

/// ThemeData 扩展
extension ThemeDataExt on ThemeData {
  /// This is the actual [cardColor] being used.
  Color get cardColorWithElevation {
    return ElevationOverlay.applySurfaceTint(cardColor, colorScheme.surfaceTint, 1);
  }
}

/// ColorScheme 扩展
extension ColorSchemeExt on ColorScheme {
  Color get warning {
    return Colors.orange;
  }

  Color? get secondaryContainerIfDark {
    return brightness == Brightness.dark ? secondaryContainer : null;
  }

  Color? get onSecondaryContainerIfDark {
    return brightness == Brightness.dark ? onSecondaryContainer : null;
  }
}