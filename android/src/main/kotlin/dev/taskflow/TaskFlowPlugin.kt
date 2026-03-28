package dev.taskflow

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** TaskFlowPlugin */
class TaskFlowPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var eventSink: EventChannel.EventSink? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "dev.taskflow/channel")
    eventChannel = EventChannel(binding.binaryMessenger, "dev.taskflow/events")
    channel.setMethodCallHandler(this)
    eventChannel.setStreamHandler(
      object : EventChannel.StreamHandler {
        override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
          eventSink = sink
        }

        override fun onCancel(args: Any?) {
          eventSink = null
        }
      }
    )
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "initialize" -> handleInitialize(result)
      "enqueue" -> handleEnqueue(call, result)
      "enqueueChain" -> handleEnqueueChain(call, result)
      "schedule" -> handleSchedule(call, result)
      "reschedule" -> handleReschedule(call, result)
      "unschedule" -> handleUnschedule(call, result)
      "cancel" -> handleCancel(call, result)
      "cancelExecution" -> handleCancelExecution(call, result)
      "cancelChain" -> handleCancelChain(call, result)
      "cancelByTag" -> handleCancelByTag(call, result)
      "cancelAll" -> handleCancelAll(result)
      "getStatus" -> handleGetStatus(call, result)
      "getAllTasks" -> handleGetAllTasks(result)
      "getTasksByTag" -> handleGetTasksByTag(call, result)
      "reportProgress" -> handleReportProgress(call, result)
      else -> result.notImplemented()
    }
  }

  private fun handleInitialize(result: Result) {
    // Initialize WorkManager and other platform components
    result.success(null)
  }

  private fun handleEnqueue(call: MethodCall, result: Result) {
    // Generate execution ID
    val executionId = "exec-${System.currentTimeMillis()}-${(0..999).random()}"
    result.success(executionId)

    // Simulate task execution with status updates
    simulateTaskExecution(executionId)
  }

  private fun simulateTaskExecution(executionId: String) {
    val mainHandler = Handler(Looper.getMainLooper())

    Thread {
      try {
        // Emit Queued status
        mainHandler.post {
          eventSink?.success(mapOf(
            "executionId" to executionId,
            "taskName" to "exampleTask",
            "type" to "queued"
          ))
        }

        Thread.sleep(500)

        // Emit Running status with progress
        for (i in 1..5) {
          Thread.sleep(400)
          mainHandler.post {
            eventSink?.success(mapOf(
              "executionId" to executionId,
              "taskName" to "exampleTask",
              "type" to "running",
              "progress" to (i * 0.2)
            ))
          }
        }

        Thread.sleep(500)

        // Emit Succeeded status
        mainHandler.post {
          eventSink?.success(mapOf(
            "executionId" to executionId,
            "taskName" to "exampleTask",
            "type" to "succeeded",
            "data" to mapOf("result" to "Task completed successfully!")
          ))
        }
      } catch (e: Exception) {
        e.printStackTrace()
      }
    }.start()
  }

  private fun handleEnqueueChain(call: MethodCall, result: Result) {
    // TODO: Implement chain enqueuing
    result.success("dummy-chain-id")
  }

  private fun handleSchedule(call: MethodCall, result: Result) {
    // TODO: Implement periodic scheduling
    result.success(null)
  }

  private fun handleReschedule(call: MethodCall, result: Result) {
    result.success(null)
  }

  private fun handleUnschedule(call: MethodCall, result: Result) {
    result.success(null)
  }

  private fun handleCancel(call: MethodCall, result: Result) {
    result.success(null)
  }

  private fun handleCancelExecution(call: MethodCall, result: Result) {
    result.success(null)
  }

  private fun handleCancelChain(call: MethodCall, result: Result) {
    result.success(null)
  }

  private fun handleCancelByTag(call: MethodCall, result: Result) {
    result.success(null)
  }

  private fun handleCancelAll(result: Result) {
    result.success(null)
  }

  private fun handleGetStatus(call: MethodCall, result: Result) {
    result.success(null)
  }

  private fun handleGetAllTasks(result: Result) {
    result.success(emptyList<Any>())
  }

  private fun handleGetTasksByTag(call: MethodCall, result: Result) {
    result.success(emptyList<Any>())
  }

  private fun handleReportProgress(call: MethodCall, result: Result) {
    result.success(null)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }
}
