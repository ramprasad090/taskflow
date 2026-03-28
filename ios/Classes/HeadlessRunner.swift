import Flutter
import Foundation

/// Manages a headless FlutterEngine for background Dart task execution.
final class HeadlessRunner {
  static let shared = HeadlessRunner()

  private var engine: FlutterEngine?
  private var methodChannel: FlutterMethodChannel?

  private init() {}

  /// Starts the headless engine (if not already started).
  func start() {
    guard engine == nil else { return }

    engine = FlutterEngine(name: "taskflow_headless", project: nil, allowHeadlessExecution: true)

    // Run the Dart entrypoint
    let result = engine!.run(withEntrypoint: "taskflowDispatcher", libraryURI: nil)
    if !result {
      print("[TaskFlow] Failed to start headless engine")
      engine = nil
      return
    }

    methodChannel = FlutterMethodChannel(
      name: "dev.taskflow/channel",
      binaryMessenger: engine!.binaryMessenger
    )
  }

  /// Executes a task by name via the Dart handler.
  func executeTask(
    name: String,
    input: [String: Any],
    attempt: Int,
    executionId: String,
    completion: @escaping (Result<[String: Any], Error>) -> Void
  ) {
    start() // Ensure engine is running

    guard let mc = methodChannel else {
      completion(.failure(RunnerError.notStarted))
      return
    }

    mc.invokeMethod(
      "executeTask",
      arguments: [
        "name": name,
        "input": input,
        "attempt": attempt,
        "executionId": executionId,
      ]
    ) { result in
      if let dict = result as? [String: Any] {
        completion(.success(dict))
      } else if let error = result as? FlutterError {
        completion(.failure(RunnerError.dartError(error.message ?? "Unknown error")))
      } else {
        completion(.failure(RunnerError.invalidResponse))
      }
    }
  }
}

enum RunnerError: LocalizedError {
  case notStarted
  case invalidResponse
  case dartError(String)

  var errorDescription: String? {
    switch self {
    case .notStarted:
      return "Headless runner not started"
    case .invalidResponse:
      return "Invalid response from Dart"
    case let .dartError(msg):
      return "Dart error: \(msg)"
    }
  }
}
