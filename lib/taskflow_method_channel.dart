import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/platform/task_flow_platform.dart';

/// An implementation of [TaskFlowPlatform] that uses method channels.
class MethodChannelTaskFlow extends TaskFlowPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  static const methodChannel = MethodChannel('dev.taskflow/channel');

  /// The event channel for receiving task status updates.
  @visibleForTesting
  static const eventChannel = EventChannel('dev.taskflow/events');

  late final Stream<Map<String, dynamic>> _events =
      eventChannel.receiveBroadcastStream().map((dynamic event) {
    if (event is Map) {
      return Map<String, dynamic>.from(
        event.cast<String, dynamic>(),
      );
    }
    return <String, dynamic>{};
  }).asBroadcastStream();

  @override
  Stream<Map<String, dynamic>> get taskEvents => _events;

  @override
  Future<void> initialize() async {
    await methodChannel.invokeMethod('initialize');
  }

  @override
  Future<String> enqueue({
    required String name,
    required Map<String, dynamic> input,
    Map<String, dynamic>? constraints,
    Map<String, dynamic>? retry,
    required String priority,
    required List<String> tags,
    int? initialDelayMs,
    String? uniqueId,
    String? uniquePolicy,
  }) async {
    final result = await methodChannel.invokeMethod<String>('enqueue', {
      'name': name,
      'input': input,
      'constraints': constraints,
      'retry': retry,
      'priority': priority,
      'tags': tags,
      'initialDelayMs': initialDelayMs,
      'uniqueId': uniqueId,
      'uniquePolicy': uniquePolicy,
    });
    return result ?? '';
  }

  @override
  Future<String> enqueueChain({
    required List<Map<String, dynamic>> steps,
    required Map<String, dynamic> input,
    Map<String, dynamic>? constraints,
  }) async {
    final result = await methodChannel.invokeMethod<String>('enqueueChain', {
      'steps': steps,
      'input': input,
      'constraints': constraints,
    });
    return result ?? '';
  }

  @override
  Future<void> schedule({
    required String name,
    required int intervalMs,
    required Map<String, dynamic> input,
    Map<String, dynamic>? constraints,
    Map<String, dynamic>? retry,
    required String priority,
  }) async {
    await methodChannel.invokeMethod('schedule', {
      'name': name,
      'intervalMs': intervalMs,
      'input': input,
      'constraints': constraints,
      'retry': retry,
      'priority': priority,
    });
  }

  @override
  Future<void> reschedule({
    required String name,
    required int intervalMs,
  }) async {
    await methodChannel.invokeMethod('reschedule', {
      'name': name,
      'intervalMs': intervalMs,
    });
  }

  @override
  Future<void> unschedule(String name) async {
    await methodChannel.invokeMethod('unschedule', {'name': name});
  }

  @override
  Future<void> cancel(String name) async {
    await methodChannel.invokeMethod('cancel', {'name': name});
  }

  @override
  Future<void> cancelExecution(String executionId) async {
    await methodChannel
        .invokeMethod('cancelExecution', {'executionId': executionId});
  }

  @override
  Future<void> cancelChain(String chainId) async {
    await methodChannel.invokeMethod('cancelChain', {'chainId': chainId});
  }

  @override
  Future<void> cancelByTag(String tag) async {
    await methodChannel.invokeMethod('cancelByTag', {'tag': tag});
  }

  @override
  Future<void> cancelAll() async {
    await methodChannel.invokeMethod('cancelAll');
  }

  @override
  Future<Map<String, dynamic>?> getStatus(String name) async {
    final result =
        await methodChannel.invokeMethod<Map>('getStatus', {'name': name});
    return result != null ? Map<String, dynamic>.from(result) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final result = await methodChannel.invokeMethod<List>('getAllTasks');
    return result
            ?.cast<Map<dynamic, dynamic>>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList() ??
        [];
  }

  @override
  Future<List<Map<String, dynamic>>> getTasksByTag(String tag) async {
    final result = await methodChannel
        .invokeMethod<List>('getTasksByTag', {'tag': tag});
    return result
            ?.cast<Map<dynamic, dynamic>>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList() ??
        [];
  }

  @override
  Future<void> reportProgress({
    required String executionId,
    required double progress,
  }) async {
    await methodChannel.invokeMethod('reportProgress', {
      'executionId': executionId,
      'progress': progress,
    });
  }
}
