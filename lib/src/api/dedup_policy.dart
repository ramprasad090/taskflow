/// Task deduplication policy to prevent duplicate enqueues.
///
/// Useful for preventing duplicate work when the same task is enqueued multiple times
/// with the same or similar input within a short time window.
///
/// Example:
/// ```dart
/// // Don't enqueue syncUser:123 if already queued
/// final dedup = DedupPolicy.byInput(ttl: Duration(minutes: 5));
///
/// await TaskFlow.enqueue(
///   'syncUser',
///   input: {'userId': '123'},
///   dedupPolicy: dedup,
/// );
/// ```
abstract class DedupPolicy {
  /// TTL for dedup entry (how long to consider a task as "already enqueued")
  final Duration ttl;

  DedupPolicy({required this.ttl});

  /// Generate dedup key from task name and input
  String generateKey(String taskName, Map<String, dynamic> input);

  /// Deduplicate by input hash
  /// Same input = same dedup key
  factory DedupPolicy.byInput({
    required Duration ttl,
  }) = _InputDedupPolicy;

  /// Deduplicate by specific input fields
  /// Only specified fields are considered for dedup
  factory DedupPolicy.byFields({
    required Duration ttl,
    required List<String> fields,
  }) = _FieldsDedupPolicy;

  /// Convert to map
  Map<String, dynamic> toMap() => {
    'ttl': ttl.inMilliseconds,
    'type': runtimeType.toString(),
  };
}

/// Dedup by full input hash
class _InputDedupPolicy extends DedupPolicy {
  _InputDedupPolicy({required Duration ttl}) : super(ttl: ttl);

  @override
  String generateKey(String taskName, Map<String, dynamic> input) {
    // Simple hash: just serialize input to string
    // In production, use crypto.sha256 for better collisions
    return '$taskName:${input.toString().hashCode}';
  }
}

/// Dedup by specific fields only
class _FieldsDedupPolicy extends DedupPolicy {
  final List<String> fields;

  _FieldsDedupPolicy({
    required Duration ttl,
    required this.fields,
  }) : super(ttl: ttl);

  @override
  String generateKey(String taskName, Map<String, dynamic> input) {
    final fieldsData = <String, dynamic>{};
    for (final field in fields) {
      if (input.containsKey(field)) {
        fieldsData[field] = input[field];
      }
    }
    return '$taskName:${fieldsData.toString().hashCode}';
  }
}
