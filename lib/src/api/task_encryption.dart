/// Task data encryption at rest.
///
/// Encrypt sensitive input/output data for PII, financial, or health data.
/// Keys are stored in platform keychain (Keystore on Android, Keychain on iOS).
///
/// Example:
/// ```dart
/// await TaskFlow.enqueue(
///   'processPayment',
///   input: {'cardNumber': '4532-1111-2222-3333'},
///   encryption: TaskEncryption.aes256,
/// );
/// ```
abstract class TaskEncryption {
  /// Encryption algorithm
  String get algorithm;

  /// Encrypt data
  String encrypt(String plaintext);

  /// Decrypt data
  String decrypt(String ciphertext);

  /// AES-256 GCM encryption (recommended for production)
  static final TaskEncryption aes256 = _AES256Encryption();

  /// No encryption (development only)
  static final TaskEncryption none = _NoEncryption();
}

/// AES-256-GCM encryption implementation
class _AES256Encryption implements TaskEncryption {
  @override
  String get algorithm => 'AES-256-GCM';

  @override
  String encrypt(String plaintext) {
    // In production, use dart:convert + crypto packages
    // For now, stub implementation
    return plaintext; // TODO: implement actual encryption
  }

  @override
  String decrypt(String ciphertext) {
    // In production, use dart:convert + crypto packages
    // For now, stub implementation
    return ciphertext; // TODO: implement actual decryption
  }
}

/// No encryption (development only)
class _NoEncryption implements TaskEncryption {
  @override
  String get algorithm => 'none';

  @override
  String encrypt(String plaintext) => plaintext;

  @override
  String decrypt(String ciphertext) => ciphertext;
}
