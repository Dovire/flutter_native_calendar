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
  
  /// The location of the event
  final String? location;
  
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
  });

  /// Converts the event to a map for platform channel communication
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'location': location,
      'isAllDay': isAllDay,
      'timeZone': timeZone,
      'url': url,
      'androidSettings': androidSettings?.toMap(),
      'iosSettings': iosSettings?.toMap(),
    };
  }
}

/// Android-specific calendar event settings
class AndroidEventSettings {
  /// List of attendee email addresses
  final List<String>? attendees;
  
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
  
  /// Whether guests can modify the event
  final bool guestsCanModify;
  
  /// Whether guests can invite others
  final bool guestsCanInviteOthers;
  
  /// Whether guests can see other guests
  final bool guestsCanSeeGuests;

  const AndroidEventSettings({
    this.attendees,
    this.calendarId,
    this.eventStatus = 1, // confirmed by default
    this.visibility = 0, // default visibility
    this.hasAlarm = true,
    this.reminderMinutes = const [15], // 15 minutes before by default
    this.eventColor,
    this.guestsCanModify = false,
    this.guestsCanInviteOthers = false,
    this.guestsCanSeeGuests = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'attendees': attendees,
      'calendarId': calendarId,
      'eventStatus': eventStatus,
      'visibility': visibility,
      'hasAlarm': hasAlarm,
      'reminderMinutes': reminderMinutes,
      'eventColor': eventColor,
      'guestsCanModify': guestsCanModify,
      'guestsCanInviteOthers': guestsCanInviteOthers,
      'guestsCanSeeGuests': guestsCanSeeGuests,
    };
  }
}

/// iOS-specific calendar event settings
class IosEventSettings {
  /// The calendar identifier to add the event to (null for default calendar)
  final String? calendarIdentifier;
  
  /// List of attendee email addresses
  final List<String>? attendees;
  
  /// Event availability (0 = not supported, 1 = busy, 2 = free, 3 = tentative, 4 = unavailable)
  final int availability;
  
  /// List of alarms (in minutes before the event)
  final List<int>? alarmMinutes;
  
  /// Event priority (0 = undefined, 1-4 = high, 5 = normal, 6-9 = low)
  final int priority;
  
  /// Whether the event has recurrence rules
  final bool hasRecurrenceRules;
  
  /// Recurrence frequency (daily, weekly, monthly, yearly)
  final String? recurrenceFrequency;
  
  /// Recurrence interval (e.g., every 2 weeks)
  final int? recurrenceInterval;
  
  /// End date for recurrence
  final DateTime? recurrenceEndDate;

  const IosEventSettings({
    this.calendarIdentifier,
    this.attendees,
    this.availability = 1, // busy by default
    this.alarmMinutes = const [15], // 15 minutes before by default
    this.priority = 5, // normal priority
    this.hasRecurrenceRules = false,
    this.recurrenceFrequency,
    this.recurrenceInterval,
    this.recurrenceEndDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'calendarIdentifier': calendarIdentifier,
      'attendees': attendees,
      'availability': availability,
      'alarmMinutes': alarmMinutes,
      'priority': priority,
      'hasRecurrenceRules': hasRecurrenceRules,
      'recurrenceFrequency': recurrenceFrequency,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceEndDate': recurrenceEndDate?.millisecondsSinceEpoch,
    };
  }
}
