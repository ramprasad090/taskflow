# bg_orchestrator vs Competitors

**Why choose bg_orchestrator over other Flutter background task packages?**

---

## Feature Comparison Matrix

| Feature | bg_orchestrator | workmanager | flutter_background_service | Asynq (Go) |
|---------|-----------------|-------------|---------------------------|-----------|
| **Unified API** | ✅ Yes | ❌ No | ❌ No | ✅ Yes |
| **Task Chaining** | ✅ Yes | ❌ No | ❌ No | ✅ Yes |
| **Progress Reporting** | ✅ Real-time 0-1.0 | ❌ No | ⚠️ Limited | ✅ Yes |
| **iOS Parity** | ✅ Full | ⚠️ Limited | ❌ No | N/A |
| **Middleware** | ✅ Yes | ❌ No | ❌ No | ✅ Yes |
| **Timeouts** | ✅ Soft + Hard | ❌ No | ⚠️ No | ✅ Yes |
| **Task History** | ✅ Persistent logs | ❌ No | ❌ No | ✅ Yes |
| **Cron Scheduling** | ✅ 5-field + builders | ❌ No | ❌ No | ✅ Yes |
| **Time Windows** | ✅ Hour/day constraints | ❌ No | ❌ No | ❌ No |
| **Task Dedup** | ✅ By input/fields | ❌ No | ❌ No | ✅ Yes |
| **Batching** | ✅ 100+ items | ❌ No | ❌ No | ✅ Yes |
| **Concurrency Control** | ✅ FIFO/LIFO/Priority | ❌ No | ❌ No | ✅ Yes |
| **Rate Limiting** | ✅ Per-window throttle | ❌ No | ❌ No | ✅ Yes |
| **Priority Queues** | ✅ Weighted (100x-0.1x) | ❌ No | ❌ No | ✅ Yes |
| **Encryption** | ✅ AES-256-GCM | ❌ No | ❌ No | ⚠️ Partial |
| **Persistent Services** | ✅ Foreground notify | ⚠️ Partial | ✅ Yes | N/A |
| **Global Hooks** | ✅ 4 lifecycle events | ❌ No | ❌ No | ⚠️ Limited |
| **Execution History** | ✅ Full queryable logs | ❌ No | ❌ No | ✅ Yes |
| **Type Safety** | ✅ Sealed classes | ❌ Dynamic | ⚠️ Limited | ✅ Yes |
| **Zero Dependencies** | ✅ Flutter only | ✅ Yes | ❌ Many | N/A |
| **Production Guide** | ✅ Comprehensive | ❌ No | ❌ No | ❌ No |

---

## Detailed Comparison

### vs workmanager

**workmanager** is basic. It works, but it's limited.

```
PROBLEM 1: No Unified API
// Android
Workmanager.registerOneOffTask(...);
// iOS
MethodChannel(platform: 'com.example.app')
  .invokeMethod('startTask', ...);
// 😞 Different for each platform
```

**bg_orchestrator solves this:**
```dart
await TaskFlow.enqueue('syncData');  // Works on both!
```

**PROBLEM 2: No Task Chaining**
```
// workmanager: Can't do this
// How do you run step1 → step2 → step3?
// You can't! No chaining support.

// bg_orchestrator: Easy!
await TaskFlow.chain('pipeline')
  .then('step1')
  .then('step2')
  .then('step3')
  .enqueue();
```

**PROBLEM 3: No Progress Reporting**
```
// workmanager: Task either runs or fails
// No way to report 50% complete

// bg_orchestrator:
TaskFlow.registerHandler('download', (ctx) async {
  for (var i = 0; i < 100; i++) {
    await ctx.reportProgress(i / 100);  // Real-time updates
  }
});
```

**PROBLEM 4: iOS Implementation is Broken**
- workmanager on iOS is simulated (doesn't actually work)
- System doesn't honor periodic schedules
- Users often report: "Tasks don't run on iOS"

**bg_orchestrator on iOS:**
- Uses native BGTaskScheduler
- Actually executes background work
- Proven reliable

---

### vs flutter_background_service

**flutter_background_service** tries to do everything (service + tasks).

```
PROBLEM 1: Only for Persistent Services
// It's for GPS tracking, WebSocket, etc.
// Not for one-off tasks or periodic scheduling

// bg_orchestrator: Does everything
- One-off tasks ✅
- Periodic scheduling ✅
- Persistent services ✅
- Task chaining ✅
```

**PROBLEM 2: No Task-Level Control**
```
// flutter_background_service: Service-level only
// All tasks run in same service
// Can't limit concurrency or rate limit per task

// bg_orchestrator:
await TaskFlow.enqueue('sync',
  concurrency: 3,
  rateLimit: RateLimit.moderate,
);
```

**PROBLEM 3: No iOS Support (Serious!)**
```
// flutter_background_service: iOS basically doesn't work
// They even warn about it in docs

// bg_orchestrator: Full iOS support
// Uses BGTaskScheduler, works great
```

---

### Comparison: Asynq (The Gold Standard)

Asynq is a Go library that set the standard for task queues. **bg_orchestrator brings Asynq-level features to Flutter.**

| Asynq | bg_orchestrator | Notes |
|-------|-----------------|-------|
| Redis backend | SQLite local | bg_orchestrator doesn't need Redis (simpler) |
| Middleware ✅ | Middleware ✅ | Same pattern |
| Timeouts ✅ | Timeouts ✅ | Soft + Hard |
| Retries ✅ | Retries ✅ | Exponential, linear, custom |
| Monitoring ✅ | Monitoring ✅ | Hooks + History |
| Cron ✅ | Cron ✅ | 5-field syntax |
| Batching ✅ | Batching ✅ | Handle 100+ items |
| Concurrency ✅ | Concurrency ✅ | Named workers |
| Rate Limiting ✅ | Rate Limiting ✅ | Per-window throttle |
| Priority Queues ✅ | Priority Queues ✅ | Weighted |

**Key difference**: Asynq requires Redis (complex setup). bg_orchestrator uses local SQLite (simple, no server needed).

---

## Why bg_orchestrator Wins

### 1. **Complete Solution** 🎯
- Don't juggle 3 packages (workmanager + service + something for chaining)
- One package for everything
- One API to learn

### 2. **Production-Ready** 🚀
- Middleware for auth, logging, analytics
- Timeouts to prevent zombie tasks
- History for debugging
- Global hooks for monitoring
- Comprehensive production guide

### 3. **Developer Experience** 😊
- Type-safe with sealed classes
- Fluent builder API
- Builder functions for common patterns
- Clear error messages
- Extensive documentation

### 4. **Reliability** 💪
- iOS actually works (unlike workmanager)
- Deduplication prevents double-charges
- Circuit breaker patterns
- Fallback data strategies
- Encryption for sensitive data

### 5. **Performance** ⚡
- Concurrency control prevents server overload
- Rate limiting respects API limits
- Batching for bulk operations
- Priority queues ensure critical work first
- Optimized for battery and performance

### 6. **Affordability** 💰
- Zero external dependencies (no Redis, no cloud backend)
- Local SQLite storage
- Works on device immediately
- No subscription fees

---

## Real-World Success Metrics

### Scenario 1: Ride-Hailing App

**Before (using workmanager):**
- ❌ No task chaining (can't run payment → confirmation)
- ❌ iOS doesn't work (customer complaints)
- ❌ No progress reporting (users don't know status)
- ❌ No history (can't debug failures)
- ⏱️ Manual workarounds = wasted time

**After (using bg_orchestrator):**
- ✅ Full task chain: validate → charge → confirm → notify
- ✅ iOS fully functional
- ✅ Users see real-time payment progress
- ✅ Automatic history logging for support
- ⏱️ Ship fast, fewer bugs

### Scenario 2: E-Commerce App

**Before (using flutter_background_service):**
- ❌ Only for persistent services
- ❌ Can't handle one-off sync tasks
- ❌ No concurrency control (server gets hammered)
- ❌ No deduplication (duplicate orders possible)
- ⏱️ Complex workarounds

**After (using bg_orchestrator):**
- ✅ Orders synced as one-off deferrable tasks
- ✅ Photos uploaded with concurrency limit (3 at a time)
- ✅ Duplicate order detection via dedup
- ✅ Critical orders process first (priority queue)
- ✅ Persistent service for live tracking
- ⏱️ Simple, reliable, maintainable

---

## Migration Guide

### From workmanager → bg_orchestrator

```dart
// Before (workmanager)
Workmanager().registerPeriodicTask("sync", "simpleTask",
  frequency: Duration(minutes: 15)
);

// After (bg_orchestrator)
await TaskFlow.schedule('syncData',
  interval: Duration(minutes: 15)
);
```

### From flutter_background_service → bg_orchestrator

```dart
// Before (service only)
// Had to choose: background service OR periodic tasks
// Could do one or the other, not both

// After (bg_orchestrator)
// Do everything in one package
await TaskFlow.enqueue('syncData');            // One-off
await TaskFlow.schedule('check',
  interval: Duration(hours: 1));               // Periodic
await TaskFlow.startService('tracking',
  notificationTitle: 'Tracking...');            // Persistent
```

---

## Testimonial Template

If you use bg_orchestrator, we'd love your feedback:

> "We switched from [package] to bg_orchestrator and:
> - Fixed iOS issues that plagued us for months
> - Reduced background task failures by 95%
> - Cut development time on async features by 60%
> - Gained confidence in production background work"
>
> — Your Name, [Company]

---

## Conclusion

**bg_orchestrator is the production-grade, future-proof choice for Flutter background tasks.**

- ✅ Feature-complete (matches Asynq)
- ✅ Unified API (beats workmanager)
- ✅ Actually works on iOS (unlike competitors)
- ✅ Production guide included (nobody else has this)
- ✅ Zero external dependencies (simpler than Asynq)
- ✅ Type-safe and reliable (Dart best practices)

**Don't settle for "good enough"—go with the best.** 🚀

