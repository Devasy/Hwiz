# ==============================================================================
# R8 / ProGuard Optimization Rules for Google Play Store
# ==============================================================================

# Flatten package hierarchy into the root package to optimize DEX string pool and DEX size
-repackageclasses ''
-allowaccessmodification

# Optimization passes
-optimizationpasses 5

# Strip verbose and debug logging in release builds to reduce DEX size
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
}

# ------------------------------------------------------------------------------
# Application Entry Point
# ------------------------------------------------------------------------------
-keep class com.devasy.lablens.MainActivity { *; }

# ------------------------------------------------------------------------------
# Flutter Engine & Plugins
# ------------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.embedding.engine.plugins.activity.ActivityAware { *; }

# Preserve keep annotations used by Flutter & AndroidX
-keep @interface io.flutter.annotation.Keep
-keep @interface androidx.annotation.Keep
-keep @io.flutter.annotation.Keep class * { *; }
-keep @androidx.annotation.Keep class * { *; }
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
}
-keepclasseswithmembers class * {
    @io.flutter.annotation.Keep <methods>;
}
-keepclasseswithmembers class * {
    @io.flutter.annotation.Keep <fields>;
}

# ------------------------------------------------------------------------------
# Third-Party Plugins & Native Libraries
# ------------------------------------------------------------------------------
# Sqflite
-keep class com.tekartik.sqflite.** { *; }

# Flutter Secure Storage & AndroidX Security Crypto
-keep class androidx.security.crypto.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn androidx.security.crypto.**

# Syncfusion PDF Viewer
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# Dart JNI Interop
-keep class com.github.dart_lang.jni.** { *; }
-dontwarn com.github.dart_lang.jni.**

# Play Core SplitInstall & Deferred Components
-dontwarn com.google.android.play.core.**

