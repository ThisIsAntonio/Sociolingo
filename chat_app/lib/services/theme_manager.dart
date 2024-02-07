import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  // Key for accessing theme mode in SharedPreferences
  static const _key = 'themeMode';

  // Save the theme mode to SharedPreferences
  static Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    // Save the theme as a string because SharedPreferences doesn't directly support saving enums
    await prefs.setString(_key, themeMode.toString());
  }

  // Retrieve the theme mode from SharedPreferences
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_key) ?? '';
    // Convert the saved string back to a ThemeMode
    return themeModeString == 'ThemeMode.dark'
        ? ThemeMode.dark
        : themeModeString == 'ThemeMode.light'
            ? ThemeMode.light
            : ThemeMode.system; // Default value
  }
}
