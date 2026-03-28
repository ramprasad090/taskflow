import BackgroundTasks
import Foundation

/// Manages BGTaskScheduler registration and task submission for iOS background execution.
final class TaskScheduler {
  static let shared = TaskScheduler()

  private init() {}

  var eventEmitter: (([String: Any]) -> Void)?

  /// Registers all BGTask identifiers. Must be called early (in AppDelegate).
  func registerAllTasks() {
    // Register refresh task (higher frequency, lighter execution)
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "dev.taskflow.refresh",
      using: nil
    ) { task in
      self.handleBGRefresh(task as! BGAppRefreshTask)
    }

    // Register processing task (longer execution window)
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "dev.taskflow.processing",
      using: nil
    ) { task in
      self.handleBGProcessing(task as! BGProcessingTask)
    }
  }

  func enqueue(
    name: String,
    executionId: String,
    priority: String,
    constraints: [String: Any]?,
    input: [String: Any]
  ) {
    let identifier = bgIdentifier(for: priority)
    let request = bgRequest(identifier: identifier, name: name, priority: priority, constraints: constraints)

    ChainPersistence.shared.saveTaskInput(executionId: executionId, input: input)

    do {
      try BGTaskScheduler.shared.submit(request)
      eventEmitter?(["type": "queued", "executionId": executionId, "taskName": name])
    } catch {
      eventEmitter?(["type": "failed", "executionId": executionId, "taskName": name, "error": error.localizedDescription])
    }
  }

  private func bgRequest(
    identifier: String,
    name: String,
    priority: String,
    constraints: [String: Any]?
  ) -> BGTaskRequest {
    if priority == "high" {
      let req = BGAppRefreshTaskRequest(identifier: identifier)
      req.earliestBeginDate = nil
      return req
    } else {
      let req = BGProcessingTaskRequest(identifier: identifier)
      req.requiresNetworkConnectivity = ConstraintMapper.requiresNetwork(constraints)
      req.requiresExternalPower = ConstraintMapper.requiresCharging(constraints) || priority == "low"
      return req
    }
  }

  private func bgIdentifier(for priority: String) -> String {
    priority == "high" ? "dev.taskflow.refresh" : "dev.taskflow.processing"
  }

  private func handleBGRefresh(_ task: BGAppRefreshTask) {
    // TODO: Implement refresh task execution
    task.setTaskCompleted(success: true)
  }

  private func handleBGProcessing(_ task: BGProcessingTask) {
    // TODO: Implement processing task execution
    task.setTaskCompleted(success: true)
  }
}
