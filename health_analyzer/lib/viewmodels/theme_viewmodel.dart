import 'package:flutter/material.dart';
import '../theme/theme_manager.dart';

/// ViewModel responsible for managing app-wide theming, dark mode, AMOLED mode,
/// and Material You / custom palette selection.
class ThemeViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _amoledMode = false;
  String _selectedTheme = 'Adaptive Theme';
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isAmoledMode => _amoledMode;
  String get selectedTheme => _selectedTheme;
  bool get isInitialized => _isInitialized;

  ThemeViewModel() {
    initialize();
  }

  /// Initialize and load saved theme settings
  Future<void> initialize() async {
    try {
      _themeMode = await ThemeManager.getThemeMode();
      _amoledMode = await ThemeManager.getAmoledMode();
      _selectedTheme = await ThemeManager.getSelectedTheme();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ThemeViewModel: $e');
    }
  }

  /// Toggle AMOLED pure black mode
  /// If turning on AMOLED mode while in light theme, automatically switch to dark mode
  /// so that pure black is immediately visible to the user.
  Future<void> setAmoledMode(bool enabled) async {
    _amoledMode = enabled;
    if (enabled && _themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      await ThemeManager.setThemeMode(_themeMode);
    }
    await ThemeManager.setAmoledMode(enabled);
    notifyListeners();
  }

  /// Set app theme mode (System, Light, Dark)
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await ThemeManager.setThemeMode(mode);
    notifyListeners();
  }

  /// Set selected theme palette name
  Future<void> setSelectedTheme(String themeName) async {
    _selectedTheme = themeName;
    await ThemeManager.setSelectedTheme(themeName);
    notifyListeners();
  }
}
