## 0.0.1

## 0.0.1

* Initial release of native_calendar plugin
* Add support for opening native calendar app with pre-filled event details
* Add support for directly adding events to calendar (with permissions)
* Comprehensive CalendarEvent class with platform-specific settings:
  - AndroidEventSettings for Android-specific features
  - IosEventSettings for iOS-specific features
* Calendar permission management (check and request permissions)
* Support for all-day events, timezones, locations, and URLs
* Advanced features:
  - Reminders and alarms
  - Event attendees and guest permissions (Android)
  - Event recurrence support (iOS)
  - Event priority and availability settings
* Comprehensive example app demonstrating all features
* Complete documentation with setup instructions for both platforms
* Platform-specific implementation:
  - Android: Uses CalendarContract and Intent.ACTION_INSERT
  - iOS: Uses EventKit and EventKitUI frameworks
