# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Google Play services - CRITICAL for R8
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep HTTP client
-keep class retrofit2.** { *; }
-keepattributes *Annotation*

# Keep JSON serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}

# Optimize string operations
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Keep all classes that might be referenced by Flutter
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep all classes from packages we're using
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.play.core.** { *; }
-keep class io.flutter.plugins.shared_preferences.** { *; }
-keep class io.flutter.plugins.url_launcher.** { *; }
-keep class io.flutter.plugins.google_fonts.** { *; }
-keep class io.flutter.plugins.http.** { *; }

# Keep specific Google Play Core classes that R8 needs
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all classes with @Keep annotation
-keep class * {
    @androidx.annotation.Keep *;
}

# Aggressive optimization for size reduction
-dontwarn android.support.**
-dontwarn androidx.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Remove unused classes and optimize size
-repackageclasses ''
-allowaccessmodification

# Optimize enums and fields
-optimizations !enum/switch,!field/*,!code/merging

# Remove unused fields and methods
-allowaccessmodification
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Additional size optimizations
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5 