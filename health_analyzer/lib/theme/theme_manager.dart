import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_utils.dart';

/// Manages theme preferences including theme selection and AMOLED mode
/// Provides persistence using SharedPreferences
class ThemeManager {
  static const String _themePreferenceKey = 'selected_theme';
  static const String _amoledModeKey = 'amoled_mode_enabled';
  static const String _themeModeKey = 'theme_mode_setting';

  /// Available theme colors for the app
  /// Users can choose from these predefined themes or use system adaptive theme
  static const Map<String, Color> themeColors = {
    'Adaptive Theme':
        Colors.blueGrey, // Uses system wallpaper colors (Material You)
    'Medical Blue': Color(0xFF2563EB), // LabLens brand blue
    'Health Green': Color(0xFF10B981), // Health/wellness green
    'Clinical Purple': Color(0xFF8B5CF6), // Professional purple
    'Sky Cyan': Colors.cyan, // Calm blue
    'Sunset Orange': Colors.orange, // Warm orange
    'Cherry Red': Colors.red, // Alert red
    'Forest Green': Colors.green, // Nature green
    'Ocean Blue': Colors.blue, // Classic blue
    'Pink Blossom': Colors.pink, // Soft pink
    'Deep Purple': Colors.deepPurple, // Rich purple
    'Teal Wave': Colors.teal, // Medical teal
    'Indigo Night': Colors.indigo, // Deep indigo
  };

  /// Get the currently selected theme from preferences
  static Future<String> getSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themePreferenceKey) ?? 'Adaptive Theme';
  }

  /// Save the selected theme to preferences
  static Future<void> setSelectedTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, themeName);
  }

  /// Get the AMOLED mode setting from preferences
  static Future<bool> getAmoledMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_amoledModeKey) ?? false;
  }

  /// Save the AMOLED mode setting to preferences
  static Future<void> setAmoledMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_amoledModeKey, enabled);
  }

  /// Get the ThemeMode setting from preferences
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeModeKey);
    if (savedMode == 'dark') return ThemeMode.dark;
    if (savedMode == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  /// Save the ThemeMode setting to preferences
  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String value = 'system';
    if (mode == ThemeMode.dark) value = 'dark';
    if (mode == ThemeMode.light) value = 'light';
    await prefs.setString(_themeModeKey, value);
  }

  /// Get the Color for a specific theme name
  static Color getThemeColor(String themeName) {
    return themeColors[themeName] ?? const Color(0xFF2563EB);
  }

  /// Get list of all available theme names
  static List<String> getAvailableThemes() {
    return themeColors.keys.toList();
  }

  /// Creates color schemes based on selected theme and dynamic colors
  /// This method intelligently selects between Material You colors and custom themes
  static (ColorScheme light, ColorScheme dark) createColorSchemes({
    required ColorScheme? lightDynamic,
    required ColorScheme? darkDynamic,
    required String selectedTheme,
    required bool amoledModeEnabled,
  }) {
    ColorScheme lightScheme;
    ColorScheme darkScheme;

    // Use dynamic colors if available and "Adaptive Theme" is selected
    if (selectedTheme == 'Adaptive Theme' &&
        lightDynamic != null &&
        darkDynamic != null) {
      lightScheme = lightDynamic;
      darkScheme = darkDynamic;
    } else {
      // Use the selected theme color to generate color schemes
      final seedColor = getThemeColor(selectedTheme);
      lightScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      );
      darkScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      );
    }

    // Apply AMOLED mode if enabled
    if (amoledModeEnabled) {
      darkScheme = ThemeUtils.createAmoledColorScheme(darkScheme);
    }

    return (lightScheme, darkScheme);
  }
}
