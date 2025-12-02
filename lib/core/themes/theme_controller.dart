import 'dart:ui';

import 'package:cc98_ocean/core/constants/color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier{
  static const String _kTheme = 'theme';
  static const String _kThemeColor = 'theme_color';

  int _themeMode = 0; // 0: system, 1: light, 2: dark
  Color _primaryColor = ColorTokens.softPurple;

  AppState() {
    _loadFromPrefs();
  }

  int get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;

  ThemeMode get themeModeEnum {
    return _themeMode == 1
        ? ThemeMode.light
        : (_themeMode == 2 ? ThemeMode.dark : ThemeMode.system);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = prefs.getInt(_kTheme) ?? 0;
    final int? colorVal = prefs.getInt(_kThemeColor);
    if (colorVal != null) {
      _primaryColor = Color(colorVal);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(int mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTheme, mode);
    notifyListeners();
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeColor, color.value);
    notifyListeners();
  }
}