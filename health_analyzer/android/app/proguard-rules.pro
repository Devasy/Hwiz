# Flutter Proguard Rules

# Preserve Flutter engine & plugin bindings
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# App Activity & Package
-keep class com.devasy.lablens.** { *; }

# Sqflite
-keep class com.tekartik.sqflite.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Flutter Secure Storage
-keep class androidx.security.crypto.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Syncfusion PDF Viewer
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# Play Core SplitInstall & Deferred Components
-dontwarn com.google.android.play.core.**

