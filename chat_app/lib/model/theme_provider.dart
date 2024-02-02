import 'package:flutter/material.dart';
import 'package:chat_app/services/theme_manager.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  set themeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    ThemeManager.saveThemeMode(themeMode);
    notifyListeners();
  }

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    _themeMode = await ThemeManager.getThemeMode();
    notifyListeners();
  }
}
