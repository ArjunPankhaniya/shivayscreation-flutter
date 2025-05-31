// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This class should be the core logic for your theme.
// It uses `ChangeNotifier` to notify listeners (like your UI) when the theme changes.
class ThemeProvider with ChangeNotifier {
  // Define a key for storing the theme mode in SharedPreferences
  static const String _themeModeKey = 'themeMode';
  ThemeMode _themeMode = ThemeMode.light; // Default theme

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode(); // Load the saved theme preference when the provider is created
  }

  // Asynchronously loads the saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Get the saved boolean for dark mode, defaulting to false (light mode) if not found
    final isDarkMode = prefs.getBool(_themeModeKey) ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notify listeners after loading the theme
  }

  // Toggles the theme between light and dark mode
  Future<void> toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    // Save the new theme preference
    await prefs.setBool(_themeModeKey, isDarkMode);
    notifyListeners(); // Notify listeners that the theme has changed
  }
}