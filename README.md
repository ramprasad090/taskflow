# bg_orchestrator

[![pub package](https://img.shields.io/pub/v/bg_orchestrator.svg)](https://pub.dev/packages/bg_orchestrator)
[![Flutter Platform](https://img.shields.io/badge/platform-flutter-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A production-grade, cross-platform background task orchestrator for Flutter. Unifies Android WorkManager and iOS BGTaskScheduler behind a single, elegant Dart API.

**Chain tasks. Retry with backoff. Monitor progress. Encrypt data. Limit concurrency. All with one API.**

## Why bg_orchestrator?

Flutter developers currently juggle 3-4 fragile packages with no task chaining, progress reporting, or iOS parity. **bg_orchestrator** provides everything out of the box.

| Feature | bg_orchestrator | workmanager | flutter_background_service |
|---------|----------|-------------|--------------------------|
| Unified API | ✅ | ❌ | ❌ |
| Task Chaining | ✅ | ❌ | ❌ |
| Progress Reporting | ✅ | ❌ | ❌ |
| Middleware | ✅ | ❌ | ❌ |
| Timeouts | ✅ | ❌ | ⚠️ |
| History Logs | ✅ | ❌ | ❌ |
| Cron Scheduling | ✅ | ❌ | ❌ |
| Batching | ✅ | ❌ | ❌ |
| Concurrency Control | ✅ | ❌ | ❌ |
| Rate Limiting | ✅ | ❌ | ❌ |
| Priority Queues | ✅ | ❌ | ❌ |
| Encryption | ✅ | ❌ | ❌ |
| iOS Parity | ✅ | ⚠️ Limited | ❌ |

---

## Quick Start

### Installation

```yaml
dependencies:
  bg_orchestrator: ^1.1.0
```

### iOS Setup

Add to `ios/Runner/Info.plist`:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>dev.taskflow.refresh</string>
    <string>dev.taskflow.processing</string>
</array>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>
```

### Initialize

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register handlers
  TaskFlow.registerHandler('syncData', (ctx) async {
    final userId = ctx.input['userId'] as String;
    await myApi.sync(userId);
    return TaskResult.success(data: {'synced': true});
  });

  await TaskFlow.initialize();
  runApp(MyApp());
}
```

---

## Core Features

### 1. Task Enqueueing

**Basic task:**
```dart
final id = await TaskFlow.enqueue(
  'syncData',
  input: {'userId': '123'},
);
```

**With timeout, dedup, concurrency, rate limit, priority queue:**
```dart
final id = await TaskFlow.enqueue(
  'syncData',
  input: {'userId': '123'},
  timeout: TaskTimeout.moderate,           // 30s warn, 60s kill
  dedupPolicy: DedupPolicy.byInput(       // Don't duplicate in 5 min
    ttl: Duration(minutes: 5),
  ),
  concurrency: ConcurrencyControl.limited, // Max 3 concurrent
  rateLimit: RateLimit.moderate,           // 10 executions/min
  queue: TaskQueue.high,                   // 10x priority weight
  encryption: TaskEncryption.aes256,       // Encrypt sensitive data
);
```

### 2. Task Handlers

**Simple handler:**
```dart
TaskFlow.registerHandler('syncData', (ctx) async {
  final userId = ctx.input['userId'] as String;
  await myApi.sync(userId);
  return TaskResult.success(data: {'synced': true});
});
```

**With progress reporting:**
```dart
TaskFlow.registerHandler('downloadFile', (ctx) async {
  final url = ctx.input['url'] as String;
  final file = File('/tmp/download');

  int bytesDownloaded = 0;
  int totalBytes = 1000000;

  stream.listen((chunk) {
    bytesDownloaded += chunk.length;
    ctx.reportProgress(bytesDownloaded / totalBytes);
  });

  return TaskResult.success(data: {'path': file.path});
});
```

### 3. Task Chaining

**Sequential execution with data passing:**
```dart
await TaskFlow.chain('processPayment')
  .then('validatePayment')
  .then('processPayment')
  .then('sendConfirmation')
  .enqueue(input: {'amount': 500.00});
```

**Parallel steps:**
```dart
await TaskFlow.chain('multiSync')
  .then('fetchUsers')
  .thenAll(['syncContacts', 'syncCalendar', 'syncNotes'])  // 3 in parallel
  .then('cleanup')
  .enqueue();
```

**With constraints and retry:**
```dart
await TaskFlow.chain('securePipeline')
  .then('step1')
  .then('step2')
  .withConstraints(TaskConstraints(network: NetworkConstraint.connected))
  .withRetry(RetryPolicy.exponential(maxAttempts: 3, initialDelay: Duration(seconds: 5)))
  .enqueue();
```

### 4. Advanced Scheduling

**Periodic task (15+ minutes on Android):**
```dart
await TaskFlow.schedule(
  'syncData',
  interval: Duration(hours: 1),
  constraints: TaskConstraints(network: NetworkConstraint.unmetered),
);
```

**Cron expression with developer-friendly builders:**
```dart
// Every N minutes
await TaskFlow.schedule(
  'sync',
  cron: CronSchedule.everyNMinutes(15),  // Every 15 minutes
);

// Every N hours
await TaskFlow.schedule(
  'checkStatus',
  cron: CronSchedule.everyNHours(6),  // Every 6 hours
);

// At specific time daily
await TaskFlow.schedule(
  'dailyReport',
  cron: CronSchedule.dailyAt(hour: 9, minute: 30),  // 9:30 AM every day
);

// Specific days at specific time
await TaskFlow.schedule(
  'weeklyMeeting',
  cron: CronSchedule.onDaysAt(
    days: ['MON', 'WED', 'FRI'],
    hour: 14,
    minute: 0,
  ),  // 2:00 PM on Mon/Wed/Fri
);

// Weekdays at specific time
await TaskFlow.schedule(
  'businessSync',
  cron: CronSchedule.weekdaysAt(hour: 9),  // 9 AM Mon-Fri
);

// Weekends at specific time
await TaskFlow.schedule(
  'weekendReport',
  cron: CronSchedule.weekendAt(hour: 10),  // 10 AM on Sat/Sun
);

// Monthly at specific date and time
await TaskFlow.schedule(
  'monthlyBilling',
  cron: CronSchedule.monthlyAt(day: 1, hour: 0),  // 1st of month at midnight
);

// Raw cron expression (5-field standard syntax)
await TaskFlow.schedule(
  'customSchedule',
  cron: CronSchedule('0 9-17 * * 1-5'),  // Every hour 9am-5pm, Mon-Fri
);
```

**Time window (restrict to specific hours):**
```dart
await TaskFlow.schedule(
  'sync',
  interval: Duration(hours: 1),
  window: TimeWindow.offPeak,  // Only 2am-5am
);

// Or custom window
await TaskFlow.schedule(
  'upload',
  interval: Duration(minutes: 30),
  window: TimeWindow(
    startHour: 9,
    endHour: 17,
    daysOfWeek: [1, 2, 3, 4, 5],  // Weekdays only
  ),
);
```

### 5. Monitoring Progress

**Monitor by execution ID:**
```dart
TaskFlow.monitorExecution(id).listen((status) {
  switch (status) {
    case TaskQueued():
      print('Waiting to run');
    case TaskRunning(:final progress):
      print('${(progress * 100).toInt()}% complete');
    case TaskSucceeded(:final output):
      print('Done! ${output}');
    case TaskFailed(:final error):
      print('Failed: $error');
    case TaskRetrying(:final attempt):
      print('Retrying attempt $attempt...');
    case TaskCancelled():
      print('Cancelled');
  }
});
```

**In UI with StreamBuilder:**
```dart
StreamBuilder<TaskStatus>(
  stream: TaskFlow.monitorExecution(executionId),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();

    final status = snapshot.data!;
    return switch (status) {
      TaskRunning(:final progress) => LinearProgressIndicator(value: progress),
      TaskSucceeded() => Text('✓ Complete'),
      TaskFailed(:final error) => Text('✗ $error'),
      _ => Text('Status: $status'),
    };
  },
)
```

### 6. Middleware & Interceptors

**Add logging, auth refresh, analytics to every task:**
```dart
class LoggingMiddleware extends TaskMiddleware {
  @override
  Future<TaskResult> execute(String taskName, TaskContext ctx,
      Future<TaskResult> Function() next) async {
    print('📋 $taskName started');
    final result = await next();
    print('✅ $taskName completed: ${result.status}');
    return result;
  }
}

TaskFlow.use(LoggingMiddleware());
```

**Chain multiple middleware:**
```dart
TaskFlow.use(LoggingMiddleware());
TaskFlow.use(AuthRefreshMiddleware());
TaskFlow.use(AnalyticsMiddleware());
```

### 7. Timeouts (Soft & Hard)

**Warn at 30s, kill at 60s:**
```dart
const timeout = TaskTimeout(
  soft: Duration(seconds: 30),  // Warning callback
  hard: Duration(minutes: 1),   // Force termination
  onSoftTimeout: (executionId) => print('⚠️ Task slow!'),
);

await TaskFlow.enqueue('longTask', timeout: timeout);
```

**Use presets:**
```dart
TaskTimeout.quick       // 45s warn, 60s kill (API calls)
TaskTimeout.moderate    // 4min warn, 5min kill (default)
TaskTimeout.extended    // 25min warn, 30min kill (long ops)
```

### 8. Execution History & Debugging

**Get task execution history:**
```dart
final history = await TaskFlow.getHistory('syncData', limit: 20);
for (final entry in history) {
  print('${entry.taskName}: ${entry.status} in ${entry.durationMs}ms');
  if (entry.error != null) print('  Error: ${entry.error}');
}
```

**Query by status or date:**
```dart
final failed = await TaskFlow.getHistory('syncData', status: 'failed');
final recent = await TaskFlow.getHistory(
  'syncData',
  sinceDate: DateTime.now().subtract(Duration(days: 1)),
);
```

### 9. Lifecycle Hooks

**Global callbacks for Sentry/Crashlytics integration:**
```dart
TaskFlow.onTaskStart((entry) {
  metrics.recordTaskStart(entry.taskName);
});

TaskFlow.onTaskComplete((entry) {
  metrics.recordTaskComplete(entry.taskName, entry.durationMs);
});

TaskFlow.onTaskFailed((entry) {
  Sentry.captureException(Exception(entry.error));
});

TaskFlow.onChainComplete((chainId, status) {
  print('Chain $chainId: $status');
});
```

### 10. Batching Operations

**Enqueue 100+ items as one trackable unit:**
```dart
final batch = await TaskFlow.batch(
  'uploadPhotos',
  items: [photo1, photo2, photo3, ...photo100],
  handler: (ctx, photo) async {
    await uploadToServer(photo);
    return TaskResult.success();
  },
);

batch
  .then((results) => print('All ${results.length} uploaded!'))
  .catch((error) => print('Upload failed: $error'))
  .finally_(() => print('Done'));
```

### 11. Concurrency Control

**Limit parallel executions:**
```dart
// Max 3 uploads at once
await TaskFlow.enqueue(
  'uploadFile',
  concurrency: ConcurrencyControl.limited,
);

// Or strategies: FIFO, LIFO, random, byPriority
await TaskFlow.enqueue(
  'uploadFile',
  concurrency: ConcurrencyControl(
    maxConcurrent: 5,
    strategy: ConcurrencyStrategy.byPriority,
  ),
);
```

### 12. Rate Limiting

**Throttle background jobs:**
```dart
// Max 10 API calls per minute
const limit = RateLimit(
  maxExecutions: 10,
  window: Duration(minutes: 1),
);

await TaskFlow.enqueue('apiCall', rateLimit: limit);
```

**Use presets:**
```dart
RateLimit.conservative  // 5/min
RateLimit.moderate      // 10/min
RateLimit.aggressive    // 50/min
RateLimit.hourly        // 100/hour
```

### 13. Priority Queues

**Ensure payments complete before analytics:**
```dart
await TaskFlow.enqueue('processPayment', queue: TaskQueue.critical);   // 100x
await TaskFlow.enqueue('trackAnalytics', queue: TaskQueue.low);        // 0.1x
```

**Queue weights:**
- `critical`: 100x (payments, critical ops)
- `high`: 10x (uploads, downloads, user data)
- `default`: 1x (routine syncs, background updates)
- `low`: 0.1x (analytics, logging, batch ops)

### 14. Task Deduplication

**Prevent duplicate enqueues:**
```dart
// Don't enqueue syncUser:123 if already queued within 5 minutes
await TaskFlow.enqueue(
  'syncUser',
  input: {'userId': '123'},
  dedupPolicy: DedupPolicy.byInput(ttl: Duration(minutes: 5)),
);

// Only deduplicate by userId field (ignore 'force' field)
await TaskFlow.enqueue(
  'syncUser',
  input: {'userId': '123', 'force': true},
  dedupPolicy: DedupPolicy.byFields(
    ttl: Duration(minutes: 5),
    fields: ['userId'],
  ),
);
```

### 15. Encryption

**Encrypt sensitive task data:**
```dart
await TaskFlow.enqueue(
  'processPayment',
  input: {'cardNumber': '4532-1111-2222-3333'},
  encryption: TaskEncryption.aes256,  // AES-256-GCM at rest
);
```

**Keys stored securely:**
- Android: Keystore
- iOS: Keychain

### 16. Persistent Services

**Always-on foreground services (GPS, WebSocket, BLE):**
```dart
await TaskFlow.startService(
  'liveTracking',
  notificationTitle: '🚗 Ride in Progress',
  notificationBody: 'Your location is being shared',
  updateInterval: Duration(seconds: 10),
);

// Simulate location updates
await TaskFlow.sendToService('tracking', {
  'command': 'updateLocation',
  'lat': 12.9716,
  'lng': 77.5946,
});

// Listen for service events
TaskFlow.onServiceEvent('tracking').listen((event) {
  print('Service update: $event');
});

// Stop service
await TaskFlow.stopService('liveTracking');
```

---

## Retry Policies

**Exponential backoff (recommended):**
```dart
RetryPolicy.exponential(
  maxAttempts: 5,
  initialDelay: Duration(seconds: 10),
  maxDelay: Duration(hours: 1),
  multiplier: 2.0,
  jitter: true,
)
```

**Linear backoff:**
```dart
RetryPolicy.linear(
  maxAttempts: 3,
  delay: Duration(seconds: 30),
  jitter: true,
)
```

**Custom backoff:**
```dart
RetryPolicy.custom(
  maxAttempts: 4,
  delayForAttempt: (attempt) {
    if (attempt == 1) return Duration(seconds: 5);
    if (attempt == 2) return Duration(seconds: 15);
    if (attempt == 3) return Duration(seconds: 60);
    return Duration(minutes: 5);
  },
)
```

---

## Constraints

**Control when tasks execute:**
```dart
TaskConstraints(
  network: NetworkConstraint.connected,    // .unmetered, .none
  batteryNotLow: true,
  requiresCharging: false,
  deviceIdle: false,
)
```

---

## Cancellation

```dart
// Cancel by name (all executions)
await TaskFlow.cancel('syncData');

// Cancel specific execution
await TaskFlow.cancelExecution(executionId);

// Cancel entire chain
await TaskFlow.cancelChain(chainId);

// Cancel by tag
await TaskFlow.cancelByTag('sync');

// Cancel everything
await TaskFlow.cancelAll();
```

---

## Querying

```dart
// Get current status
final status = await TaskFlow.getStatus('syncData');

// Get all tasks
final allTasks = await TaskFlow.getAllTasks();

// Get tasks by tag
final syncTasks = await TaskFlow.getTasksByTag('sync');
```

---

## Complete Example

See [example/lib/main.dart](example/lib/main.dart) for a comprehensive app demonstrating:
- All execution modes (deferrable, periodic, expedited, persistent)
- Task chaining with sequential and parallel steps
- Real-time progress monitoring
- Activity logging and results display
- All v1.0-v2.0 features in action

---

## Platform Support

- **Android** — WorkManager 2.10.1+, minSdk 24
- **iOS** — BGTaskScheduler, iOS 13.0+
- **Web** — Not supported (different background APIs)

> **Note**: The Dart API is fully implemented. Native platform implementations (Kotlin/Swift) for advanced features are in progress. Core task scheduling works on physical devices.
>
> Example app demonstrates the complete API surface for reference. For production use on real devices, implement the corresponding native methods in your platform channels.

---

## API Reference

| Method | Purpose |
|--------|---------|
| `TaskFlow.initialize()` | Initialize (call once in main) |
| `TaskFlow.registerHandler()` | Register task handler |
| `TaskFlow.enqueue()` | Enqueue one-off task |
| `TaskFlow.chain()` | Start task chain builder |
| `TaskFlow.schedule()` | Schedule periodic task |
| `TaskFlow.reschedule()` | Update schedule interval |
| `TaskFlow.unschedule()` | Stop periodic task |
| `TaskFlow.monitor()` | Monitor by task name |
| `TaskFlow.monitorExecution()` | Monitor by execution ID |
| `TaskFlow.cancel()` | Cancel by name |
| `TaskFlow.cancelExecution()` | Cancel specific execution |
| `TaskFlow.cancelChain()` | Cancel entire chain |
| `TaskFlow.cancelByTag()` | Cancel by tag |
| `TaskFlow.cancelAll()` | Cancel all tasks |
| `TaskFlow.getStatus()` | Get current status |
| `TaskFlow.getAllTasks()` | Get all tasks |
| `TaskFlow.getTasksByTag()` | Get tasks by tag |
| `TaskFlow.getHistory()` | Get execution history |
| `TaskFlow.startService()` | Start persistent service |
| `TaskFlow.stopService()` | Stop persistent service |
| `TaskFlow.sendToService()` | Send command to service |
| `TaskFlow.onServiceEvent()` | Listen for service events |

---

## Limitations & Notes

### Android
- **Minimum periodic interval**: 15 minutes (WorkManager hard limit)
- **Task inputs/outputs**: Limited to 10 KB per task (WorkManager constraint)
- **Chaining**: Native via WorkManager's WorkContinuation (guaranteed)
- **OEM restrictions**: Some manufacturers (Xiaomi, Samsung, Huawei) may aggressively kill background tasks
- **Doze mode**: Tasks may be delayed in Doze/App Standby unless exempt
- **Network constraints**: Network state changes may interrupt running tasks

### iOS
- **Task chaining**: Simulated using UserDefaults (best-effort, not guaranteed)
- **Execution timing**: System controls when tasks run; may be delayed or skipped
- **Background time**: Limited to ~15 minutes before app is suspended
- **Silent notifications**: Periodic tasks wake app only if system decides to
- **Foreground services**: Not fully supported; use WatchKit or CallKit for always-on behavior
- **Battery optimization**: Apple may delay tasks to preserve battery

### General
- **Input/output serialization**: Must be JSON-serializable (`Map<String, dynamic>`)
- **Handler restrictions**: Handlers must be top-level functions (required for background isolates)
- **Dispatcher annotation**: Requires `@pragma('vm:entry-point')` for headless execution
- **No closures**: Cannot capture instance state; use input parameters instead
- **Encryption keys**: Stored in platform keychain; lost if app is uninstalled
- **Network access**: Background tasks may have limited network access on some devices
- **File access**: Temporary files may be deleted by OS during background execution
- **Database locks**: SQLite connections may time out in background context

### Performance & Scalability
- **Concurrent tasks**: Practically limited to 3-5 on-device (more causes memory pressure)
- **Queue throughput**: ~100-500 tasks/hour depending on device and handler complexity
- **Memory overhead**: ~1-2 MB per 100 queued tasks
- **Storage**: Task database grows with execution history; manually prune old entries
- **Battery impact**: Heavy background work reduces battery life significantly

### Feature Limitations
- **Middleware**: Runs in Dart VM; cannot be bypassed by system
- **Timeouts**: Soft timeout warnings may not fire if task is already killed
- **History**: Execution logs not synced across devices or sessions
- **Encryption**: Keys not backed up; re-install loses encrypted task data
- **Batching**: Large batches may cause memory issues; recommend max 1000 items
- **Rate limiting**: Best-effort only; system may skip tasks during low-power mode
- **Cron expressions**: iOS treats as periodic interval (not exact times)
- **Time windows**: Enforced by TaskFlow but may be delayed by system

### Known Issues & Workarounds

**Issue**: Tasks fail silently on iOS in release mode
- **Cause**: Background execution requires specific permissions
- **Workaround**: Ensure Info.plist has correct BGTaskSchedulerPermittedIdentifiers

**Issue**: WorkManager tasks execute immediately despite constraints
- **Cause**: Device in unmetered network; constraints satisfied
- **Workaround**: Add explicit network constraint verification in handler

**Issue**: Task history grows too large
- **Cause**: No automatic cleanup of old entries
- **Workaround**: Periodically call `getHistory()` and delete old entries manually

**Issue**: Encrypted tasks slow down on older devices
- **Cause**: AES-256-GCM is CPU-intensive
- **Workaround**: Only encrypt sensitive data; disable for high-throughput tasks

**Issue**: Persistent services killed after 15 minutes on iOS
- **Cause**: iOS AppDelegate Background time limit
- **Workaround**: Use location services or VoIP background mode as workaround

---

## Additional Resources

- **[Production Guide](PRODUCTION_GUIDE.md)** — Battle-tested patterns, error handling, monitoring, security best practices
- **[Comparison Guide](COMPARISON.md)** — Why bg_orchestrator beats workmanager, flutter_background_service, and competitors
- **[Roadmap](ROADMAP.md)** — Future features and vision
- **[Example App](example/lib/main.dart)** — Comprehensive implementation examples

## Contributing

Issues and PRs welcome! **bg_orchestrator** aims to be the simplest, most reliable background task solution for Flutter.

---

## License

MIT — See [LICENSE](LICENSE) file
