/// Base exception for all taskflow errors.
class TaskFlowException implements Exception {
  /// The error message.
  final String message;

  /// Optional error code for platform-specific exceptions.
  final String? code;

  TaskFlowException({
    required this.message,
    this.code,
  });

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

/// Thrown when any TaskFlow API is called before [TaskFlow.initialize].
class TaskFlowNotInitializedException extends TaskFlowException {
  TaskFlowNotInitializedException()
      : super(
          message:
              'TaskFlow.initialize() must be called before using any TaskFlow API',
          code: 'NOT_INITIALIZED',
        );
}

/// Thrown when [TaskFlow.enqueue] references a handler that was not registered.
class TaskHandlerNotFoundException extends TaskFlowException {
  /// The name of the handler that was not found.
  final String handlerName;

  TaskHandlerNotFoundException(this.handlerName)
      : super(
          message: 'Task handler "$handlerName" was not registered',
          code: 'HANDLER_NOT_FOUND',
        );
}

/// Thrown when input/output data exceeds platform limits.
class TaskFlowDataSizeException extends TaskFlowException {
  /// The actual size in bytes.
  final int actualBytes;

  /// The maximum allowed size in bytes.
  final int maxBytes;

  TaskFlowDataSizeException({
    required this.actualBytes,
    required this.maxBytes,
  }) : super(
    message:
        'Task input/output data exceeds maximum size: $actualBytes bytes > $maxBytes bytes',
    code: 'DATA_SIZE_EXCEEDED',
  );
}

/// Thrown when a task chain definition has circular dependencies.
class TaskFlowChainCycleException extends TaskFlowException {
  TaskFlowChainCycleException()
      : super(
          message: 'Task chain contains a circular dependency',
          code: 'CHAIN_CYCLE',
        );
}
