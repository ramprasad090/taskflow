/// Priority level for a background task.
enum TaskPriority {
  /// High priority. Android: uses setExpedited(). iOS: uses BGAppRefreshTask.
  high,

  /// Normal priority. Android: OneTimeWorkRequest. iOS: BGProcessingTask.
  normal,

  /// Low priority. Android: OneTimeWorkRequest with idle constraint. iOS: BGProcessingTask with requiresExternalPower.
  low,
}
