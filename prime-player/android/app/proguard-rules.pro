# ExoPlayer (better_player_plus)
-keep class com.google.android.exoplayer2.** { *; }
-keep class com.jhomlala.better_player.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Hive
-keep class * extends com.google.flatbuffers.Table { *; }
-keep class * extends com.google.flatbuffers.Struct { *; }
