/// Abstract interface for persistent key-value storage.
///
/// Used by iOS chaining to persist chain state across app kills.
/// Android does not use this since WorkManager handles persistence natively.
abstract class StateStore {
  /// Stores a value by key.
  Future<void> put(String key, String value);

  /// Retrieves a value by key, or null if not found.
  Future<String?> get(String key);

  /// Deletes a key.
  Future<void> delete(String key);

  /// Returns all stored key-value pairs.
  Future<Map<String, String>> getAll();
}
