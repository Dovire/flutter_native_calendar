/// Represents a calendar event with cross-platform and platform-specific settings.
class CalendarEvent {
  /// The title of the event
  final String title;
  
  /// The description/notes of the event
  final String? description;
  
  /// The start date and time of the event
  final DateTime startDate;
  
  /// The end date and time of the event
  final DateTime? endDate;
  
  /// The location of the event (can be string or EventLocation)
  final dynamic location;
  
  /// Whether this is an all-day event
  final bool isAllDay;
  
  /// The timezone identifier (e.g., "America/New_York")
  final String? timeZone;
  
  /// URL associated with the event
  final String? url;
  
  /// Android-specific settings
  final AndroidEventSettings? androidSettings;
  
  /// iOS-specific settings
  final IosEventSettings? iosSettings;

  const CalendarEvent({
    required this.title,
    required this.startDate,
    this.description,
    this.endDate,
    this.location,
    this.isAllDay = false,
    this.timeZone,
    this.url,
    this.androidSettings,
    this.iosSettings,
  }) : assert(location == null || location is String || location is EventLocation, 
              'Location must be either a String or EventLocation object');

  /// Converts the event to a map for platform channel communication
  Map<String, dynamic> toMap() {
    dynamic locationData;
    if (location is EventLocation) {
      locationData = (location as EventLocation).toMap();
    } else if (location is String) {
      locationData = location;
    }
    
    return {
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'location': locationData,
      'isAllDay': isAllDay,
      'timeZone': timeZone,
      'url': url,
      'androidSettings': androidSettings?.toMap(),
      'iosSettings': iosSettings?.toMap(),
    };
  }
}

/// Recurrence frequency options for calendar events
enum RecurrenceFrequency {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly'),
  yearly('yearly');

  const RecurrenceFrequency(this.value);
  final String value;
  
  @override
  String toString() => value;
}

/// Location information for calendar events
class EventLocation {
  /// The display name/title of the location
  final String title;
  
  /// Full address of the location
  final String? address;
  
  /// Latitude coordinate
  final double? latitude;
  
  /// Longitude coordinate
  final double? longitude;
  
  /// Radius in meters (for geofencing/proximity alerts)
  final double? radius;
  
  /// Additional notes about the location
  final String? notes;

  const EventLocation({
    required this.title,
    this.address,
    this.latitude,
    this.longitude,
    this.radius,
    this.notes,
  }) : assert(latitude == null || (latitude >= -90 && latitude <= 90), 'Latitude must be between -90 and 90'),
       assert(longitude == null || (longitude >= -180 && longitude <= 180), 'Longitude must be between -180 and 180'),
       assert(radius == null || radius > 0, 'Radius must be positive');

  /// Creates a simple location with just a title
  const EventLocation.simple(String title) : this(title: title);
  
  /// Creates a location with coordinates
  const EventLocation.withCoordinates({
    required String title,
    required double latitude,
    required double longitude,
    String? address,
    double? radius,
    String? notes,
  }) : this(
    title: title,
    address: address,
    latitude: latitude,
    longitude: longitude,
    radius: radius,
    notes: notes,
  );

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'notes': notes,
    };
  }
  
  @override
  String toString() => title;
}

/// Android-specific calendar event settings
class AndroidEventSettings {
  /// Calendar ID to add the event to (null for default calendar)
  final int? calendarId;
  
  /// Event status (0 = tentative, 1 = confirmed, 2 = canceled)
  final int eventStatus;
  
  /// Visibility (0 = default, 1 = confidential, 2 = private, 3 = public)
  final int visibility;
  
  /// Whether the event has an alarm/reminder
  final bool hasAlarm;
  
  /// Reminder minutes before the event (e.g., 15 for 15 minutes before)
  final List<int>? reminderMinutes;
  
  /// Event color (as integer)
  final int? eventColor;

  const AndroidEventSettings({
    this.calendarId,
    this.eventStatus = 1, // confirmed by default
    this.visibility = 0, // default visibility
    this.hasAlarm = true,
    this.reminderMinutes = const [15], // 15 minutes before by default
    this.eventColor,
  }) : assert(eventStatus >= 0 && eventStatus <= 2, 'Event status must be 0 (tentative), 1 (confirmed), or 2 (canceled)'),
       assert(visibility >= 0 && visibility <= 3, 'Visibility must be between 0 and 3'),
       assert(calendarId == null || calendarId >= 0, 'Calendar ID must be non-negative');

  Map<String, dynamic> toMap() {
    return {
      'calendarId': calendarId,
      'eventStatus': eventStatus,
      'visibility': visibility,
      'hasAlarm': hasAlarm,
      'reminderMinutes': reminderMinutes,
      'eventColor': eventColor,
    };
  }
}

/// iOS-specific calendar event settings
class IosEventSettings {
  /// The calendar identifier to add the event to (null for default calendar)
  final String? calendarIdentifier;
  
  /// Event availability (0 = not supported, 1 = busy, 2 = free, 3 = tentative, 4 = unavailable)
  final int availability;
  
  /// List of alarms (in minutes before the event)
  final List<int>? alarmMinutes;
  
  /// Event priority (0 = undefined, 1-4 = high, 5 = normal, 6-9 = low)
  final int priority;
  
  /// Whether the event has recurrence rules
  final bool hasRecurrenceRules;
  
  /// Recurrence frequency (daily, weekly, monthly, yearly)
  final RecurrenceFrequency? recurrenceFrequency;
  
  /// Recurrence interval (e.g., every 2 weeks)
  final int? recurrenceInterval;
  
  /// End date for recurrence
  final DateTime? recurrenceEndDate;

  const IosEventSettings({
    this.calendarIdentifier,
    this.availability = 1, // busy by default
    this.alarmMinutes = const [15], // 15 minutes before by default
    this.priority = 5, // normal priority
    this.hasRecurrenceRules = false,
    this.recurrenceFrequency,
    this.recurrenceInterval,
    this.recurrenceEndDate,
  }) : assert(availability >= 0 && availability <= 4, 'Availability must be between 0 and 4'),
       assert(priority >= 0 && priority <= 9, 'Priority must be between 0 and 9'),
       assert(alarmMinutes == null || alarmMinutes.length <= 2, 'iOS supports maximum 2 alarms per event'),
       assert(!hasRecurrenceRules || recurrenceFrequency != null, 'Recurrence frequency is required when hasRecurrenceRules is true'),
       assert(recurrenceInterval == null || recurrenceInterval > 0, 'Recurrence interval must be positive');

  Map<String, dynamic> toMap() {
    return {
      'calendarIdentifier': calendarIdentifier,
      'availability': availability,
      'alarmMinutes': alarmMinutes,
      'priority': priority,
      'hasRecurrenceRules': hasRecurrenceRules,
      'recurrenceFrequency': recurrenceFrequency?.value,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceEndDate': recurrenceEndDate?.millisecondsSinceEpoch,
    };
  }
}
