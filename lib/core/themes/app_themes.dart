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
    brightness: Brightness.light,
    dividerColor: ColorTokens.dividerBlue,
    appBarTheme: const AppBarTheme(elevation: 0),
    fontFamily: "Hm Sans"
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: ColorTokens.primaryDark,
      surface: ColorTokens.surfaceDark,
    ),
    brightness: Brightness.dark,
    dividerColor: ColorTokens.dividerGrey,
    fontFamily: "Hm Sans"
  );
}