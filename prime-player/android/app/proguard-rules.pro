# media_kit / libmpv
-keep class com.alexmercerind.** { *; }
-keep class media_kit_libs_android_video.** { *; }

# Hive
-keep class * extends com.google.flatbuffers.Table { *; }
-keep class * extends com.google.flatbuffers.Struct { *; }
