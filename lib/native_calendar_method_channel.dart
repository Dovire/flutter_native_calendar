import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'calendar_event.dart';
import 'native_calendar_platform_interface.dart';

/// An implementation of [NativeCalendarPlatform] that uses method channels.
class MethodChannelNativeCalendar extends NativeCalendarPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_native_calendar');

  @override
  Future<bool> openCalendarWithEvent(CalendarEvent event) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'openCalendarWithEvent',
        event.toMap(),
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error opening calendar: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> addEventToCalendar(CalendarEvent event) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'addEventToCalendar',
        event.toMap(),
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error adding event to calendar: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> hasCalendarPermissions() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('hasCalendarPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking calendar permissions: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> requestCalendarPermissions() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('requestCalendarPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error requesting calendar permissions: ${e.message}');
      return false;
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
