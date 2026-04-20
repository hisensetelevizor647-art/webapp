# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-keep class com.google.api.client.** { *; }
-dontwarn com.google.android.gms.**

# Keep annotations
-keepattributes *Annotation*, InnerClasses, EnclosingMethod, Signature

# Speech / TTS plugins
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.speech_to_text.**

# OkHttp / http
-dontwarn okhttp3.**
-dontwarn okio.**
