import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'isDarkMode';
  static const Color _seedColor = Color(0xFF2196F3);
  static const double _defaultBorderRadius = 12.0;

  ThemeMode _themeMode = ThemeMode.light;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _initTheme();
  }

  Future<void> _initTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final isDark = _prefs?.getBool(_themePrefKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_themePrefKey, isDarkMode);

    notifyListeners();
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final borderRadius = BorderRadius.circular(_defaultBorderRadius);
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: borderRadius),
        filled: true,
      ),
    );
  }

  // Cache theme instances for better performance
  static final ThemeData lightTheme = _buildTheme(Brightness.light);
  static final ThemeData darkTheme = _buildTheme(Brightness.dark);
}
