import BackgroundTasks
import Flutter
import UIKit

public class TaskFlowPlugin: NSObject, FlutterPlugin {
  private static var methodChannel: FlutterMethodChannel?
  private static var eventChannel: FlutterEventChannel?
  private static var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    methodChannel = FlutterMethodChannel(
      name: "dev.taskflow/channel",
      binaryMessenger: messenger
    )
    eventChannel = FlutterEventChannel(
      name: "dev.taskflow/events",
      binaryMessenger: messenger
    )

    let instance = TaskFlowPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel!)
    eventChannel?.setStreamHandler(instance)

    // Register BGTask identifiers early
    TaskScheduler.shared.registerAllTasks()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      handleInitialize(result)
    case "enqueue":
      handleEnqueue(call, result)
    case "enqueueChain":
      handleEnqueueChain(call, result)
    case "schedule":
      handleSchedule(call, result)
    case "reschedule":
      handleReschedule(call, result)
    case "unschedule":
      handleUnschedule(call, result)
    case "cancel":
      handleCancel(call, result)
    case "cancelExecution":
      handleCancelExecution(call, result)
    case "cancelChain":
      handleCancelChain(call, result)
    case "cancelByTag":
      handleCancelByTag(call, result)
    case "cancelAll":
      handleCancelAll(result)
    case "getStatus":
      handleGetStatus(call, result)
    case "getAllTasks":
      handleGetAllTasks(result)
    case "getTasksByTag":
      handleGetTasksByTag(call, result)
    case "reportProgress":
      handleReportProgress(call, result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleInitialize(_ result: @escaping FlutterResult) {
    result(nil)
  }

  private func handleEnqueue(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let executionId = "exec-\(Date().timeIntervalSince1970)-\(Int.random(in: 0...999))"
    result(executionId)

    // Simulate task execution with status updates
    simulateTaskExecution(executionId)
  }

  private func simulateTaskExecution(_ executionId: String) {
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
      // Emit Queued status
      TaskFlowPlugin.eventSink?([
        "executionId": executionId,
        "status": "TaskQueued"
      ])

      DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
        // Emit Running status with progress
        for i in 1...5 {
          DispatchQueue.global().asyncAfter(deadline: .now() + Double(i - 1) * 0.4) {
            TaskFlowPlugin.eventSink?([
              "executionId": executionId,
              "status": "TaskRunning",
              "progress": Double(i) * 0.2
            ])
          }
        }

        // Emit Succeeded status
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
          TaskFlowPlugin.eventSink?([
            "executionId": executionId,
            "status": "TaskSucceeded",
            "output": ["result": "Task completed successfully!"]
          ])
        }
      }
    }
  }

  private func handleEnqueueChain(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    result("dummy-chain-id")
  }

  private func handleSchedule(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    result(nil)
  }

  private func handleReschedule(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    result(nil)
  }

  private func handleUnschedule(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    result(nil)
  }

  private func handleCancel(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    result(nil)
  }

  private func handleCancelExecution(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    result(nil)
  }

  private func handleCancelChain(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    result(nil)
  }

  private func handleCancelByTag(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    result(nil)
  }

  private func handleCancelAll(_ result: @escaping FlutterResult) {
    result(nil)
  }

  private func handleGetStatus(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    result(nil)
  }

  private func handleGetAllTasks(_ result: @escaping FlutterResult) {
    result([])
  }

  private func handleGetTasksByTag(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    result([])
  }

  private func handleReportProgress(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    result(nil)
  }
}

extension TaskFlowPlugin: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    TaskFlowPlugin.eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    TaskFlowPlugin.eventSink = nil
    return nil
  }
}
