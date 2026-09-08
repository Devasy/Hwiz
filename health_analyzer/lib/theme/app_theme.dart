import 'package:flutter/material.dart';

/// LabLens Design System
/// Central theme configuration for consistent UI across the app
/// Supports Material 3 with dynamic theming (Material You)

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ============ BRAND COLORS (Fallback when dynamic colors not available) ============

  // Primary Brand Colors
  static const Color primaryColor = Color(0xFF2563EB); // Modern blue
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Secondary Colors
  static const Color secondaryColor = Color(0xFF8B5CF6); // Purple accent
  static const Color accentColor = Color(0xFF06B6D4); // Cyan accent

  // Status Colors
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningColor = Color(0xFFF59E0B); // Orange
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color infoColor = Color(0xFF3B82F6); // Light blue
  static const Color infoLight = Color(0xFFDBEAFE);

  // Neutral Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color dividerColor = Color(0xFFE5E7EB);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFFFFFFF);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkCard = Color(0xFF374151);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);

  // ============ TYPOGRAPHY ============

  static const String fontFamily = 'Inter'; // Can be changed to system default

  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: textTertiary,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textTertiary,
    letterSpacing: 0.5,
  );

  // ============ SPACING ============

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // ============ RADIUS ============

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusFull = 999.0;

  // ============ SHADOWS ============

  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ============ THEME DATA ============

  /// Default light color scheme (used when dynamic colors not available)
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
  );

  /// Default dark color scheme (used when dynamic colors not available)
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.dark,
  );

  /// Light theme with optional custom color scheme
  /// If colorScheme is null, uses default brand colors
  static ThemeData lightTheme([ColorScheme? colorScheme]) {
    final scheme = colorScheme ?? lightColorScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      // Material 3 visual density for better touch targets
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Typography based on Material 3 spec
      typography: Typography.material2021(),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingSmall.copyWith(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: titleMedium.copyWith(color: scheme.onPrimary),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing12,
          ),
          textStyle: titleMedium,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: titleMedium,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: bodyMedium.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: bodyMedium.copyWith(color: scheme.onSurfaceVariant),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing8,
        ),
        labelStyle: labelMedium.copyWith(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      // Dialog Theme - Material 3 elevation tones
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: headingSmall.copyWith(color: scheme.onSurface),
        contentTextStyle: bodyMedium.copyWith(color: scheme.onSurfaceVariant),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: bodyMedium.copyWith(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),

      // Switch Theme - Material 3 style
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.onSurfaceVariant;
        }),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        selectedTileColor: scheme.secondaryContainer,
        selectedColor: scheme.onSecondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // FAB Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 6, // Material 3: FAB normal state
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),

      // Navigation Bar Theme (Material 3 - replaces BottomNavigationBar)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0, // M3: No shadow, use surface tones instead
        height: 80, // M3: Taller for better touch targets
        indicatorColor: scheme.secondaryContainer,
        indicatorShape:
            const StadiumBorder(), // Pill shape for active indicator
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        // Icon colors using WidgetState
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: scheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: scheme.onSurfaceVariant,
            size: 24,
          );
        }),
        // Label text styles
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return labelMedium.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            );
          }
          return labelSmall.copyWith(
            color: scheme.onSurfaceVariant,
          );
        }),
      ),

      // Bottom Navigation Bar Theme (Legacy - prefer NavigationBar)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: 0, // M3: No elevation
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: labelMedium,
        unselectedLabelStyle: labelSmall,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: scheme.onSurface,
        size: 24,
      ),

      // Text Theme - using colorScheme for proper contrast
      textTheme: TextTheme(
        displayLarge: headingLarge.copyWith(color: scheme.onSurface),
        displayMedium: headingMedium.copyWith(color: scheme.onSurface),
        displaySmall: headingSmall.copyWith(color: scheme.onSurface),
        headlineLarge: titleLarge.copyWith(color: scheme.onSurface),
        headlineMedium: titleMedium.copyWith(color: scheme.onSurface),
        headlineSmall: titleSmall.copyWith(color: scheme.onSurface),
        titleLarge: titleLarge.copyWith(color: scheme.onSurface),
        titleMedium: titleMedium.copyWith(color: scheme.onSurface),
        titleSmall: titleSmall.copyWith(color: scheme.onSurface),
        bodyLarge: bodyLarge.copyWith(color: scheme.onSurface),
        bodyMedium: bodyMedium.copyWith(color: scheme.onSurface),
        bodySmall: bodySmall.copyWith(color: scheme.onSurfaceVariant),
        labelLarge: labelLarge.copyWith(color: scheme.onSurface),
        labelMedium: labelMedium.copyWith(color: scheme.onSurfaceVariant),
        labelSmall: labelSmall.copyWith(color: scheme.onSurfaceVariant),
      ),

      // Page transitions with Android 14+ Predictive Back Gestures
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Dark theme with optional custom color scheme
  /// If colorScheme is null, uses default brand colors
  static ThemeData darkTheme([ColorScheme? colorScheme]) {
    final scheme = colorScheme ?? darkColorScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      // Material 3 visual density for better touch targets
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Typography based on Material 3 spec
      typography: Typography.material2021(),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingSmall.copyWith(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation:
            6, // Material 3: FAB normal state (reduced from light for dark theme)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      // Navigation Bar Theme (Material 3 - replaces BottomNavigationBar)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0, // M3: No shadow, use surface tones instead
        height: 80, // M3: Taller for better touch targets
        indicatorColor: scheme.secondaryContainer,
        indicatorShape:
            const StadiumBorder(), // Pill shape for active indicator
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        // Icon colors using WidgetState
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: scheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: scheme.onSurfaceVariant,
            size: 24,
          );
        }),
        // Label text styles
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return labelMedium.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            );
          }
          return labelSmall.copyWith(
            color: scheme.onSurfaceVariant,
          );
        }),
      ),

      // Bottom Navigation Bar Theme (Legacy - prefer NavigationBar)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: 0, // M3: No elevation
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: labelMedium.copyWith(color: scheme.primary),
        unselectedLabelStyle:
            labelSmall.copyWith(color: scheme.onSurfaceVariant),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: headingSmall.copyWith(color: scheme.onSurface),
        contentTextStyle: bodyMedium.copyWith(color: scheme.onSurfaceVariant),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: bodyMedium.copyWith(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: bodyMedium.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: bodyMedium.copyWith(color: scheme.onSurfaceVariant),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        selectedTileColor: scheme.secondaryContainer,
        selectedColor: scheme.onSecondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Text Theme - using colorScheme for proper contrast
      textTheme: TextTheme(
        displayLarge: headingLarge.copyWith(color: scheme.onSurface),
        displayMedium: headingMedium.copyWith(color: scheme.onSurface),
        displaySmall: headingSmall.copyWith(color: scheme.onSurface),
        headlineLarge: titleLarge.copyWith(color: scheme.onSurface),
        headlineMedium: titleMedium.copyWith(color: scheme.onSurface),
        headlineSmall: titleSmall.copyWith(color: scheme.onSurface),
        titleLarge: titleLarge.copyWith(color: scheme.onSurface),
        titleMedium: titleMedium.copyWith(color: scheme.onSurface),
        titleSmall: titleSmall.copyWith(color: scheme.onSurface),
        bodyLarge: bodyLarge.copyWith(color: scheme.onSurface),
        bodyMedium: bodyMedium.copyWith(color: scheme.onSurface),
        bodySmall: bodySmall.copyWith(color: scheme.onSurfaceVariant),
        labelLarge: labelLarge.copyWith(color: scheme.onSurface),
        labelMedium: labelMedium.copyWith(color: scheme.onSurfaceVariant),
        labelSmall: labelSmall.copyWith(color: scheme.onSurfaceVariant),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: scheme.onSurface,
        size: 24,
      ),

      // Page transitions with Android 14+ Predictive Back Gestures
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}
