import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'theme/theme_utils.dart';
import 'theme/theme_manager.dart';
import 'utils/display_utils.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/report_viewmodel.dart';
import 'viewmodels/ask_ai_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
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

class LabLensApp extends StatelessWidget {
  const LabLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()..initialize()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
        ChangeNotifierProvider(create: (_) => AskAiViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, child) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              final (lightColorScheme, darkColorScheme) =
                  ThemeManager.createColorSchemes(
                lightDynamic: lightDynamic,
                darkDynamic: darkDynamic,
                selectedTheme: themeVM.selectedTheme,
                amoledModeEnabled: themeVM.isAmoledMode,
              );

              return MaterialApp(
                title: 'LabLens',
                debugShowCheckedModeBanner: false,
                theme: ThemeUtils.createLightTheme(lightColorScheme),
                darkTheme: ThemeUtils.createDarkTheme(darkColorScheme),
                themeMode: themeVM.themeMode,
                themeAnimationDuration: const Duration(milliseconds: 300),
                themeAnimationCurve: Curves.easeInOut,
                home: const MainShell(),
              );
            },
          );
        },
      ),
    );
  }
}
