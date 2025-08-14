# Additional ProGuard rules for R8 to prevent missing classes
# This file handles Google Play Core and other dependencies

# Keep all Google Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep Flutter specific classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep HTTP and networking classes
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Keep JSON serialization
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep classes with @Keep annotation
-keep class * {
    @androidx.annotation.Keep *;
}

# Don't warn about missing classes
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.**
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# Optimize but be careful
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 3
