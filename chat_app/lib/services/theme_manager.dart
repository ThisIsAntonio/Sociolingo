import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static const _key = 'themeMode';

  static Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    // Guardar el tema como un string porque SharedPreferences no soporta directamente guardar enumeraciones
    await prefs.setString(_key, themeMode.toString());
  }

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_key) ?? '';
    // Convertir el string guardado de nuevo a un ThemeMode
    return themeModeString == 'ThemeMode.dark'
        ? ThemeMode.dark
        : themeModeString == 'ThemeMode.light'
            ? ThemeMode.light
            : ThemeMode.system; // Valor predeterminado
  }
}
