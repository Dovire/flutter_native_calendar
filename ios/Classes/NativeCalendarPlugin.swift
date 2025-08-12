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
      
      // Handle location (can be string or structured location object)
      if let locationData = args["location"] {
        self.setEventLocation(event: event, locationData: locationData)
      }
      
      if let isAllDay = args["isAllDay"] as? Bool {
        event.isAllDay = isAllDay
      }
      
      if let url = args["url"] as? String, let eventUrl = URL(string: url) {
        event.url = eventUrl
      }
      
      // Extract iOS settings once
      let iosSettings = args["iosSettings"] as? [String: Any]
      
      // Apply iOS-specific settings
      if let settings = iosSettings {
        self.applyIosSettings(to: event, settings: settings)
      }
      
      // Set calendar using extracted settings
      self.setEventCalendar(event: event, iosSettings: iosSettings)
      
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
    
    // Handle location (can be string or structured location object)
    if let locationData = args["location"] {
      setEventLocation(event: event, locationData: locationData)
    }
    
    if let isAllDay = args["isAllDay"] as? Bool {
      event.isAllDay = isAllDay
    }
    
    if let url = args["url"] as? String, let eventUrl = URL(string: url) {
      event.url = eventUrl
    }
    
    // Extract iOS settings once
    let iosSettings = args["iosSettings"] as? [String: Any]
    
    // Apply iOS-specific settings
    if let settings = iosSettings {
      applyIosSettings(to: event, settings: settings)
    }
    
    // Set calendar using extracted settings
    setEventCalendar(event: event, iosSettings: iosSettings)

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
    
    // Handle alarms (iOS allows maximum 2 alarms per event)
    if let alarmMinutes = settings["alarmMinutes"] as? [Int] {
      let limitedAlarms = Array(alarmMinutes.prefix(2)) // Limit to 2 alarms
      for minutes in limitedAlarms {
        let alarm = EKAlarm(relativeOffset: TimeInterval(-minutes * 60))
        event.addAlarm(alarm)
      }
    } else {
      // Default 15 minute reminder if no specific alarms are set
      let alarm = EKAlarm(relativeOffset: TimeInterval(-15 * 60))
      event.addAlarm(alarm)
    }
    
    // Handle recurrence rules
    if let hasRecurrence = settings["hasRecurrenceRules"] as? Bool, hasRecurrence {
      if let frequency = settings["recurrenceFrequency"] as? String {
        let recurrenceRule = createRecurrenceRule(
          frequency: frequency,
          interval: settings["recurrenceInterval"] as? Int,
          endDate: settings["recurrenceEndDate"] as? Double
        )
        if let rule = recurrenceRule {
          event.recurrenceRules = [rule]
        }
      }
    }
    
    // Note: EKEvent doesn't have a priority property (only EKReminder does)
    // For events, we could potentially add priority info to the notes/description
    // or use calendar colors as a workaround, but EventKit doesn't support direct event priority
    if let priority = settings["priority"] as? Int {
      // We could append priority info to notes as a workaround
      let priorityText = getPriorityText(priority)
      if !priorityText.isEmpty {
        let currentNotes = event.notes ?? ""
        event.notes = currentNotes.isEmpty ? priorityText : "\(currentNotes)\n\(priorityText)"
      }
    }
  }
  
  private func setEventCalendar(event: EKEvent, iosSettings: [String: Any]?) {
    if let settings = iosSettings,
       let calendarIdentifier = settings["calendarIdentifier"] as? String,
       let calendar = eventStore.calendar(withIdentifier: calendarIdentifier) {
      event.calendar = calendar
    } else {
      event.calendar = eventStore.defaultCalendarForNewEvents
    }
  }
  
  private func setEventLocation(event: EKEvent, locationData: Any) {
    if let locationString = locationData as? String {
      // Simple string location
      event.location = locationString
    } else if let locationMap = locationData as? [String: Any] {
      // Structured location object
      var locationText = ""
      
      if let title = locationMap["title"] as? String {
        locationText = title
      }
      
      if let address = locationMap["address"] as? String, !address.isEmpty {
        if !locationText.isEmpty {
          locationText += "\n" + address
        } else {
          locationText = address
        }
      }
      
      // Add coordinates info if available
      if let latitude = locationMap["latitude"] as? Double,
         let longitude = locationMap["longitude"] as? Double {
        let coordsText = String(format: "%.6f, %.6f", latitude, longitude)
        if !locationText.isEmpty {
          locationText += "\nCoordinates: " + coordsText
        } else {
          locationText = "Coordinates: " + coordsText
        }
      }
      
      // Add notes if available
      if let notes = locationMap["notes"] as? String, !notes.isEmpty {
        if !locationText.isEmpty {
          locationText += "\n" + notes
        } else {
          locationText = notes
        }
      }
      
      event.location = locationText.isEmpty ? nil : locationText
      
      // TODO: In future versions, we could create EKStructuredLocation for better integration
      // with Maps app, but for now we'll use the basic location string approach
    }
  }
  
  private func createRecurrenceRule(frequency: String, interval: Int?, endDate: Double?) -> EKRecurrenceRule? {
    var recurrenceFrequency: EKRecurrenceFrequency
    
    switch frequency.lowercased() {
    case "daily":
      recurrenceFrequency = .daily
    case "weekly":
      recurrenceFrequency = .weekly
    case "monthly":
      recurrenceFrequency = .monthly
    case "yearly":
      recurrenceFrequency = .yearly
    default:
      // Invalid frequency - return nil to prevent crash
      print("Invalid recurrence frequency: \(frequency). Must be daily, weekly, monthly, or yearly.")
      return nil
    }
    
    let recurrenceInterval = max(interval ?? 1, 1) // Ensure positive interval
    var recurrenceEnd: EKRecurrenceEnd?
    
    if let endTimestamp = endDate {
      let endDate = Date(timeIntervalSince1970: endTimestamp / 1000.0)
      recurrenceEnd = EKRecurrenceEnd(end: endDate)
    }
    
    return EKRecurrenceRule(
      recurrenceWith: recurrenceFrequency,
      interval: recurrenceInterval,
      end: recurrenceEnd
    )
  }
  
  private func getPriorityText(_ priority: Int) -> String {
    switch priority {
    case 1...4:
      return "[High Priority]"
    case 6...9:
      return "[Low Priority]"
    case 5:
      return "" // Normal priority, don't add text
    default:
      return ""
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
