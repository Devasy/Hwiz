# Flutter Proguard Rules

# Preserve Flutter engine & plugin bindings
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Sqflite
-keep class com.tekartik.sqflite.** { *; }

# Flutter Secure Storage
-keep class androidx.security.crypto.** { *; }

# Syncfusion PDF Viewer
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# Play Core SplitInstall & Deferred Components
-dontwarn com.google.android.play.core.**

