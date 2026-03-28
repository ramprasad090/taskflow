import Foundation

/// Maps TaskConstraints to iOS BGTask request properties.
struct ConstraintMapper {
  static func requiresNetwork(_ map: [String: Any]?) -> Bool {
    guard let network = map?["network"] as? String else { return false }
    return network == "connected" || network == "unmetered"
  }

  static func requiresCharging(_ map: [String: Any]?) -> Bool {
    (map?["requiresCharging"] as? Bool) == true
  }

  static func warnIgnoredConstraints(_ map: [String: Any]?) {
    if (map?["deviceIdle"] as? Bool) == true {
      print("[TaskFlow] WARNING: deviceIdle constraint is not supported on iOS and will be ignored.")
    }
  }
}
