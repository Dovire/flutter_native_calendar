# native_calendar

A Flutter plugin to add events to native calendar on Android and iOS with rich platform-specific settings and features.

## Features

- ✅ Open native calendar app with pre-filled event details
- ✅ Add events directly to calendar (with permissions)
- ✅ Request and check calendar permissions
- ✅ Platform-specific settings for Android and iOS
- ✅ Support for reminders, alarms, and advanced calendar features
- ✅ All-day events support
- ✅ Timezone support
- ✅ Attendees and guest permissions (Android)
- ✅ Event recurrence (iOS)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  native_calendar: ^0.0.1
```

## Platform Setup

### Android Setup

#### 1. Add Permissions

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Calendar permissions -->
    <uses-permission android:name="android.permission.READ_CALENDAR" />
    <uses-permission android:name="android.permission.WRITE_CALENDAR" />
    
    <application>
        <!-- Your app configuration -->
    </application>
</manifest>
```

#### 2. ProGuard Rules (if using code obfuscation)

Add the following rules to your `android/app/proguard-rules.pro`:

```pro
# Keep calendar provider classes
-keep class android.provider.CalendarContract** { *; }
-keep class android.content.ContentValues { *; }

# Keep plugin classes
-keep class com.dovireinfotech.native_calendar.** { *; }
```

#### 3. Proguard / R8 exceptions

By default, Android apps use R8 for shrinking/obfuscation in release builds. In some cases, it can interfere with calendar querying functions (e.g., retrieveCalendars()). You may add the following rule to your `proguard-rules.pro` to prevent stripping related classes:

```pro
-keep class com.builttoroam.devicecalendar.** { *; }
```

See your app module’s ProGuard configuration (usually `android/app/proguard-rules.pro`) for where to place these rules. Refer to the Android developer docs for more about R8 and keep rules.

#### 4. Minimum SDK Version

Ensure your `android/app/build.gradle` has minimum SDK version 16 or higher:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 16  // Minimum required
        targetSdkVersion 34
        // ... other configurations
    }
}
```

### iOS Setup

#### 1. Add Privacy Usage Descriptions

Add the following to your `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- Existing keys... -->
    
    <!-- Calendar access (required) -->
    <key>NSCalendarsUsageDescription</key>
    <string>Access most functions for calendar viewing and editing.</string>

    <!-- iOS 17+: Full Calendar access -->
    <key>NSCalendarsFullAccessUsageDescription</key>
    <string>Access most functions for calendar viewing and editing.</string>

    <!-- Contacts access if adding attendees from contacts -->
    <key>NSContactsUsageDescription</key>
    <string>Access contacts for event attendee editing.</string>

    <!-- Optional: If you want to access reminders as well -->
    <key>NSRemindersUsageDescription</key>
    <string>This app needs access to reminders to manage calendar events.</string>
</dict>
```

Note: This plugin uses Swift on iOS. There is a known issue when adding a Swift-based plugin to an Objective‑C project. If you encounter build issues, see Flutter’s guidance on integrating Swift plugins into Objective‑C apps and apply the suggested workarounds.

#### 2. Minimum iOS Version

Ensure your `ios/Podfile` targets iOS 11.0 or higher:

```ruby
platform :ios, '11.0'
```

#### 3. EventKit Framework

The plugin automatically includes EventKit framework, but you can verify it's included in your `ios/Runner.xcodeproj`:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your target
3. Go to "Build Phases" → "Link Binary With Libraries"
4. Ensure `EventKit.framework` and `EventKitUI.framework` are listed

## Usage

### Basic Example

```dart
import 'package:native_calendar/native_calendar.dart';

// Create a simple event
final event = CalendarEvent(
  title: 'Team Meeting',
  startDate: DateTime.now().add(Duration(hours: 1)),
  endDate: DateTime.now().add(Duration(hours: 2)),
  description: 'Discuss project progress and next steps',
  location: 'Conference Room A',
);

// Option 1: Open calendar app with pre-filled event (recommended)
bool success = await NativeCalendar.openCalendarWithEvent(event);
if (success) {
  print('Calendar opened successfully');
} else {
  print('Failed to open calendar');
}

// Option 2: Add event directly to calendar (requires permissions)
bool hasPermissions = await NativeCalendar.hasCalendarPermissions();
if (!hasPermissions) {
  hasPermissions = await NativeCalendar.requestCalendarPermissions();
}

if (hasPermissions) {
  bool eventAdded = await NativeCalendar.addEventToCalendar(event);
  if (eventAdded) {
    print('Event added successfully');
  }
}
```

### Advanced Example with Platform-Specific Settings

```dart
import 'package:native_calendar/native_calendar.dart';

// Create event with platform-specific settings
final event = CalendarEvent(
  title: 'Important Business Meeting',
  startDate: DateTime.now().add(Duration(days: 1)),
  endDate: DateTime.now().add(Duration(days: 1, hours: 2)),
  description: 'Quarterly review meeting',
  location: 'Board Room, 15th Floor',
  timeZone: 'America/New_York',
  url: 'https://zoom.us/j/123456789',
  
  // Android-specific settings
  androidSettings: AndroidEventSettings(
    attendees: ['john@company.com', 'jane@company.com'],
    reminderMinutes: [15, 60], // 15 minutes and 1 hour before
    eventStatus: 1, // confirmed
    visibility: 2, // private
    hasAlarm: true,
    guestsCanModify: false,
    guestsCanInviteOthers: false,
    guestsCanSeeGuests: true,
  ),
  
  // iOS-specific settings
  iosSettings: IosEventSettings(
    attendees: ['john@company.com', 'jane@company.com'],
    alarmMinutes: [15, 60], // 15 minutes and 1 hour before
    availability: 1, // busy
    priority: 1, // high priority
  ),
);

// Add to calendar
bool success = await NativeCalendar.addEventToCalendar(event);
```

### All-Day Event Example

```dart
final allDayEvent = CalendarEvent(
  title: 'Company Holiday',
  startDate: DateTime(2024, 12, 25),
  isAllDay: true,
  description: 'Christmas Day - Office Closed',
);

await NativeCalendar.openCalendarWithEvent(allDayEvent);
```

### Permission Handling

```dart
// Check if permissions are granted
bool hasPermissions = await NativeCalendar.hasCalendarPermissions();

if (!hasPermissions) {
  // Request permissions
  bool granted = await NativeCalendar.requestCalendarPermissions();
  
  if (granted) {
    // Proceed with calendar operations
    print('Calendar permissions granted');
  } else {
    // Handle permission denial
    print('Calendar permissions denied');
    // Show explanation dialog or redirect to settings
  }
}
```

## API Reference

### CalendarEvent

| Property | Type | Description | Required |
|----------|------|-------------|----------|
| `title` | `String` | Event title | ✅ |
| `startDate` | `DateTime` | Event start date and time | ✅ |
| `endDate` | `DateTime?` | Event end date and time | ❌ |
| `description` | `String?` | Event description/notes | ❌ |
| `location` | `String?` | Event location | ❌ |
| `isAllDay` | `bool` | Whether event is all-day (default: false) | ❌ |
| `timeZone` | `String?` | Timezone identifier | ❌ |
| `url` | `String?` | Associated URL | ❌ |
| `androidSettings` | `AndroidEventSettings?` | Android-specific settings | ❌ |
| `iosSettings` | `IosEventSettings?` | iOS-specific settings | ❌ |

### AndroidEventSettings

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `attendees` | `List<String>?` | List of attendee emails | `null` |
| `calendarId` | `int?` | Target calendar ID | `null` (default) |
| `eventStatus` | `int` | Event status (0=tentative, 1=confirmed, 2=canceled) | `1` |
| `visibility` | `int` | Visibility (0=default, 1=confidential, 2=private, 3=public) | `0` |
| `hasAlarm` | `bool` | Whether to set reminders | `true` |
| `reminderMinutes` | `List<int>?` | Reminder times in minutes before event | `[15]` |
| `eventColor` | `int?` | Event color as integer | `null` |
| `guestsCanModify` | `bool` | Whether guests can modify | `false` |
| `guestsCanInviteOthers` | `bool` | Whether guests can invite others | `false` |
| `guestsCanSeeGuests` | `bool` | Whether guests can see other guests | `true` |

### IosEventSettings

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `calendarIdentifier` | `String?` | Target calendar identifier | `null` (default) |
| `attendees` | `List<String>?` | List of attendee emails | `null` |
| `availability` | `int` | Availability (1=busy, 2=free, 3=tentative, 4=unavailable) | `1` |
| `alarmMinutes` | `List<int>?` | Alarm times in minutes before event | `[15]` |
| `priority` | `int` | Priority (1-4=high, 5=normal, 6-9=low) | `5` |
| `hasRecurrenceRules` | `bool` | Whether event has recurrence | `false` |
| `recurrenceFrequency` | `String?` | Recurrence frequency | `null` |
| `recurrenceInterval` | `int?` | Recurrence interval | `null` |
| `recurrenceEndDate` | `DateTime?` | Recurrence end date | `null` |

### Methods

#### `NativeCalendar.openCalendarWithEvent(CalendarEvent event)`
Opens the native calendar app with pre-filled event details. User can review and save manually.
- **Returns**: `Future<bool>` - true if calendar opened successfully
- **Permissions**: Not required (but recommended for better UX)

#### `NativeCalendar.addEventToCalendar(CalendarEvent event)`
Adds event directly to calendar without user interaction.
- **Returns**: `Future<bool>` - true if event was added successfully
- **Permissions**: Required (WRITE_CALENDAR, READ_CALENDAR)

#### `NativeCalendar.hasCalendarPermissions()`
Checks if calendar permissions are granted.
- **Returns**: `Future<bool>` - true if permissions granted

#### `NativeCalendar.requestCalendarPermissions()`
Requests calendar permissions from user.
- **Returns**: `Future<bool>` - true if permissions granted

## Troubleshooting

### Android Issues

1. **Permission Denied**: Ensure you've added calendar permissions to AndroidManifest.xml
2. **Calendar Not Opening**: Check if device has a calendar app installed
3. **Events Not Saving**: Verify WRITE_CALENDAR permission is granted

### iOS Issues

1. **Permission Denied**: Ensure NSCalendarsUsageDescription is added to Info.plist
2. **Calendar Not Opening**: Ensure EventKit/EventKitUI frameworks are linked
3. **iOS Simulator**: Calendar permissions might behave differently on simulator vs device

### General Issues

1. **Plugin Not Found**: Run `flutter clean` and `flutter pub get`
2. **Build Errors**: Ensure minimum SDK/iOS versions are met
3. **Date Issues**: Always use UTC or properly handle timezones

## Example App

See the [example](example/) directory for a complete working app demonstrating all features.

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our GitHub repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
