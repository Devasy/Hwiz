import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Display utilities for detecting and optimizing for high refresh rate displays (90Hz, 120Hz, etc.)
///
/// This enables smoother animations and scrolling on devices that support higher refresh rates
/// such as:
/// - iPhone Pro models (ProMotion 120Hz)
/// - iPad Pro (ProMotion 120Hz)
/// - Many Android flagship devices (90Hz, 120Hz, 144Hz)
///
/// Usage:
/// ```dart
/// // In main() before runApp:
/// await DisplayUtils.initializeHighRefreshRate();
///
/// // Use adaptive durations:
/// Duration animDuration = DisplayUtils.getOptimalAnimationDuration();
///
/// // Use adaptive curves:
/// Curve animCurve = DisplayUtils.getOptimalAnimationCurve();
/// ```
class DisplayUtils {
  static bool _highRefreshRateEnabled = false;
  static double _detectedRefreshRate = 60.0;

  /// Initialize high refresh rate support
  ///
  /// Call this in main() before runApp() to detect and enable high refresh rate
  /// optimizations for smoother animations and scrolling
  static Future<void> initializeHighRefreshRate() async {
    if (kIsWeb) {
      debugPrint('LabLens: Web platform - skipping refresh rate detection');
      return;
    }

    try {
      final binding = WidgetsBinding.instance;

      if (binding.platformDispatcher.views.isNotEmpty) {
        final view = binding.platformDispatcher.views.first;
        final refreshRate = view.display.refreshRate;
        _detectedRefreshRate = refreshRate;

        debugPrint(
          '🎨 LabLens: Display refresh rate detected: ${refreshRate.toStringAsFixed(1)}Hz',
        );

        if (refreshRate > 60) {
          _highRefreshRateEnabled = true;
          debugPrint(
            '✨ LabLens: High refresh rate display enabled! Enjoy buttery smooth ${refreshRate.toStringAsFixed(0)}Hz animations',
          );

          // Enable platform-specific optimizations
          await _enablePlatformOptimizations();
        } else {
          debugPrint(
              'LabLens: Standard 60Hz display - using default animations');
        }
      }
    } catch (e) {
      debugPrint('LabLens: Could not detect display refresh rate: $e');
      debugPrint('LabLens: Falling back to standard 60Hz mode');
    }
  }

  /// Enable platform-specific optimizations for high refresh rate
  static Future<void> _enablePlatformOptimizations() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS ProMotion optimization - ensure smooth 120Hz animations
        debugPrint('LabLens: Enabling iOS ProMotion optimizations');
        // Note: Flutter automatically uses CADisplayLink on iOS for frame scheduling
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Android high refresh rate optimization
        debugPrint('LabLens: Enabling Android high refresh rate optimizations');
        // Note: Flutter automatically adapts to device refresh rate on Android
      }
    } catch (e) {
      debugPrint('LabLens: Platform optimization warning (non-critical): $e');
    }
  }

  /// Get the current display refresh rate
  static double getCurrentRefreshRate() {
    return _detectedRefreshRate;
  }

  /// Check if high refresh rate is available and enabled
  static bool get isHighRefreshRateEnabled => _highRefreshRateEnabled;

  /// Get optimal animation duration based on refresh rate
  ///
  /// On high refresh rate displays (90Hz+), animations are 20% faster
  /// to take advantage of the smoother frame rate
  ///
  /// Example:
  /// - 60Hz: 300ms
  /// - 120Hz: 240ms (20% faster, feels smoother)
  static Duration getOptimalAnimationDuration({
    Duration standard = const Duration(milliseconds: 300),
  }) {
    if (_highRefreshRateEnabled) {
      // Faster animations for high refresh rate displays
      // 20% reduction feels natural and takes advantage of higher frame rate
      return Duration(milliseconds: (standard.inMilliseconds * 0.8).round());
    }
    return standard;
  }

  /// Get optimal animation curve for current display
  ///
  /// On high refresh rate displays, use emphasized curves for more fluid motion
  static Curve getOptimalAnimationCurve() {
    if (_highRefreshRateEnabled) {
      // Smoother emphasized curve for high refresh rate
      return Curves.easeInOutCubicEmphasized;
    }
    return Curves.easeInOut; // Standard curve for 60Hz
  }

  /// Get optimal scroll physics for current display
  ///
  /// On high refresh rate displays, use more responsive physics
  static ScrollPhysics getOptimalScrollPhysics() {
    if (_highRefreshRateEnabled) {
      // More responsive scroll physics for high refresh rate
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return const BouncingScrollPhysics();
  }

  /// Get display information summary
  static String getDisplayInfo() {
    final refreshRate = _detectedRefreshRate.toStringAsFixed(1);
    final mode = _highRefreshRateEnabled ? 'High Refresh Rate' : 'Standard';
    return '$refreshRate Hz ($mode)';
  }

  /// Print display capabilities (for debugging)
  static void printDisplayCapabilities() {
    try {
      final binding = WidgetsBinding.instance;
      if (binding.platformDispatcher.views.isEmpty) {
        debugPrint('LabLens: No display views available');
        return;
      }

      final view = binding.platformDispatcher.views.first;
      final display = view.display;

      debugPrint('╔════════════════════════════════════════╗');
      debugPrint('║     LabLens Display Capabilities      ║');
      debugPrint('╠════════════════════════════════════════╣');
      debugPrint('${'║ Refresh Rate: ${display.refreshRate.toStringAsFixed(1)} Hz'
              .padRight(40)}║');
      debugPrint(
          '${'║ Size: ${display.size.width.toInt()}x${display.size.height.toInt()}'
                  .padRight(40)}║');
      debugPrint(
          '${'║ Device Pixel Ratio: ${display.devicePixelRatio.toStringAsFixed(2)}x'
                  .padRight(40)}║');
      debugPrint(
          '${'║ High Refresh: ${_highRefreshRateEnabled ? "✅ Enabled" : "⭕ Disabled"}'
                  .padRight(40)}║');
      if (_highRefreshRateEnabled) {
        debugPrint('${'║ Optimization: 20% faster animations'.padRight(40)}║');
      }
      debugPrint('╚════════════════════════════════════════╝');
    } catch (e) {
      debugPrint('LabLens: Could not print display capabilities: $e');
    }
  }
}
