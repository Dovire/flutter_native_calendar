import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'calendar_event.dart';
import 'native_calendar_method_channel.dart';

abstract class NativeCalendarPlatform extends PlatformInterface {
  /// Constructs a NativeCalendarPlatform.
  NativeCalendarPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeCalendarPlatform _instance = MethodChannelNativeCalendar();

  /// The default instance of [NativeCalendarPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeCalendar].
  static NativeCalendarPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeCalendarPlatform] when
  /// they register themselves.
  static set instance(NativeCalendarPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Opens the native calendar app with pre-filled event details.
  /// 
  /// Returns true if the calendar was successfully opened, false otherwise.
  Future<bool> openCalendarWithEvent(CalendarEvent event) {
    throw UnimplementedError('openCalendarWithEvent() has not been implemented.');
  }

  /// Adds an event directly to the calendar (requires calendar permissions).
  /// 
  /// Returns true if the event was successfully added, false otherwise.
  Future<bool> addEventToCalendar(CalendarEvent event) {
    throw UnimplementedError('addEventToCalendar() has not been implemented.');
  }

  /// Checks if calendar permissions are granted.
  /// 
  /// Returns true if permissions are granted, false otherwise.
  Future<bool> hasCalendarPermissions() {
    throw UnimplementedError('hasCalendarPermissions() has not been implemented.');
  }

  /// Requests calendar permissions from the user.
  /// 
  /// Returns true if permissions are granted, false otherwise.
  Future<bool> requestCalendarPermissions() {
    throw UnimplementedError('requestCalendarPermissions() has not been implemented.');
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
