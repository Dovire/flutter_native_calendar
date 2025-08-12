package com.example.native_calendar

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
class NativeCalendarPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
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
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun openCalendarWithEvent(eventData: Map<String, Any>, result: Result) {
    try {
      val intent = Intent(Intent.ACTION_INSERT).apply {
        data = CalendarContract.Events.CONTENT_URI
        putExtra(CalendarContract.Events.TITLE, eventData["title"] as String)
        
        eventData["description"]?.let { 
          putExtra(CalendarContract.Events.DESCRIPTION, it as String) 
        }
        eventData["location"]?.let { 
          putExtra(CalendarContract.Events.EVENT_LOCATION, it as String) 
        }
        
        val startDate = eventData["startDate"] as Long
        putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startDate)
        
        eventData["endDate"]?.let {
          putExtra(CalendarContract.EXTRA_EVENT_END_TIME, it as Long)
        }
        
        val isAllDay = eventData["isAllDay"] as? Boolean ?: false
        putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, isAllDay)
        
        eventData["timeZone"]?.let {
          putExtra(CalendarContract.Events.EVENT_TIMEZONE, it as String)
        }
      }
      
      intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
      activity?.startActivity(intent) ?: context?.startActivity(intent)
      result.success(true)
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
        put(CalendarContract.Events.DTSTART, eventData["startDate"] as Long)
        eventData["endDate"]?.let {
          put(CalendarContract.Events.DTEND, it as Long)
        }
        put(CalendarContract.Events.TITLE, eventData["title"] as String)
        eventData["description"]?.let {
          put(CalendarContract.Events.DESCRIPTION, it as String)
        }
        eventData["location"]?.let {
          put(CalendarContract.Events.EVENT_LOCATION, it as String)
        }
        
        val isAllDay = eventData["isAllDay"] as? Boolean ?: false
        put(CalendarContract.Events.ALL_DAY, if (isAllDay) 1 else 0)
        
        eventData["timeZone"]?.let {
          put(CalendarContract.Events.EVENT_TIMEZONE, it as String)
        } ?: put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
        
        // Set calendar ID (default to 1 if not specified)
        val androidSettings = eventData["androidSettings"] as? Map<String, Any>
        val calendarId = androidSettings?.get("calendarId") as? Int ?: 1
        put(CalendarContract.Events.CALENDAR_ID, calendarId)
        
        // Set event status
        val eventStatus = androidSettings?.get("eventStatus") as? Int ?: 1
        put(CalendarContract.Events.STATUS, eventStatus)
        
        // Set visibility
        val visibility = androidSettings?.get("visibility") as? Int ?: 0
        put(CalendarContract.Events.ACCESS_LEVEL, visibility)
        
        // Set color if provided
        androidSettings?.get("eventColor")?.let {
          put(CalendarContract.Events.EVENT_COLOR, it as Int)
        }
        
        // Set guest permissions
        val guestsCanModify = androidSettings?.get("guestsCanModify") as? Boolean ?: false
        put(CalendarContract.Events.GUESTS_CAN_MODIFY, if (guestsCanModify) 1 else 0)
        
        val guestsCanInviteOthers = androidSettings?.get("guestsCanInviteOthers") as? Boolean ?: false
        put(CalendarContract.Events.GUESTS_CAN_INVITE_OTHERS, if (guestsCanInviteOthers) 1 else 0)
        
        val guestsCanSeeGuests = androidSettings?.get("guestsCanSeeGuests") as? Boolean ?: true
        put(CalendarContract.Events.GUESTS_CAN_SEE_GUESTS, if (guestsCanSeeGuests) 1 else 0)
      }

      val uri = context?.contentResolver?.insert(CalendarContract.Events.CONTENT_URI, values)
      
      // Add reminders if specified
      if (uri != null) {
        val hasAlarm = (eventData["androidSettings"] as? Map<String, Any>)?.get("hasAlarm") as? Boolean ?: true
        if (hasAlarm) {
          val reminderMinutes = (eventData["androidSettings"] as? Map<String, Any>)?.get("reminderMinutes") as? List<Int> ?: listOf(15)
          for (minutes in reminderMinutes) {
            val reminderValues = ContentValues().apply {
              put(CalendarContract.Reminders.EVENT_ID, uri.lastPathSegment?.toLong())
              put(CalendarContract.Reminders.MINUTES, minutes)
              put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
            }
            context?.contentResolver?.insert(CalendarContract.Reminders.CONTENT_URI, reminderValues)
          }
        }
      }
      
      result.success(uri != null)
    } catch (e: Exception) {
      result.success(false)
    }
  }

  private fun hasCalendarPermissions(): Boolean {
    return context?.let {
      ContextCompat.checkSelfPermission(it, Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED &&
      ContextCompat.checkSelfPermission(it, Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED
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

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
    if (requestCode == CALENDAR_PERMISSION_REQUEST_CODE) {
      val granted = grantResults.isNotEmpty() && 
                   grantResults.all { it == PackageManager.PERMISSION_GRANTED }
      pendingResult?.success(granted)
      pendingResult = null
      return true
    }
    return false
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
