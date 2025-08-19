import 'package:flutter/material.dart';
import 'package:flutter_native_calendar/native_calendar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  bool _hasPermissions = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    bool hasPermissions;

    try {
      platformVersion = await NativeCalendar.getPlatformVersion() ??
          'Unknown platform version';
      hasPermissions = await NativeCalendar.hasCalendarPermissions();
    } catch (e) {
      platformVersion = 'Failed to get platform version.';
      hasPermissions = false;
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _hasPermissions = hasPermissions;
    });
  }

  Future<void> _requestPermissions() async {
    try {
      bool granted = await NativeCalendar.requestCalendarPermissions();
      setState(() {
        _hasPermissions = granted;
        _statusMessage = granted
            ? 'Calendar permissions granted!'
            : 'Calendar permissions denied.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error requesting permissions: $e';
      });
    }
  }

  Future<void> _openCalendarWithBasicEvent() async {
    final event = CalendarEvent(
      title: 'Flutter Demo Event',
      startDate: DateTime.now().add(const Duration(hours: 1)),
      endDate: DateTime.now().add(const Duration(hours: 2)),
      description: 'This event was created using the native_calendar plugin',
      location: 'Flutter Developer Office',
    );

    try {
      bool success = await NativeCalendar.openCalendarWithEvent(event);
      setState(() {
        _statusMessage = success
            ? 'Calendar opened successfully!'
            : 'Failed to open calendar.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error opening calendar: $e';
      });
    }
  }

  Future<void> _addEventToCalendar() async {
    if (!_hasPermissions) {
      setState(() {
        _statusMessage =
            'Calendar permissions required. Please grant permissions first.';
      });
      return;
    }

    final event = CalendarEvent(
      title: 'Direct Calendar Event',
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 1, hours: 1)),
      description: 'This event was added directly to your calendar',
      location: const EventLocation.withCoordinates(
        title: 'Home Office',
        address: '123 Main Street, Anytown, USA',
        latitude: 37.7749,
        longitude: -122.4194,
        radius: 100.0,
        notes: 'Use the side entrance',
      ),
      androidSettings: const AndroidEventSettings(
        reminderMinutes: [15, 60], // 15 minutes and 1 hour before
        hasAlarm: true,
      ),
      iosSettings: IosEventSettings(
        alarmMinutes: [15, 60], // 15 minutes and 1 hour before
        priority: 5, // normal priority
      ),
    );

    try {
      bool success = await NativeCalendar.addEventToCalendar(event);
      setState(() {
        _statusMessage = success
            ? 'Event added to calendar successfully!'
            : 'Failed to add event to calendar.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error adding event: $e';
      });
    }
  }

  Future<void> _openAllDayEvent() async {
    final event = CalendarEvent(
      title: 'All-Day Event',
      startDate: DateTime.now().add(const Duration(days: 2)),
      isAllDay: true,
      description: 'This is an all-day event example',
    );

    try {
      bool success = await NativeCalendar.openCalendarWithEvent(event);
      setState(() {
        _statusMessage = success
            ? 'All-day event calendar opened!'
            : 'Failed to open calendar for all-day event.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error opening all-day event: $e';
      });
    }
  }

  Future<void> _openAdvancedEvent() async {
    final event = CalendarEvent(
      title: 'Advanced Meeting',
      startDate: DateTime.now().add(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 3, hours: 2)),
      description: 'Advanced event with platform-specific settings',
      location: const EventLocation.withCoordinates(
        title: 'Conference Room A',
        address: '456 Business Plaza, Suite 100, Corporate City, NY 10001',
        latitude: 40.7128,
        longitude: -74.0060,
        notes: '15th Floor, East Wing',
      ),
      url: 'https://zoom.us/j/123456789',
      timeZone: 'America/New_York',
      androidSettings: const AndroidEventSettings(
        reminderMinutes: [15, 30],
        eventStatus: 1, // confirmed
        visibility: 2, // private
        hasAlarm: true,
      ),
      iosSettings: IosEventSettings(
        alarmMinutes: [15, 30], // Maximum 2 alarms on iOS
        availability: 1, // busy
        priority: 1, // high priority
      ),
    );

    try {
      bool success = await NativeCalendar.openCalendarWithEvent(event);
      setState(() {
        _statusMessage = success
            ? 'Advanced event calendar opened!'
            : 'Failed to open calendar for advanced event.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error opening advanced event: $e';
      });
    }
  }

  Future<void> _openRecurringEvent() async {
    final event = CalendarEvent(
      title: 'Weekly Team Meeting',
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 1, hours: 1)),
      description: 'Recurring weekly team meeting',
      location: const EventLocation.simple('Conference Room B'),
      androidSettings: const AndroidEventSettings(
        reminderMinutes: [15],
        eventStatus: 1, // confirmed
        hasAlarm: true,
      ),
      iosSettings: IosEventSettings(
        alarmMinutes: const [15, 5], // 15 minutes and 5 minutes before (max 2)
        availability: 1, // busy
        priority: 5, // normal priority
        hasRecurrenceRules: true,
        recurrenceFrequency: RecurrenceFrequency.monthly,
        recurrenceInterval: 3,
        // recurrenceEndDate: DateTime.now().add(const Duration(days: 90)), // 3 months
      ),
    );

    try {
      bool success = await NativeCalendar.openCalendarWithEvent(event);
      setState(() {
        _statusMessage = success
            ? 'Recurring event calendar opened!'
            : 'Failed to open calendar for recurring event.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error opening recurring event: $e';
      });
    }
  }

  Future<void> _addEventWithMarker() async {
    if (!_hasPermissions) {
      setState(() {
        _statusMessage =
            'Calendar permissions required. Please grant permissions first.';
      });
      return;
    }

    final event = CalendarEvent(
      title: 'System Generated Event',
      startDate: DateTime.now().add(const Duration(hours: 2)),
      endDate: DateTime.now().add(const Duration(hours: 3)),
      description: 'This is a system-generated event that can be found using markers.',
      location: 'Demo Location',
      systemMarker: 'FLUTTER_DEMO_2024', // Marker will be automatically formatted and appended
    );

    try {
      bool success = await NativeCalendar.addEventToCalendar(event);
      setState(() {
        _statusMessage = success
            ? 'Event with marker added successfully! You can now search for it.'
            : 'Failed to add event with marker.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error adding event with marker: $e';
      });
    }
  }

  Future<void> _addEventWithMarkerOnly() async {
    if (!_hasPermissions) {
      setState(() {
        _statusMessage =
            'Calendar permissions required. Please grant permissions first.';
      });
      return;
    }

    final event = CalendarEvent(
      title: 'Marker-Only Event',
      startDate: DateTime.now().add(const Duration(hours: 4)),
      endDate: DateTime.now().add(const Duration(hours: 5)),
      // No description provided - marker will be the only content
      location: 'Demo Location',
      systemMarker: 'FLUTTER_DEMO_2024', // Only the marker will appear in description
    );

    try {
      bool success = await NativeCalendar.addEventToCalendar(event);
      setState(() {
        _statusMessage = success
            ? 'Event with marker-only description added successfully!'
            : 'Failed to add event with marker.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error adding event with marker: $e';
      });
    }
  }

  Future<void> _findEventsWithMarker() async {
    if (!_hasPermissions) {
      setState(() {
        _statusMessage =
            'Calendar permissions required. Please grant permissions first.';
      });
      return;
    }

    try {
      final eventIds = await NativeCalendar.findEventsWithMarker(
        'FLUTTER_DEMO_2024',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );
      
      setState(() {
        if (eventIds.isEmpty) {
          _statusMessage = 'No events found with the marker "FLUTTER_DEMO_2024". Try adding an event with marker first.';
        } else {
          _statusMessage = 'Found ${eventIds.length} event(s) with marker "FLUTTER_DEMO_2024":\n${eventIds.join(', ')}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error searching for events with marker: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Calendar Plugin Example'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform Information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('Running on: $_platformVersion'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _hasPermissions ? Icons.check_circle : Icons.cancel,
                            color: _hasPermissions ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _hasPermissions
                                ? 'Calendar permissions granted'
                                : 'Calendar permissions not granted',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_hasPermissions)
                ElevatedButton.icon(
                  onPressed: _requestPermissions,
                  icon: const Icon(Icons.security, color: Colors.black),
                  label: const Text('Request Calendar Permissions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Calendar Operations',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openCalendarWithBasicEvent,
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: const Text('Open Calendar with Basic Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addEventToCalendar,
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                label: const Text('Add Event Directly to Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _openAllDayEvent,
                icon: const Icon(
                  Icons.today,
                  color: Colors.white,
                ),
                label: const Text('Open Calendar with All-Day Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _openAdvancedEvent,
                icon: const Icon(
                  Icons.event,
                  color: Colors.white,
                ),
                label: const Text('Open Calendar with Advanced Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _openRecurringEvent,
                icon: const Icon(
                  Icons.repeat,
                  color: Colors.white,
                ),
                label: const Text('Open Calendar with Recurring Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Event Marker Operations',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addEventWithMarker,
                icon: const Icon(
                  Icons.bookmark_add,
                  color: Colors.white,
                ),
                label: const Text('Add Event with System Marker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addEventWithMarkerOnly,
                icon: const Icon(
                  Icons.bookmark,
                  color: Colors.white,
                ),
                label: const Text('Add Event with Marker Only'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _findEventsWithMarker,
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                label: const Text('Find Events with Marker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              if (_statusMessage.isNotEmpty)
                Card(
                  color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(_statusMessage),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
