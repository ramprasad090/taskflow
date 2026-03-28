/// Batch of tasks with lifecycle callbacks.
///
/// Enqueue multiple items as a single trackable unit with then/catch/finally callbacks.
///
/// Example:
/// ```dart
/// final batch = await TaskFlow.batch(
///   'uploadPhotos',
///   items: [photo1, photo2, photo3],
///   handler: (ctx, photo) async {
///     await uploadToServer(photo);
///     return TaskResult.success();
///   },
/// );
///
/// batch.then((results) {
///   print('All ${results.length} photos uploaded!');
/// }).catch((error) {
///   print('Upload failed: $error');
/// }).finally(() {
///   print('Batch complete');
/// });
/// ```
class TaskBatch {
  /// Unique batch ID
  final String batchId;

  /// Name of the task for each item
  final String taskName;

  /// Number of items in batch
  final int itemCount;

  /// Number of items completed
  int get completedCount => _completedCount;
  int _completedCount = 0;

  /// Number of items failed
  int get failedCount => _failedCount;
  int _failedCount = 0;

  /// Batch progress (0.0 - 1.0)
  double get progress => itemCount > 0 ? completedCount / itemCount : 0.0;

  final List<void Function(List<Map<String, dynamic>>)> _thenCallbacks = [];
  final List<void Function(Object)> _catchCallbacks = [];
  final List<void Function()> _finallyCallbacks = [];

  TaskBatch({
    required this.batchId,
    required this.taskName,
    required this.itemCount,
  });

  /// Register success callback
  TaskBatch then(void Function(List<Map<String, dynamic>>) callback) {
    _thenCallbacks.add(callback);
    return this;
  }

  /// Register error callback
  TaskBatch catch_(void Function(Object) callback) {
    _catchCallbacks.add(callback);
    return this;
  }

  /// Register finally callback
  TaskBatch finally_(void Function() callback) {
    _finallyCallbacks.add(callback);
    return this;
  }

  /// Internal: mark item as completed
  void _markCompleted() {
    _completedCount++;
    _checkCompletion();
  }

  /// Internal: mark item as failed
  void _markFailed() {
    _failedCount++;
    _checkCompletion();
  }

  /// Internal: check if batch is complete and fire callbacks
  void _checkCompletion() {
    if (_completedCount + _failedCount == itemCount) {
      if (_failedCount == 0) {
        for (final callback in _thenCallbacks) {
          try {
            callback([]);
          } catch (_) {}
        }
      } else {
        for (final callback in _catchCallbacks) {
          try {
            callback(Exception('$_failedCount items failed'));
          } catch (_) {}
        }
      }
      for (final callback in _finallyCallbacks) {
        try {
          callback();
        } catch (_) {}
      }
    }
  }
}
