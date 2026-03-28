import Foundation

/// Persists chain state in UserDefaults so chains survive app termination on iOS.
final class ChainPersistence {
  static let shared = ChainPersistence()

  private let defaults = UserDefaults.standard
  private let chainPrefix = "taskflow.chain."
  private let inputPrefix = "taskflow.input."

  private init() {}

  /// Saves chain state (step index, outputs, etc.)
  func saveChainState(chainId: String, state: [String: Any]) {
    if let data = try? JSONSerialization.data(withJSONObject: state) {
      defaults.set(data, forKey: chainPrefix + chainId)
    }
  }

  /// Loads chain state by ID.
  func loadChainState(chainId: String) -> [String: Any]? {
    guard let data = defaults.data(forKey: chainPrefix + chainId),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }
    return obj
  }

  /// Deletes chain state.
  func deleteChainState(chainId: String) {
    defaults.removeObject(forKey: chainPrefix + chainId)
  }

  /// Saves task input for later retrieval.
  func saveTaskInput(executionId: String, input: [String: Any]) {
    if let data = try? JSONSerialization.data(withJSONObject: input) {
      defaults.set(data, forKey: inputPrefix + executionId)
    }
  }

  /// Loads task input by execution ID.
  func loadTaskInput(executionId: String) -> [String: Any]? {
    guard let data = defaults.data(forKey: inputPrefix + executionId),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }
    return obj
  }

  /// Deletes task input.
  func deleteTaskInput(executionId: String) {
    defaults.removeObject(forKey: inputPrefix + executionId)
  }
}
