import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_native_calendar/native_calendar.dart';
import 'package:flutter_native_calendar/native_calendar_platform_interface.dart';
import 'package:flutter_native_calendar/native_calendar_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeCalendarPlatform
    with MockPlatformInterfaceMixin
    implements NativeCalendarPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> openCalendarWithEvent(CalendarEvent event) => Future.value(true);

  @override
  Future<bool> addEventToCalendar(CalendarEvent event) => Future.value(true);

  @override
  Future<bool> hasCalendarPermissions() => Future.value(true);

  @override
  Future<bool> requestCalendarPermissions() => Future.value(true);

  @override
  Future<List<String>> findEventsWithMarker(
    String marker, {
    DateTime? startDate,
    DateTime? endDate,
  }) => Future.value(['event1', 'event2']);
}

void main() {
  final NativeCalendarPlatform initialPlatform =
      NativeCalendarPlatform.instance;

  test('$MethodChannelNativeCalendar is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeCalendar>());
  });

  test('getPlatformVersion', () async {
    MockNativeCalendarPlatform fakePlatform = MockNativeCalendarPlatform();
    NativeCalendarPlatform.instance = fakePlatform;

    expect(await NativeCalendar.getPlatformVersion(), '42');
  });

  test('findEventsWithMarker', () async {
    MockNativeCalendarPlatform fakePlatform = MockNativeCalendarPlatform();
    NativeCalendarPlatform.instance = fakePlatform;

    final eventIds = await NativeCalendar.findEventsWithMarker('TEST_MARKER');
    expect(eventIds, ['event1', 'event2']);
  });

  test('CalendarEvent with systemMarker and description', () {
    final event = CalendarEvent(
      title: 'Test Event',
      startDate: DateTime(2024, 1, 1),
      description: 'User provided description',
      systemMarker: 'TEST_MARKER',
    );

    final map = event.toMap();
    expect(map['description'], 'User provided description\n\n[MARKER:TEST_MARKER] System Generated Event - Do not modify this line');
  });

  test('CalendarEvent with systemMarker and no description', () {
    final event = CalendarEvent(
      title: 'Test Event',
      startDate: DateTime(2024, 1, 1),
      systemMarker: 'TEST_MARKER',
    );

    final map = event.toMap();
    expect(map['description'], '[MARKER:TEST_MARKER] System Generated Event - Do not modify this line');
  });

  test('CalendarEvent with systemMarker and empty description', () {
    final event = CalendarEvent(
      title: 'Test Event',
      startDate: DateTime(2024, 1, 1),
      description: '   ', // Whitespace only
      systemMarker: 'TEST_MARKER',
    );

    final map = event.toMap();
    expect(map['description'], '[MARKER:TEST_MARKER] System Generated Event - Do not modify this line');
  });

  test('CalendarEvent without systemMarker', () {
    final event = CalendarEvent(
      title: 'Test Event',
      startDate: DateTime(2024, 1, 1),
      description: 'User provided description',
    );

    final map = event.toMap();
    expect(map['description'], 'User provided description');
  });
}
