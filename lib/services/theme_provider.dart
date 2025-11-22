import 'package:flutter/material.dart';
import 'theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  final ThemeService _service = ThemeService();

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _themeMode = await _service.getTheme();
    notifyListeners(); // rebuild MaterialApp
  }

  Future<void> toggleTheme() async {
    final isDark = _themeMode == ThemeMode.dark;
    _themeMode = await _service.toggleTheme(isDark);
    notifyListeners(); // rebuild MaterialApp
  }
}
