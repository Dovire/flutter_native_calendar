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
}

void main() {
  final NativeCalendarPlatform initialPlatform = NativeCalendarPlatform.instance;

  test('$MethodChannelNativeCalendar is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeCalendar>());
  });

  test('getPlatformVersion', () async {
    MockNativeCalendarPlatform fakePlatform = MockNativeCalendarPlatform();
    NativeCalendarPlatform.instance = fakePlatform;

    expect(await NativeCalendar.getPlatformVersion(), '42');
  });
}
