# TaskFlow

[![pub package](https://img.shields.io/pub/v/taskflow.svg)](https://pub.dev/packages/taskflow)
[![Flutter Platform](https://img.shields.io/badge/platform-flutter-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A production-grade, cross-platform background task orchestrator for Flutter. Unifies Android WorkManager and iOS BGTaskScheduler behind a single, elegant Dart API.

**Chain tasks. Retry with backoff. Monitor progress. One API for both platforms.**

## Why TaskFlow?

Flutter developers currently juggle 3-4 fragile packages and can't chain tasks, report progress, or get iOS parity. TaskFlow solves all of this.

| Feature | TaskFlow | workmanager | flutter_background_service |
|---------|----------|-------------|--------------------------|
| Unified API | ✅ | ❌ | ❌ |
| Task Chaining | ✅ | ❌ | ❌ |
| Progress Reporting | ✅ | ❌ | ❌ |
| iOS Parity | ✅ | ⚠️ Limited | ❌ |
| Typed Retry Policies | ✅ | ❌ | ❌ |

## Architecture

TaskFlow uses a **4-layer design** for clean separation of concerns:

### Layer 1: Dart API (Public Interface)

The top layer provides a clean, intuitive static API that developers interact with.

```dart
// Example: All three execution modes
TaskFlow.enqueue('task', input: data);           // One-off deferrable task
TaskFlow.chain('pipeline').then('a').then('b'); // Task chaining
TaskFlow.schedule('sync', interval: Duration(hours: 1)); // Periodic
```

**Components:**
- `TaskFlow` — Static API (20+ methods)
- `TaskChain` — Fluent builder for chaining
- `TaskContext` — Handler execution context
- `TaskResult` — Sealed return type (success/failure/retry)
- `TaskStatus` — Sealed stream events
- `TaskConstraints`, `RetryPolicy` — Type-safe config

### Layer 2: Core Engine (Pure Dart)

Pure Dart business logic with no platform dependencies. Handles retry calculations, chain DAG resolution, and state management.

```dart
// Example: RetryEngine calculates backoff delays
final delay = RetryEngine.computeDelay(
  attempt: 2,
  policy: RetryPolicy.exponential(
    initialDelay: Duration(seconds: 10),
    maxDelay: Duration(minutes: 5),
  ),
); // Returns ~40 seconds (10s * 2^2)

// Example: ChainResolver validates task DAG
ChainResolver.validate([
  {'taskName': 'step1'},
  {'names': ['step2a', 'step2b'], 'parallel': true},
  {'taskName': 'step3'},
], registry); // Throws if any task not registered
```

**Components:**
- `TaskRegistry` — Handler lookup table
- `RetryEngine` — Backoff calculations with jitter
- `ChainResolver` — DAG validation and execution order
- `StateStore` — Abstract KV interface (SharedPreferences on Android, UserDefaults on iOS)
- `ProgressTracker` — Chain progress aggregation

### Layer 3: Platform Bridge (MethodChannel)

Thin abstraction layer using MethodChannel for control and EventChannel for streaming events.

```dart
// Example: Internal—users don't call this directly
final result = await TaskFlowPlatform.instance.enqueue(
  name: 'syncData',
  input: {'userId': '123'},
  constraints: {'network': 'connected'},
  retry: {'type': 'exponential', 'maxAttempts': 5},
);

// Example: Event stream for live updates
TaskFlowPlatform.instance.taskEvents
  .where((event) => event['executionId'] == id)
  .listen((event) {
    final status = TaskStatus.fromMap(event);
    print('Task status: $status');
  });
```

**Components:**
- `TaskFlowPlatform` — Abstract interface
- `MethodChannelTaskFlow` — MethodChannel implementation
- `ConstraintMapper` — Serialization helper
- Channels: `dev.taskflow/channel` (control), `dev.taskflow/events` (stream)

### Layer 4: Native Layer

Platform-specific implementation using native task schedulers.

**Android (Kotlin):**
```kotlin
// Example: WorkManager-backed task execution
class TaskFlowWorker : CoroutineWorker(context, params) {
  override suspend fun doWork(): Result {
    // Invoke Dart handler via headless isolate
    return try {
      Result.success()
    } catch (e: Exception) {
      Result.retry()
    }
  }
}
```

**iOS (Swift):**
```swift
// Example: BGTaskScheduler registration and execution
func application(_ app: UIApplication,
                 didFinishLaunchingWithOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
  BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "dev.taskflow.refresh",
    using: nil
  ) { task in
    // Invoke Dart handler via headless FlutterEngine
    self.headslessRunner.executeTask(task)
  }
  return true
}
```

**Components:**
- Android: WorkManager, CoroutineWorker, ForegroundService
- iOS: BGTaskScheduler, BGAppRefreshTask, HeadlessRunner

---

## Data Flow

```
User Code
    ↓
TaskFlow.enqueue() ← TaskFlow API
    ↓
TaskFlowPlatform.enqueue() ← Platform Bridge
    ↓
Android: WorkManager.enqueue() | iOS: BGTaskScheduler.scheduleTaskWithIdentifier()
    ↓
Background execution
    ↓
Headless isolate invokes Dart handler
    ↓
Handler returns TaskResult
    ↓
Event emitted via EventChannel
    ↓
TaskFlow.monitor() stream receives update
    ↓
UI updates via StreamBuilder
```

---

## Key Design Decisions

- **Static API** — `TaskFlow.enqueue()` not instance-based (simplicity, clarity)
- **Sealed classes** — TaskResult and TaskStatus enable exhaustive pattern matching
- **Fluent builder** — `.then().thenAll().enqueue()` is intuitive
- **Progress 0.0–1.0** — Float scale, consistent across platforms
- **Handlers are top-level** — Required for headless isolates on Android
- **iOS chaining simulated** — UserDefaults persistence (documented as best-effort)
- **15-min Android minimum** — Enforced in Dart, throws ArgumentError
- **Input/Output JSON** — Map<String, dynamic>, fully serializable
- **Zero runtime dependencies** — Only Flutter SDK
- **No web support** — Mobile-only, web has different background APIs

## Visual Architecture

### Basic 4-Layer Stack

```
┌─────────────────────────────────────────────────┐
│   Dart API Layer (Public User Interface)        │
│   TaskFlow.enqueue() • TaskFlow.chain()          │
│   TaskFlow.schedule() • TaskFlow.monitor()       │
│   ✨ Intuitive, typed, sealed classes            │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│   Core Engine (Pure Dart, No Platform Deps)     │
│   TaskRegistry • RetryEngine • ChainResolver     │
│   StateStore • ProgressTracker                   │
│   🔧 Business logic & retry calculations         │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│   Platform Bridge (MethodChannel + EventChannel) │
│   TaskFlowPlatform interface                     │
│   Constraint & Status serialization              │
│   🌉 Dart ↔ Native communication                 │
└──────────────────┬──────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
┌───────▼────────┐   ┌───────▼────────┐
│  Android       │   │  iOS           │
│  (Kotlin)      │   │  (Swift)       │
│                │   │                │
│ WorkManager    │   │ BGTaskScheduler│
│ Expedited Work │   │ BGAppRefresh   │
│ ForegroundSvc  │   │ BGProcessing   │
│ Notifications  │   │ Background     │
│ WakeLock       │   │ Modes (Loc,    │
│                │   │ Audio, VOIP)   │
└────────────────┘   └────────────────┘
```

### Three Execution Modes

TaskFlow supports three distinct execution patterns:

**1. Deferrable Tasks** (Default)
```dart
TaskFlow.enqueue('syncData',
  input: {'userId': '123'},
  constraints: TaskConstraints(network: NetworkConstraint.connected),
  retry: RetryPolicy.exponential(maxAttempts: 5),
);
// ✅ Respects device constraints (network, battery, charging, idle)
// ✅ Automatic retry with exponential backoff
// ✅ Survives app kill
// ⏱️ Execution timing: System decides (respects constraints)
```

**2. Persistent Services** (Always-on, Phase 5+)
```dart
TaskFlow.startService('liveTracking',
  handlers: {
    'updateLocation': (ctx) async {
      // GPS update handler
      return TaskResult.success();
    },
  },
);
// 🎯 Continuous background work
// 📍 GPS tracking, WebSocket, BLE, real-time updates
// 🔔 Foreground notification required (Android)
// ⚠️ Limited to ~15 minutes on iOS
```

**3. Expedited Tasks** (ASAP execution)
```dart
TaskFlow.enqueue('processPayment',
  priority: TaskPriority.high,
  input: payment,
);
// ⚡ Run ASAP, within minutes
// 💰 Payment processing, critical uploads
// 🔔 May require foreground notification (Android 12+)
// ✅ Best-effort on iOS
```

---

## Core Features

### 1. Task Enqueueing

**Basic enqueue:**
```dart
final id = await TaskFlow.enqueue(
  'syncData',
  input: {'userId': '123'},
  retry: RetryPolicy.exponential(maxAttempts: 5),
  constraints: TaskConstraints(network: NetworkConstraint.connected),
);
```

**With all options:**
```dart
final id = await TaskFlow.enqueue(
  'syncData',
  input: {'userId': '123', 'force': true},
  constraints: TaskConstraints(
    network: NetworkConstraint.unmetered,
    batteryNotLow: true,
    requiresCharging: false,
    deviceIdle: false,
  ),
  retry: RetryPolicy.exponential(
    maxAttempts: 5,
    initialDelay: Duration(seconds: 10),
  ),
  priority: TaskPriority.high,  // Expedited on Android
  tags: ['sync', 'critical'],
  initialDelay: Duration(minutes: 5),
  uniqueId: 'user_123_sync',
  uniquePolicy: UniquePolicy.replace,  // Or .keepExisting
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

  final stream = http.get(Uri.parse(url));
  int bytesDownloaded = 0;
  int totalBytes = 1000000;  // Known size

  stream.listen((chunk) {
    bytesDownloaded += chunk.length;
    ctx.reportProgress(bytesDownloaded / totalBytes);
  });

  return TaskResult.success(data: {'path': file.path});
});
```

**With retry capability:**
```dart
TaskFlow.registerHandler('apiCall', (ctx) async {
  try {
    final data = await myApi.fetchData();
    return TaskResult.success(data: {'result': data});
  } catch (e) {
    if (e is TimeoutException) {
      return TaskResult.retryLater();  // System will retry
    }
    return TaskResult.failure(message: e.toString());
  }
});
```

### 3. Task Chaining (Sequential & Parallel)

**Simple chain:**
```dart
await TaskFlow.chain('downloadAndProcess')
  .then('download')
  .then('process')
  .enqueue(input: {'url': 'https://...'});
```

**Parallel steps:**
```dart
await TaskFlow.chain('multiSync')
  .then('fetchUsers')
  .thenAll(['syncContacts', 'syncCalendar', 'syncNotes'])  // 3 in parallel
  .then('cleanup')  // Waits for all parallel to finish
  .enqueue();
```

**Chain with error handling:**
```dart
await TaskFlow.chain('criticalPipeline')
  .then('validateData')
  .then('uploadToServer')
  .then('sendNotification')
  .onFailure('handleFailure')  // Runs if any step fails
  .enqueue(input: {'data': importantData});
```

**Chain with constraints:**
```dart
await TaskFlow.chain('metered')
  .then('step1')
  .then('step2')
  .withConstraints(
    TaskConstraints(network: NetworkConstraint.unmetered),
  )
  .withRetry(RetryPolicy.exponential(maxAttempts: 3))
  .enqueue();
```

### 4. Monitoring Progress

**Monitor by execution ID:**
```dart
TaskFlow.monitorExecution(id).listen((status) {
  switch (status) {
    case TaskQueued():
      print('Task queued, waiting to run');
    case TaskRunning(:final progress):
      print('Running: ${(progress * 100).toStringAsFixed(0)}%');
    case TaskSucceeded(:final output):
      print('Done! Output: $output');
    case TaskFailed(:final message):
      print('Failed: $message');
    case TaskRetrying(:final nextAttempt):
      print('Will retry in ${nextAttempt.inSeconds}s');
    case TaskCancelled():
      print('User cancelled');
  }
});
```

**Monitor by task name:**
```dart
TaskFlow.monitor('syncData').listen((status) {
  if (status is TaskRunning) {
    updateProgressBar(status.progress);
  }
});
```

**With StreamBuilder in UI:**
```dart
StreamBuilder<TaskStatus>(
  stream: TaskFlow.monitorExecution(executionId),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();

    final status = snapshot.data!;
    return switch (status) {
      TaskRunning(:final progress) => LinearProgressIndicator(value: progress),
      TaskSucceeded() => Text('✓ Complete'),
      TaskFailed(:final message) => Text('✗ $message'),
      _ => Text('Status: $status'),
    };
  },
)
```

### 5. Periodic Scheduling

**Schedule recurring task (Android minimum 15 minutes):**
```dart
await TaskFlow.schedule(
  'syncData',
  interval: Duration(hours: 1),
  input: {'userId': '123'},
  constraints: TaskConstraints(network: NetworkConstraint.unmetered),
  retry: RetryPolicy.exponential(maxAttempts: 3),
);
```

**Reschedule with new interval:**
```dart
await TaskFlow.reschedule(
  'syncData',
  interval: Duration(hours: 2),
);
```

**Stop periodic task:**
```dart
await TaskFlow.unschedule('syncData');
```

### 6. Cancellation

**Cancel by name (all executions):**
```dart
await TaskFlow.cancel('syncData');
```

**Cancel specific execution:**
```dart
await TaskFlow.cancelExecution(executionId);
```

**Cancel entire chain:**
```dart
await TaskFlow.cancelChain(chainId);
```

**Cancel by tag:**
```dart
await TaskFlow.cancelByTag('sync');
```

**Cancel everything:**
```dart
await TaskFlow.cancelAll();
```

### 7. Task Query

**Get current status:**
```dart
final status = await TaskFlow.getStatus('syncData');
if (status is TaskRunning) {
  print('Progress: ${status.progress}');
}
```

**Get all tasks:**
```dart
final allTasks = await TaskFlow.getAllTasks();
for (final task in allTasks) {
  print('${task.name}: ${task.status}');
}
```

**Get tasks by tag:**
```dart
final syncTasks = await TaskFlow.getTasksByTag('sync');
print('Active sync tasks: ${syncTasks.length}');
```

## Retry Policies

TaskFlow supports multiple retry strategies with exponential backoff, jitter, and maximum delays to prevent thundering herd.

**Exponential backoff (recommended):**
```dart
RetryPolicy.exponential(
  maxAttempts: 5,                    // Total attempts (1 + 4 retries)
  initialDelay: Duration(seconds: 10),
  maxDelay: Duration(hours: 1),      // Cap on delay
  multiplier: 2.0,                   // Double each time: 10s, 20s, 40s, 80s
  jitter: true,                      // Add randomness to prevent thundering herd
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
  delayForAttempt: (attemptNumber) {
    // attemptNumber: 1, 2, 3, 4 (0-indexed)
    if (attemptNumber == 0) return Duration(seconds: 5);
    if (attemptNumber == 1) return Duration(seconds: 15);
    if (attemptNumber == 2) return Duration(seconds: 60);
    return Duration(minutes: 5);
  },
)
```

**No retry:**
```dart
RetryPolicy.none()
```

## Constraints

Control when tasks execute based on device state.

```dart
TaskConstraints(
  // Network: require connection, prefer unmetered (WiFi), or any
  network: NetworkConstraint.connected,    // .unmetered, .none

  // Battery: don't run if battery critically low
  batteryNotLow: true,

  // Charging: only run when plugged in
  requiresCharging: false,

  // Device idle: only run when not in use
  deviceIdle: false,
)
```

## Installation

```yaml
dependencies:
  taskflow: ^1.0.0
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

### Initialization

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register handlers (can be in main or dispatcher)
  TaskFlow.registerHandler('syncData', (ctx) async {
    // Your handler logic
    return TaskResult.success();
  });

  // Initialize (dispatcher parameter is optional)
  await TaskFlow.initialize();

  runApp(MyApp());
}

// Optional: For complex apps, use a dispatcher for headless execution
@pragma('vm:entry-point')
void taskflowDispatcher() {
  TaskFlow.registerHandler('backgroundTask', (ctx) async {
    // This runs in background isolate
    return TaskResult.success();
  });
}
```

## Complete Example App

Full example at [example/lib/main.dart](example/lib/main.dart):

```dart
import 'package:flutter/material.dart';
import 'package:taskflow/taskflow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register handlers
  TaskFlow.registerHandler('exampleTask', (ctx) async {
    await ctx.reportProgress(0.5);
    await Future.delayed(Duration(seconds: 1));
    return TaskResult.success(data: {'result': 'Done!'});
  });

  await TaskFlow.initialize();
  runApp(const TaskFlowExampleApp());
}

class TaskFlowExampleApp extends StatelessWidget {
  const TaskFlowExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow Example',
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  String? _executionId;
  TaskStatus? _currentStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TaskFlow Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final id = await TaskFlow.enqueue(
                  'exampleTask',
                  retry: RetryPolicy.exponential(maxAttempts: 3),
                );
                setState(() => _executionId = id);
                _monitorTask(id);
              },
              child: const Text('Enqueue Task'),
            ),
            if (_executionId != null) ...[
              const SizedBox(height: 20),
              Text('ID: $_executionId'),
              if (_currentStatus != null)
                Text('Status: ${_statusString(_currentStatus!)}'),
              if (_currentStatus is TaskRunning)
                LinearProgressIndicator(
                  value: (_currentStatus as TaskRunning).progress,
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _monitorTask(String executionId) {
    TaskFlow.monitorExecution(executionId).listen((status) {
      setState(() => _currentStatus = status);
    });
  }

  String _statusString(TaskStatus status) {
    return switch (status) {
      TaskQueued() => 'Queued',
      TaskRunning() => 'Running',
      TaskSucceeded() => 'Succeeded',
      TaskFailed() => 'Failed',
      TaskRetrying() => 'Retrying',
      TaskCancelled() => 'Cancelled',
    };
  }
}
```

## Real-World Examples

### Data Sync with Progress

```dart
TaskFlow.registerHandler('syncUserData', (ctx) async {
  final userId = ctx.input['userId'] as String;

  // Step 1: Fetch user
  await ctx.reportProgress(0.2);
  final user = await api.getUser(userId);

  // Step 2: Sync contacts
  await ctx.reportProgress(0.4);
  await api.syncContacts(user.contacts);

  // Step 3: Sync calendar
  await ctx.reportProgress(0.7);
  await api.syncCalendar(user.calendar);

  // Step 4: Upload photos
  await ctx.reportProgress(0.9);
  await api.uploadPhotos(user.photos);

  return TaskResult.success(data: {
    'synced': true,
    'timestamp': DateTime.now().toIso8601String(),
  });
});

// Enqueue with WiFi-only constraint
await TaskFlow.enqueue(
  'syncUserData',
  input: {'userId': '123'},
  constraints: TaskConstraints(network: NetworkConstraint.unmetered),
  retry: RetryPolicy.exponential(maxAttempts: 3),
);
```

### Chained Processing

```dart
// Define handlers
TaskFlow.registerHandler('downloadFile', (ctx) async {
  final url = ctx.input['url'] as String;
  // ... download logic
  return TaskResult.success(data: {'path': '/tmp/file.zip'});
});

TaskFlow.registerHandler('extractZip', (ctx) async {
  final path = ctx.input['path'] as String;
  // ... extract logic
  return TaskResult.success(data: {'extracted': true});
});

TaskFlow.registerHandler('processFiles', (ctx) async {
  // ... process logic
  return TaskResult.success(data: {'processed': 100});
});

// Chain them
await TaskFlow.chain('processDownload')
  .then('downloadFile')
  .then('extractZip')
  .then('processFiles')
  .enqueue(input: {
    'url': 'https://example.com/archive.zip',
  });
```

### Retry with Backoff

```dart
TaskFlow.registerHandler('apiCall', (ctx) async {
  final maxRetries = 5;
  try {
    final data = await api.fetchWithTimeout();
    return TaskResult.success(data: data);
  } catch (e) {
    if (e is TimeoutException && ctx.attempt < maxRetries) {
      return TaskResult.retryLater();
    }
    return TaskResult.failure(message: e.toString());
  }
});

// Exponential backoff: 10s, 20s, 40s, 80s, 160s
await TaskFlow.enqueue(
  'apiCall',
  retry: RetryPolicy.exponential(
    maxAttempts: 5,
    initialDelay: Duration(seconds: 10),
    maxDelay: Duration(minutes: 5),
  ),
);
```

## Platform Support

- **Android** — WorkManager 2.10.1, minSdk 24
- **iOS** — BGTaskScheduler, iOS 13.0+
- **Web** — Not supported (different background APIs)

## API Reference

| Method | Purpose |
|--------|---------|
| `TaskFlow.initialize()` | Initialize TaskFlow (call once in main) |
| `TaskFlow.registerHandler()` | Register task handler function |
| `TaskFlow.enqueue()` | Enqueue one-off task |
| `TaskFlow.chain()` | Start building task chain |
| `TaskFlow.schedule()` | Schedule recurring task (15min+ on Android) |
| `TaskFlow.reschedule()` | Update interval for periodic task |
| `TaskFlow.unschedule()` | Stop periodic task |
| `TaskFlow.monitor()` | Stream updates for task by name |
| `TaskFlow.monitorExecution()` | Stream updates for specific execution |
| `TaskFlow.cancel()` | Cancel all executions by name |
| `TaskFlow.cancelExecution()` | Cancel specific execution |
| `TaskFlow.cancelChain()` | Cancel entire chain |
| `TaskFlow.cancelByTag()` | Cancel by tag |
| `TaskFlow.cancelAll()` | Cancel all tasks |
| `TaskFlow.getStatus()` | Get current status |
| `TaskFlow.getAllTasks()` | Get all registered tasks |
| `TaskFlow.getTasksByTag()` | Get tasks with tag |

## Limitations & Notes

### Android
- Minimum periodic interval: **15 minutes** (enforced by WorkManager)
- Task inputs/outputs limited to **10 KB** (WorkManager constraint)
- Chaining is native via WorkManager's OneTimeWorkRequest/WorkContinuation

### iOS
- Task chaining is **simulated** using UserDefaults persistence (best-effort)
- System controls actual execution timing for periodic tasks
- Background execution time is limited; tasks may be interrupted

### General
- Task input/output must be JSON-serializable (`Map<String, dynamic>`)
- Handlers must be top-level functions (required for background isolates)
- Dispatcher function must have `@pragma('vm:entry-point')` annotation

## Contributing

Issues and PRs welcome! TaskFlow aims to be the simplest, most reliable background task solution for Flutter.

## License

MIT — See [LICENSE](LICENSE) file