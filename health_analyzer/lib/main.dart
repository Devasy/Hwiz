import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'theme/theme_utils.dart';
import 'theme/theme_manager.dart';
import 'utils/display_utils.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/report_viewmodel.dart';
import 'views/screens/main_shell.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize high refresh rate detection and optimization (90Hz, 120Hz displays)
    await DisplayUtils.initializeHighRefreshRate();

    // Print display capabilities in debug mode
    DisplayUtils.printDisplayCapabilities();
  } catch (e) {
    debugPrint('Display initialization non-critical warning: $e');
  }

  runApp(const LabLensApp());
}

class LabLensApp extends StatefulWidget {
  const LabLensApp({super.key});

  @override
  State<LabLensApp> createState() => _LabLensAppState();
}

class _LabLensAppState extends State<LabLensApp> {
  bool _amoledModeEnabled = false;
  String _selectedTheme = 'Adaptive Theme';

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    try {
      final amoledMode = await ThemeManager.getAmoledMode();
      final selectedTheme = await ThemeManager.getSelectedTheme();
      if (!mounted) return;
      setState(() {
        _amoledModeEnabled = amoledMode;
        _selectedTheme = selectedTheme;
      });
    } catch (e) {
      debugPrint('Error loading theme settings: $e');
    }
  }

  /// Update AMOLED mode setting
  void updateAmoledMode(bool enabled) async {
    await ThemeManager.setAmoledMode(enabled);
    setState(() {
      _amoledModeEnabled = enabled;
    });
  }

  /// Update theme selection
  void updateTheme(String themeName) async {
    await ThemeManager.setSelectedTheme(themeName);
    setState(() {
      _selectedTheme = themeName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()..initialize()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
      ],
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          // Create color schemes based on selected theme and AMOLED mode
          final (lightColorScheme, darkColorScheme) =
              ThemeManager.createColorSchemes(
            lightDynamic: lightDynamic,
            darkDynamic: darkDynamic,
            selectedTheme: _selectedTheme,
            amoledModeEnabled: _amoledModeEnabled,
          );

          // Log theme information in debug mode
          if (_selectedTheme == 'Adaptive Theme' && lightDynamic != null) {
            debugPrint('🎨 Material You enabled - using dynamic colors');
            debugPrint('  Primary: ${lightDynamic.primary}');
            debugPrint('  Secondary: ${lightDynamic.secondary}');
          } else {
            debugPrint('🎨 Using custom theme: $_selectedTheme');
          }

          if (_amoledModeEnabled) {
            debugPrint('🌙 AMOLED mode enabled');
          }

          return MaterialApp(
            title: 'LabLens',
            debugShowCheckedModeBanner: false,
            theme: ThemeUtils.createLightTheme(lightColorScheme),
            darkTheme: ThemeUtils.createDarkTheme(darkColorScheme),
            themeMode: ThemeMode.system,
            // Enable smooth theme transitions
            themeAnimationDuration: const Duration(milliseconds: 300),
            themeAnimationCurve: Curves.easeInOut,
            home: MainShell(
              onAmoledModeChanged: updateAmoledMode,
              onThemeChanged: updateTheme,
            ),
          );
        },
      ),
    );
  }
}
