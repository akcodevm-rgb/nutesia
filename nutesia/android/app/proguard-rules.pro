# WorkManager (pulled in by Google Mobile Ads) creates its Room database by
# reflection at startup. Without these rules R8 strips WorkDatabase_Impl and
# the app crashes before Flutter starts:
#   Failed to create an instance of androidx.work.impl.WorkDatabase
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
