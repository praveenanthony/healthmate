import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String key = "isDarkMode";

  Future<ThemeMode> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(key) ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, isDarkMode);
  }

  Future<ThemeMode> toggleTheme(bool isDarkMode) async {
    final newMode = !isDarkMode;
    await saveTheme(newMode);
    return newMode ? ThemeMode.dark : ThemeMode.light;
  }
}