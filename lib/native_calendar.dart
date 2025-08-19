export 'calendar_event.dart';

import 'calendar_event.dart';
import 'native_calendar_platform_interface.dart';

/// Main API class for the native_calendar plugin.
class NativeCalendar {
  /// Opens the native calendar app with pre-filled event details.
  ///
  /// This method opens the device's default calendar application
  /// with the event details pre-filled. The user can then review
  /// and save the event manually.
  ///
  /// Returns `true` if the calendar was successfully opened, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final event = CalendarEvent(
  ///   title: 'Meeting with Team',
  ///   startDate: DateTime.now().add(Duration(hours: 1)),
  ///   endDate: DateTime.now().add(Duration(hours: 2)),
  ///   description: 'Discuss project progress',
  ///   location: 'Conference Room A',
  /// );
  ///
  /// final success = await NativeCalendar.openCalendarWithEvent(event);
  /// if (success) {
  ///   print('Calendar opened successfully');
  /// } else {
  ///   print('Failed to open calendar');
  /// }
  /// ```
  static Future<bool> openCalendarWithEvent(CalendarEvent event) {
    return NativeCalendarPlatform.instance.openCalendarWithEvent(event);
  }

  /// Adds an event directly to the calendar without user interaction.
  ///
  /// This method requires calendar permissions and directly adds
  /// the event to the device's calendar without opening the calendar app.
  ///
  /// Returns `true` if the event was successfully added, `false` otherwise.
  ///
  /// Note: Make sure to request calendar permissions before calling this method.
  ///
  /// Example:
  /// ```dart
  /// // First check/request permissions
  /// bool hasPermissions = await NativeCalendar.hasCalendarPermissions();
  /// if (!hasPermissions) {
  ///   hasPermissions = await NativeCalendar.requestCalendarPermissions();
  /// }
  ///
  /// if (hasPermissions) {
  ///   final event = CalendarEvent(
  ///     title: 'Automated Reminder',
  ///     startDate: DateTime.now().add(Duration(days: 1)),
  ///     description: 'This event was added programmatically',
  ///   );
  ///
  ///   final success = await NativeCalendar.addEventToCalendar(event);
  ///   if (success) {
  ///     print('Event added successfully');
  ///   }
  /// }
  /// ```
  static Future<bool> addEventToCalendar(CalendarEvent event) {
    return NativeCalendarPlatform.instance.addEventToCalendar(event);
  }

  /// Checks if the app has calendar permissions.
  ///
  /// Returns `true` if calendar permissions are granted, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// bool hasPermissions = await NativeCalendar.hasCalendarPermissions();
  /// if (!hasPermissions) {
  ///   // Request permissions or show explanation to user
  /// }
  /// ```
  static Future<bool> hasCalendarPermissions() {
    return NativeCalendarPlatform.instance.hasCalendarPermissions();
  }

  /// Requests calendar permissions from the user.
  ///
  /// Returns `true` if permissions are granted, `false` if denied.
  ///
  /// Example:
  /// ```dart
  /// bool permissionsGranted = await NativeCalendar.requestCalendarPermissions();
  /// if (permissionsGranted) {
  ///   // Proceed with calendar operations
  /// } else {
  ///   // Show error message or alternative options
  /// }
  /// ```
  static Future<bool> requestCalendarPermissions() {
    return NativeCalendarPlatform.instance.requestCalendarPermissions();
  }

  /// Gets the platform version (for testing purposes).
  ///
  /// Returns the platform version string.
  static Future<String?> getPlatformVersion() {
    return NativeCalendarPlatform.instance.getPlatformVersion();
  }

  /// Finds calendar events that contain a specific marker in their description/notes.
  ///
  /// This method searches for events that have been marked with a system-generated
  /// identifier. The marker helps identify events that should not be manually modified.
  ///
  /// The marker format includes:
  /// - A unique identifier that can be set dynamically by the app
  /// - A warning message: "System Generated Event - Do not modify this line"
  ///
  /// On Android, the marker is searched in the event's description field.
  /// On iOS, the marker is searched in the event's notes field.
  ///
  /// [marker] - The unique marker string to search for in event descriptions/notes
  /// [startDate] - Optional start date to limit the search range (defaults to 30 days ago)
  /// [endDate] - Optional end date to limit the search range (defaults to 30 days from now)
  ///
  /// Returns a list of event IDs that contain the specified marker.
  ///
  /// Example:
  /// ```dart
  /// // Create an event with a system marker
  /// final event = CalendarEvent(
  ///   title: 'Automated Event',
  ///   startDate: DateTime.now().add(Duration(hours: 1)),
  ///   description: 'This event was created automatically',
  ///   systemMarker: 'APP_SYNC_2024', // Marker will be automatically formatted
  /// );
  /// await NativeCalendar.addEventToCalendar(event);
  ///
  /// // Search for events with that marker
  /// final eventIds = await NativeCalendar.findEventsWithMarker(
  ///   'APP_SYNC_2024',
  ///   startDate: DateTime.now().subtract(Duration(days: 7)),
  ///   endDate: DateTime.now().add(Duration(days: 7)),
  /// );
  ///
  /// print('Found ${eventIds.length} events with the marker');
  /// ```
  static Future<List<String>> findEventsWithMarker(
    String marker, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return NativeCalendarPlatform.instance.findEventsWithMarker(
      marker,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
