# ProGuard / R8 rules for native calendar example app

# Keep Android calendar provider and content values
-keep class android.provider.CalendarContract** { *; }
-keep class android.content.ContentValues { *; }

# Keep this plugin's native classes
-keep class com.dovireinfotech.native_calendar.** { *; }
