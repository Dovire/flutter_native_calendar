# Consumer ProGuard rules shipped with the plugin. These are merged into the
# app's rules when the app depends on this plugin.

# Keep the plugin classes used via reflection from Flutter engine.
-keep class com.dovireinfotech.native_calendar.** { *; }

# Keep relevant Android calendar provider classes used by this plugin
-keep class android.provider.CalendarContract** { *; }
-keep class android.content.ContentValues { *; }
