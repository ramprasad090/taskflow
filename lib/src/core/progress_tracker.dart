/// Aggregates per-task progress into per-chain progress.
final class ProgressTracker {
  ProgressTracker._();

  /// Computes overall chain progress from step progress values.
  ///
  /// Averages the progress of all steps.
  /// If no steps have reported progress, returns 0.0.
  static double chainProgress(
    Map<String, double> stepProgress,
    int totalSteps,
  ) {
    if (totalSteps == 0) return 0.0;
    if (stepProgress.isEmpty) return 0.0;

    final sum = stepProgress.values.fold<double>(0.0, (a, b) => a + b);
    return (sum / totalSteps).clamp(0.0, 1.0);
  }
}
