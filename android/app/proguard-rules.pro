-dontwarn kotlin.**
-dontwarn kotlinx.**

# Strip common debug logging from release builds.
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** i(...);
    public static *** v(...);
}

# Reduce source-level metadata left in the shipped APK/AAB.
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# Keep the Flutter Android entry activity stable.
-keep class com.tempcam.MainActivity { *; }
