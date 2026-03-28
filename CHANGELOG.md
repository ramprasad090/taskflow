## 1.1.0

### Complete Feature Set - Production Ready

Major release consolidating all reliability, scheduling, batching, and security features into a single, battle-tested package.

**Reliability & Observability**
* Task middleware/interceptors for logging, auth refresh, analytics
* Soft and hard timeouts with warning callbacks and force termination
* Persistent execution history with duration, status, errors, stack traces
* Global lifecycle hooks: `onTaskStart`, `onTaskComplete`, `onTaskFailed`, `onChainComplete`

**Advanced Scheduling**
* Cron expressions with standard 5-field syntax (`0 9 * * MON`, `0 */6 * * *`, etc.)
* Time window constraints to restrict execution to specific hours/days
* Task deduplication by input hash or specific fields with TTL
* Presets: `hourly`, `daily`, `weeklyMonday`, `monthly`, `offPeak`, `businessHours`

**Batching & Concurrency**
* Batch operations to enqueue 100s of items as one trackable unit
* Concurrency control with strategies (FIFO, LIFO, random, byPriority)
* Rate limiting to throttle executions per time window (e.g., 10/min)
* Priority queues with weighted execution (critical=100x, high=10x, default=1x, low=0.1x)

**Security & Encryption**
* AES-256-GCM encryption at rest for sensitive task data
* Platform keychain integration (Keystore on Android, Keychain on iOS)
* Foreground services with bidirectional UI communication
* Service ↔ UI event channels for real-time data streaming

### New API Types

Added 12 new API classes for advanced feature control:
* `TaskMiddleware` - Interceptor pattern for task execution
* `TaskHistoryEntry` - Execution log model with serialization
* `TaskHooks` - Global lifecycle callbacks
* `TaskTimeout` - Soft/hard timeout configuration with presets
* `CronSchedule` - 5-field cron expression builder
* `TimeWindow` - Hour/day-of-week constraints with presets
* `DedupPolicy` - Deduplication by input or specific fields
* `TaskBatch` - Batch operations with then/catch/finally callbacks
* `ConcurrencyControl` - Concurrency limit and strategy configuration
* `RateLimit` - Rate limiting with time windows and presets
* `TaskQueue` - Weighted priority queue enum (critical, high, default, low)
* `TaskEncryption` - AES-256-GCM encryption configuration

### Enhanced API Methods

Updated `TaskFlow` and `TaskChain` to accept all new parameters:
* `TaskFlow.enqueue()` - Now supports timeout, middleware, dedup, concurrency, rate limit, queue, encryption, time window
* `TaskFlow.schedule()` - Now supports cron expressions and time windows
* `TaskFlow.getHistory()` - New method to retrieve execution history for debugging
* All parameters fully documented with examples

### Comprehensive Example App

Complete demonstration of all v1.0-v2.0 features:
* 7 major feature sections with 20+ example buttons
* Live task monitoring with progress bars and status chips
* Real-time activity log showing all operations
* Shows all execution modes and advanced configurations

### Documentation Updates

* Rewrote README with examples for every feature
* Updated CHANGELOG to document all available capabilities
* Complete ROADMAP showing feature status and future direction
* API reference with parameter documentation

### Bug Fixes

* Fixed TaskTimeout const validation (use runtime validation instead)
* Fixed TimeWindow const assertions (use final presets)
* All 12 new API types fully integrated and tested

---

## 1.0.3

* **NEW: Persistent Service API** — `TaskFlow.startService()` for always-on background services.
* Supports GPS tracking, real-time messaging, WebSocket, and BLE communication.
* Foreground service with notification support (Android) and 15-minute limit (iOS).
* Add task chaining example demonstrating sequential task execution.
* Add periodic scheduling example (15+ minute intervals).
* Enhance example app with task result display and real-time activity logging.
* Show transaction IDs, GPS coordinates, and sync data for each execution mode.
* Demonstrate all five execution patterns: enqueue, chain, schedule, persistent, expedited.
* Fix README branding (TaskFlow → bg_orchestrator).

## 1.0.2

* Fix pubspec.yaml description length (max 180 chars for pub.dev display).
* Update all remaining taskflow references to bg_orchestrator.
* Fix example app and test imports to use correct package name.
* Enhance example app with real-time results display and activity log.
* Add complete Ola/Uber ride-hailing example demonstrating all three execution modes.

## 1.0.1

* Fix test import warnings by updating to use bg_orchestrator package name.
* Add proper MIT license text.

## 1.0.0

* Initial release.
* Unified background task orchestrator for Flutter.
* Android: WorkManager-backed task scheduling with chaining support.
* iOS: BGTaskScheduler-backed task scheduling with simulated chaining.
* Cross-platform: TaskFlow static API, fluent TaskChain builder, sealed TaskResult/TaskStatus.
* Task chaining with sequential and parallel steps.
* Output data passing between chain steps.
* Typed retry policies: exponential, linear, custom.
* Task constraints: network, battery, charging, device idle.
* Priority levels: high (expedited), normal, low.
* Task tagging and tag-based cancellation.
* Real-time progress reporting (0.0–1.0).
* Reactive monitoring via TaskStatus stream.
* One-off and periodic task scheduling.
* Unique task policies: keep, replace.
* Full example app demonstrating all features.
* Comprehensive documentation and pub.dev setup.
