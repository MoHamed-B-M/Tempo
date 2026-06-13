# Flutter engine (everything needed via reflection)
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
-keep class io.flutter.plugins.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# timezone (Dart TZ database package)
-keep class timezone.** { *; }

# flutter_timezone (native plugin)
-keep class com.example.fluttertimezone.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# package_info_plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# connectivity_plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-keep class io.flutter.plugins.connectivity.** { *; }

# hive / hive_flutter (TypeAdapters loaded via reflection)
-keep class com.hive.** { *; }

# motor
-keep class com.example.motor.** { *; }
-keep class xyz.motor.** { *; }

#m3e_core
-keep class com.m3e.** { *; }

# Keep model classes
-keep class com.example.tempo.model.** { *; }

# Keep annotations (needed for reflection-based frameworks)
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep enum classes
-keepclassmembers enum * { *; }
-keep enum * { *; }

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Keep coroutines (used by many plugins)
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Play Core (used by Flutter's deferred component loading)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep all MethodChannel/EventChannel handler classes
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * implements io.flutter.plugin.common.PluginRegistry$PluginRegistrantCallback { *; }

# Suppress common R8 warnings
-dontwarn com.google.common.**
-dontwarn com.google.errorprone.**
-dontwarn com.google.j2objc.**
-dontwarn javax.annotation.**
-dontwarn checkstyle.**
-dontwarn org.codehaus.**
-dontwarn org.jspecify.**
-dontwarn org.jetbrains.annotations.**
-dontwarn afu.**
-dontwarn java.lang.invoke.**
-dontwarn org.slf4j.**
-dontwarn org.apache.**
-dontwarn com.squareup.**
-dontwarn okhttp3.**
-dontwarn okio.**
