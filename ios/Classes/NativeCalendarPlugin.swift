import Flutter
import UIKit
import EventKit
import EventKitUI

public class NativeCalendarPlugin: NSObject, FlutterPlugin {
  private let eventStore = EKEventStore()
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_native_calendar", binaryMessenger: registrar.messenger())
    let instance = NativeCalendarPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "openCalendarWithEvent":
      if let args = call.arguments as? [String: Any] {
        openCalendarWithEvent(args: args, result: result)
      } else {
        result(false)
      }
    case "addEventToCalendar":
      if let args = call.arguments as? [String: Any] {
        addEventToCalendar(args: args, result: result)
      } else {
        result(false)
      }
    case "hasCalendarPermissions":
      result(hasCalendarPermissions())
    case "requestCalendarPermissions":
      requestCalendarPermissions(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func openCalendarWithEvent(args: [String: Any], result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard let title = args["title"] as? String,
            let startTimestamp = args["startDate"] as? Double else {
        result(false)
        return
      }
      
      let event = EKEvent(eventStore: self.eventStore)
      event.title = title
      event.startDate = Date(timeIntervalSince1970: startTimestamp / 1000.0)
      
      if let endTimestamp = args["endDate"] as? Double {
        event.endDate = Date(timeIntervalSince1970: endTimestamp / 1000.0)
      } else {
        event.endDate = event.startDate.addingTimeInterval(3600) // 1 hour default
      }
      
      if let description = args["description"] as? String {
        event.notes = description
      }
      
      if let location = args["location"] as? String {
        event.location = location
      }
      
      if let isAllDay = args["isAllDay"] as? Bool {
        event.isAllDay = isAllDay
      }
      
      if let url = args["url"] as? String, let eventUrl = URL(string: url) {
        event.url = eventUrl
      }
      
      // Apply iOS-specific settings
      if let iosSettings = args["iosSettings"] as? [String: Any] {
        self.applyIosSettings(to: event, settings: iosSettings)
      }
      
      // Set default calendar
      event.calendar = self.eventStore.defaultCalendarForNewEvents
      
      let eventController = EKEventEditViewController()
      eventController.event = event
      eventController.eventStore = self.eventStore
      eventController.editViewDelegate = self
      
      if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
        var presentingController = rootViewController
        while let presented = presentingController.presentedViewController {
          presentingController = presented
        }
        presentingController.present(eventController, animated: true, completion: nil)
        result(true)
      } else {
        result(false)
      }
    }
  }
  
  private func addEventToCalendar(args: [String: Any], result: @escaping FlutterResult) {
    guard hasCalendarPermissions() else {
      result(false)
      return
    }
    
    guard let title = args["title"] as? String,
          let startTimestamp = args["startDate"] as? Double else {
      result(false)
      return
    }
    
    let event = EKEvent(eventStore: eventStore)
    event.title = title
    event.startDate = Date(timeIntervalSince1970: startTimestamp / 1000.0)
    
    if let endTimestamp = args["endDate"] as? Double {
      event.endDate = Date(timeIntervalSince1970: endTimestamp / 1000.0)
    } else {
      event.endDate = event.startDate.addingTimeInterval(3600) // 1 hour default
    }
    
    if let description = args["description"] as? String {
      event.notes = description
    }
    
    if let location = args["location"] as? String {
      event.location = location
    }
    
    if let isAllDay = args["isAllDay"] as? Bool {
      event.isAllDay = isAllDay
    }
    
    if let url = args["url"] as? String, let eventUrl = URL(string: url) {
      event.url = eventUrl
    }
    
    // Apply iOS-specific settings
    if let iosSettings = args["iosSettings"] as? [String: Any] {
      applyIosSettings(to: event, settings: iosSettings)
    }
    
    // Set calendar
    if let iosSettings = args["iosSettings"] as? [String: Any],
       let calendarIdentifier = iosSettings["calendarIdentifier"] as? String,
       let calendar = eventStore.calendar(withIdentifier: calendarIdentifier) {
      event.calendar = calendar
    } else {
      event.calendar = eventStore.defaultCalendarForNewEvents
    }
    
    // Add alarms
    if let iosSettings = args["iosSettings"] as? [String: Any],
       let alarmMinutes = iosSettings["alarmMinutes"] as? [Int] {
      for minutes in alarmMinutes {
        let alarm = EKAlarm(relativeOffset: TimeInterval(-minutes * 60))
        event.addAlarm(alarm)
      }
    } else {
      // Default 15 minute reminder
      let alarm = EKAlarm(relativeOffset: TimeInterval(-15 * 60))
      event.addAlarm(alarm)
    }
    
    do {
      try eventStore.save(event, span: .thisEvent)
      result(true)
    } catch {
      result(false)
    }
  }
  
  private func applyIosSettings(to event: EKEvent, settings: [String: Any]) {
    if let availability = settings["availability"] as? Int {
      switch availability {
      case 1:
        event.availability = .busy
      case 2:
        event.availability = .free
      case 3:
        event.availability = .tentative
      case 4:
        event.availability = .unavailable
      default:
        event.availability = .busy
      }
    }
    
    if let priority = settings["priority"] as? Int {
      event.priority = priority
    }
  }
  
  private func hasCalendarPermissions() -> Bool {
    return EKEventStore.authorizationStatus(for: .event) == .authorized
  }
  
  private func requestCalendarPermissions(result: @escaping FlutterResult) {
    eventStore.requestAccess(to: .event) { granted, error in
      DispatchQueue.main.async {
        result(granted)
      }
    }
  }
}

extension NativeCalendarPlugin: EKEventEditViewDelegate {
  public func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
    controller.dismiss(animated: true, completion: nil)
  }
}
