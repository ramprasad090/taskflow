package dev.taskflow

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

/** CoroutineWorker that executes task handlers via headless Dart isolate. */
class TaskFlowWorker(
  appContext: Context,
  params: WorkerParameters,
) : CoroutineWorker(appContext, params) {

  companion object {
    const val KEY_TASK_NAME = "taskName"
    const val KEY_INPUT = "input"
    const val KEY_ATTEMPT = "attempt"
    const val KEY_EXECUTION_ID = "executionId"
  }

  override suspend fun doWork(): Result {
    // TODO: Implement worker logic
    // - Extract task name, input, attempt, executionId from inputData
    // - Invoke Dart handler via FlutterEngine
    // - Return success/failure/retry
    return Result.success()
  }
}
