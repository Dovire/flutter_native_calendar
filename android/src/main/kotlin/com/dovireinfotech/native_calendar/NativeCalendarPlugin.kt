package com.dovireinfotech.native_calendar

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.CalendarContract
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.*

/** NativeCalendarPlugin */
class NativeCalendarPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: android.app.Activity? = null
    private var pendingResult: Result? = null

    companion object {
        private const val CALENDAR_PERMISSION_REQUEST_CODE = 1001
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_native_calendar")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            "openCalendarWithEvent" -> {
                openCalendarWithEvent(call.arguments as Map<String, Any>, result)
            }

            "addEventToCalendar" -> {
                addEventToCalendar(call.arguments as Map<String, Any>, result)
            }

            "hasCalendarPermissions" -> {
                result.success(hasCalendarPermissions())
            }

            "requestCalendarPermissions" -> {
                requestCalendarPermissions(result)
            }

            "findEventsWithMarker" -> {
                findEventsWithMarker(call.arguments as Map<String, Any>, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun openCalendarWithEvent(eventData: Map<String, Any>, result: Result) {
        try {
            // Try the MIME type approach first
            val intent = Intent(Intent.ACTION_INSERT).apply {
                type = "vnd.android.cursor.dir/event"
                
                // Add basic event data using standard Intent extras
                addBasicEventDataToIntent(this, eventData)
                
                // Handle Android-specific settings for Intent
                handleAndroidSettingsForIntent(this, eventData)
            }

            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            
            try {
                activity?.startActivity(intent) ?: context?.startActivity(intent)
                result.success(true)
            } catch (e: Exception) {
                // Fallback to ContentURI approach
                val fallbackIntent = Intent(Intent.ACTION_INSERT).apply {
                    data = CalendarContract.Events.CONTENT_URI
                    addBasicEventDataToIntent(this, eventData)
                    handleAndroidSettingsForIntent(this, eventData)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                
                activity?.startActivity(fallbackIntent) ?: context?.startActivity(fallbackIntent)
                result.success(true)
            }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun addEventToCalendar(eventData: Map<String, Any>, result: Result) {
        if (!hasCalendarPermissions()) {
            result.success(false)
            return
        }

        try {
            val values = ContentValues().apply {
                // Add basic event data
                addBasicEventDataToContentValues(this, eventData)
                
                // Handle Android-specific settings for ContentValues
                handleAndroidSettingsForContentValues(this, eventData)
            }

            val uri = context?.contentResolver?.insert(CalendarContract.Events.CONTENT_URI, values)

            // Add reminders if specified
            if (uri != null) {
                handleRemindersForDirectInsert(uri, eventData)
            }

            result.success(uri != null)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun hasCalendarPermissions(): Boolean {
        return context?.let {
            ContextCompat.checkSelfPermission(
                it,
                Manifest.permission.WRITE_CALENDAR
            ) == PackageManager.PERMISSION_GRANTED &&
                    ContextCompat.checkSelfPermission(
                        it,
                        Manifest.permission.READ_CALENDAR
                    ) == PackageManager.PERMISSION_GRANTED
        } ?: false
    }

    private fun requestCalendarPermissions(result: Result) {
        if (activity == null) {
            result.success(false)
            return
        }

        pendingResult = result
        ActivityCompat.requestPermissions(
            activity!!,
            arrayOf(Manifest.permission.WRITE_CALENDAR, Manifest.permission.READ_CALENDAR),
            CALENDAR_PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == CALENDAR_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingResult?.success(granted)
            pendingResult = null
            return true
        }
        return false
    }

    private fun findEventsWithMarker(arguments: Map<String, Any>, result: Result) {
        if (!hasCalendarPermissions()) {
            result.success(emptyList<String>())
            return
        }

        try {
            val marker = arguments["marker"] as String
            val startDate = arguments["startDate"] as? Long
            val endDate = arguments["endDate"] as? Long
            
            val eventIds = mutableListOf<String>()
            
            // Set default date range if not provided (30 days ago to 30 days from now)
            val searchStartTime = startDate ?: (System.currentTimeMillis() - (30L * 24 * 60 * 60 * 1000))
            val searchEndTime = endDate ?: (System.currentTimeMillis() + (30L * 24 * 60 * 60 * 1000))
            
            val projection = arrayOf(
                CalendarContract.Events._ID,
                CalendarContract.Events.DESCRIPTION,
                CalendarContract.Events.TITLE,
                CalendarContract.Events.DTSTART,
                CalendarContract.Events.DTEND
            )
            
            val selection = "${CalendarContract.Events.DTSTART} >= ? AND ${CalendarContract.Events.DTSTART} <= ? AND ${CalendarContract.Events.DESCRIPTION} LIKE ?"
            val selectionArgs = arrayOf(
                searchStartTime.toString(),
                searchEndTime.toString(),
                "%[MARKER:$marker]%"
            )
            
            val cursor = context?.contentResolver?.query(
                CalendarContract.Events.CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )
            
            cursor?.use {
                while (it.moveToNext()) {
                    val eventId = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events._ID))
                    val description = it.getString(it.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION))
                    
                    // Double-check that the description contains our specific marker format
                    if (description != null && description.contains("[MARKER:$marker] System Generated Event - Do not modify this line")) {
                        eventIds.add(eventId)
                    }
                }
            }
            
            result.success(eventIds)
        } catch (e: Exception) {
            result.success(emptyList<String>())
        }
    }

    private fun findPrimaryCalendarId(): Int {
        try {
            val projection = arrayOf(
                CalendarContract.Calendars._ID,
                CalendarContract.Calendars.IS_PRIMARY,
                CalendarContract.Calendars.ACCOUNT_NAME,
                CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME
            )

            val cursor = context?.contentResolver?.query(
                CalendarContract.Calendars.CONTENT_URI,
                projection,
                "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL} >= ${CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR}",
                null,
                "${CalendarContract.Calendars.IS_PRIMARY} DESC"
            )

            cursor?.use {
                while (it.moveToNext()) {
                    val id = it.getInt(it.getColumnIndexOrThrow(CalendarContract.Calendars._ID))
                    val isPrimary =
                        it.getInt(it.getColumnIndexOrThrow(CalendarContract.Calendars.IS_PRIMARY))
                    val account =
                        it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_NAME))
                    val accessLevel =
                        it.getInt(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL))
                    val displayName =
                        it.getString(it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME))

                    if (it.position == 0) { // First calendar (primary)
                        return id
                    }
                }
            }
        } catch (e: Exception) {
            // Silently handle exception
        }

        return 1 // Fallback to calendar ID 1
    }

    // Helper methods for common functionality
    private fun addBasicEventDataToIntent(intent: Intent, eventData: Map<String, Any>) {
        intent.putExtra(CalendarContract.Events.TITLE, eventData["title"] as String)

        eventData["description"]?.let {
            intent.putExtra(CalendarContract.Events.DESCRIPTION, it as String)
        }

        // Handle location (can be string or structured location object)
        eventData["location"]?.let { locationData ->
            val locationString = formatLocationForAndroid(locationData)
            intent.putExtra(CalendarContract.Events.EVENT_LOCATION, locationString)
        }

        val startDate = eventData["startDate"] as Long
        intent.putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startDate)

        eventData["endDate"]?.let {
            intent.putExtra(CalendarContract.EXTRA_EVENT_END_TIME, it as Long)
        }

        val isAllDay = eventData["isAllDay"] as? Boolean ?: false
        intent.putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, isAllDay)

        eventData["timeZone"]?.let {
            intent.putExtra(CalendarContract.Events.EVENT_TIMEZONE, it as String)
        }
    }

    private fun addBasicEventDataToContentValues(values: ContentValues, eventData: Map<String, Any>) {
        values.put(CalendarContract.Events.DTSTART, eventData["startDate"] as Long)
        eventData["endDate"]?.let {
            values.put(CalendarContract.Events.DTEND, it as Long)
        }
        values.put(CalendarContract.Events.TITLE, eventData["title"] as String)
        eventData["description"]?.let {
            values.put(CalendarContract.Events.DESCRIPTION, it as String)
        }

        // Handle location (can be string or structured location object)
        eventData["location"]?.let { locationData ->
            val locationString = formatLocationForAndroid(locationData)
            values.put(CalendarContract.Events.EVENT_LOCATION, locationString)
        }

        val isAllDay = eventData["isAllDay"] as? Boolean ?: false
        values.put(CalendarContract.Events.ALL_DAY, if (isAllDay) 1 else 0)

        eventData["timeZone"]?.let {
            values.put(CalendarContract.Events.EVENT_TIMEZONE, it as String)
        } ?: values.put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
    }

    private fun handleAndroidSettingsForIntent(intent: Intent, eventData: Map<String, Any>) {
        val androidSettings = eventData["androidSettings"] as? Map<String, Any>

        androidSettings?.let { settings ->
            // Note: For Intent.ACTION_INSERT, we can only use standard Calendar extras
            // Custom settings like calendarId, eventStatus, visibility are not supported via Intent
            // The calendar app will use its own defaults for these
            
            // Handle reminders - Android Calendar app supports this via Intent extras
            handleRemindersForIntent(intent, settings)
        }
    }

    private fun handleAndroidSettingsForContentValues(values: ContentValues, eventData: Map<String, Any>) {
        val androidSettings = eventData["androidSettings"] as? Map<String, Any>
        val calendarId = androidSettings?.get("calendarId") as? Int ?: findPrimaryCalendarId()
        values.put(CalendarContract.Events.CALENDAR_ID, calendarId)

        // Set event status
        val eventStatus = androidSettings?.get("eventStatus") as? Int ?: 1
        values.put(CalendarContract.Events.STATUS, eventStatus)

        // Set visibility
        val visibility = androidSettings?.get("visibility") as? Int ?: 0
        values.put(CalendarContract.Events.ACCESS_LEVEL, visibility)

        // Set color if provided
        androidSettings?.get("eventColor")?.let {
            values.put(CalendarContract.Events.EVENT_COLOR, it as Int)
        }
    }

    private fun handleRemindersForIntent(intent: Intent, settings: Map<String, Any>) {
        val hasAlarm = settings["hasAlarm"] as? Boolean ?: true
        if (hasAlarm) {
            val reminderMinutes = settings["reminderMinutes"] as? List<*> ?: listOf(15)

            // For Intent.ACTION_INSERT, most calendar apps ignore custom reminder times
            // and use their own defaults. We'll try the available Intent extras but
            // the user will need to manually adjust reminders in the calendar app.
            if (reminderMinutes.isNotEmpty()) {
                val firstReminder = parseReminderMinutes(reminderMinutes[0])
                
                // Try setting hasAlarm extra (limited support across calendar apps)
                intent.putExtra("hasAlarm", true)
                
                // Some calendar apps might respect these extras (very limited support)
                intent.putExtra("reminderMinutes", firstReminder)
            }
        } else {
            intent.putExtra("hasAlarm", false)
        }
    }

    private fun handleRemindersForDirectInsert(uri: Uri, eventData: Map<String, Any>) {
        try {
            val androidSettings = eventData["androidSettings"] as? Map<String, Any>
            val hasAlarm = androidSettings?.get("hasAlarm") as? Boolean ?: true

            if (hasAlarm) {
                val reminderMinutes = androidSettings?.get("reminderMinutes") as? List<*> ?: listOf(15)
                val eventId = uri.lastPathSegment?.toLongOrNull()

                if (eventId != null) {
                    for (minutesObj in reminderMinutes) {
                        val minutes = parseReminderMinutes(minutesObj)

                        val reminderValues = ContentValues().apply {
                            put(CalendarContract.Reminders.EVENT_ID, eventId)
                            put(CalendarContract.Reminders.MINUTES, minutes)
                            put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
                        }

                        context?.contentResolver?.insert(
                            CalendarContract.Reminders.CONTENT_URI,
                            reminderValues
                        )
                    }
                }
            }
        } catch (e: Exception) {
            // Log reminder creation failure but don't fail the entire event creation
        }
    }

    private fun parseReminderMinutes(minutesObj: Any?): Int {
        return when (minutesObj) {
            is Int -> minutesObj
            is Double -> minutesObj.toInt()
            is String -> minutesObj.toIntOrNull() ?: 15
            else -> 15
        }
    }

    private fun formatLocationForAndroid(locationData: Any): String {
        return when (locationData) {
            is String -> locationData
            is Map<*, *> -> {
                val locationMap = locationData as Map<String, Any>
                val parts = mutableListOf<String>()

                // Add title
                locationMap["title"]?.let { title ->
                    parts.add(title as String)
                }

                // Add address if available
                locationMap["address"]?.let { address ->
                    val addressStr = address as String
                    if (addressStr.isNotEmpty()) {
                        parts.add(addressStr)
                    }
                }

                // Add coordinates if available
                val latitude = locationMap["latitude"] as? Double
                val longitude = locationMap["longitude"] as? Double
                if (latitude != null && longitude != null) {
                    parts.add(
                        "Coordinates: ${
                            String.format(
                                "%.6f",
                                latitude
                            )
                        }, ${String.format("%.6f", longitude)}"
                    )
                }

                // Add notes if available
                locationMap["notes"]?.let { notes ->
                    val notesStr = notes as String
                    if (notesStr.isNotEmpty()) {
                        parts.add(notesStr)
                    }
                }

                parts.joinToString("\n")
            }

            else -> locationData.toString()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
