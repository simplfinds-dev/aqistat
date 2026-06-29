# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# Remove all log statements in release (avoids leaking data)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}


# ---------------------------------------------------------------------------
# Keep-rules for plugins (needed when minifyEnabled is turned back on).
# ---------------------------------------------------------------------------

# Google Play Core - Flutter references these for deferred components / split
# installs even when unused. Without these, R8 fails with "Missing class
# com.google.android.play.core.*". Safe to ignore them.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# flutter_local_notifications uses Gson + Dexterous scheduling classes.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Kotlin metadata / coroutines used by several plugins.
-keep class kotlin.** { *; }
-dontwarn kotlin.**
