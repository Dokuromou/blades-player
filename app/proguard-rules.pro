# jaudiotagger reads/writes audio metadata through reflection-driven tag readers
# (ID3v1/v2, Vorbis/FLAC comments, MP4 ilst atoms, WAV INFO chunks).
-keep class org.jaudiotagger.** { *; }
-dontwarn org.jaudiotagger.**
-dontwarn javax.imageio.**
-dontwarn java.awt.**
-dontwarn org.apache.commons.io.**

# The MediaSession service is instantiated by the system.
-keep class app.blades.player.playback.PlaybackService { *; }

# Room generated implementations
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-dontwarn androidx.room.paging.**

# Kotlin coroutines internals used reflectively by DataStore
-dontwarn kotlinx.coroutines.**
