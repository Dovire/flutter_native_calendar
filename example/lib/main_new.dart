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
      platformVersion = await NativeCalendar.getPlatformVersion() ?? 'Unknown platform version';
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
        _statusMessage = 'Calendar permissions required. Please grant permissions first.';
      });
      return;
    }

    final event = CalendarEvent(
      title: 'Direct Calendar Event',
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 1, hours: 1)),
      description: 'This event was added directly to your calendar',
      location: 'Home Office',
      androidSettings: const AndroidEventSettings(
        reminderMinutes: [15, 60], // 15 minutes and 1 hour before
        hasAlarm: true,
      ),
      iosSettings: const IosEventSettings(
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
      location: 'Conference Room A',
      url: 'https://zoom.us/j/123456789',
      timeZone: 'America/New_York',
      androidSettings: const AndroidEventSettings(
        attendees: ['colleague@company.com'],
        reminderMinutes: [15, 30, 60],
        eventStatus: 1, // confirmed
        visibility: 2, // private
        hasAlarm: true,
        guestsCanModify: false,
        guestsCanInviteOthers: true,
        guestsCanSeeGuests: true,
      ),
      iosSettings: const IosEventSettings(
        attendees: ['colleague@company.com'],
        alarmMinutes: [15, 30, 60],
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
                  icon: const Icon(Icons.security),
                  label: const Text('Request Calendar Permissions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
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
                icon: const Icon(Icons.calendar_today),
                label: const Text('Open Calendar with Basic Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              ElevatedButton.icon(
                onPressed: _addEventToCalendar,
                icon: const Icon(Icons.add),
                label: const Text('Add Event Directly to Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              ElevatedButton.icon(
                onPressed: _openAllDayEvent,
                icon: const Icon(Icons.today),
                label: const Text('Open Calendar with All-Day Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              ElevatedButton.icon(
                onPressed: _openAdvancedEvent,
                icon: const Icon(Icons.event),
                label: const Text('Open Calendar with Advanced Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
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
