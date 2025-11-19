import 'package:flutter/material.dart';
import '../constants/color_tokens.dart';
///提供基础主题实现。
///存储colorscheme,以便复用
class AppThemes {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    hoverColor: ColorTokens.primaryLight.withOpacity(0.12),
    colorScheme: ColorScheme.light(
      primary: ColorTokens.primaryLight,
      surface: ColorTokens.surfaceLight,
    ),
    // 如果想让旧组件自动取新色，可再包一层
    appBarTheme: const AppBarTheme(elevation: 0),
    fontFamily: 'Arial'
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: ColorTokens.primaryDark,
      surface: ColorTokens.surfaceDark,
    ),
  );
}