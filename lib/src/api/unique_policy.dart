/// Policy for handling duplicate task enqueues with the same [uniqueId].
enum UniquePolicy {
  /// Keep the existing task, ignore the new one.
  keepExisting,

  /// Replace the existing task with the new one (cancel old, enqueue new).
  replace,
}
