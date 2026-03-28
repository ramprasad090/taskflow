# bg_orchestrator: Production Guide

**Make your app bulletproof with battle-tested patterns and reliability strategies.**

---

## Table of Contents

1. [Error Handling Strategies](#error-handling-strategies)
2. [Retry Patterns](#retry-patterns)
3. [Monitoring & Alerting](#monitoring--alerting)
4. [Performance Optimization](#performance-optimization)
5. [Security Best Practices](#security-best-practices)
6. [Troubleshooting](#troubleshooting)
7. [Real-World Examples](#real-world-examples)

---

## Error Handling Strategies

### 1. Graceful Degradation

**Always handle failures without crashing:**

```dart
TaskFlow.registerHandler('syncData', (ctx) async {
  try {
    final userId = ctx.input['userId'] as String;
    final data = await api.fetchData(userId);

    return TaskResult.success(data: {'synced': true, 'count': data.length});
  } on TimeoutException catch (e) {
    // Network timeout - retry later
    return TaskResult.retryLater();
  } on UnauthorizedException catch (e) {
    // Auth failed - don't retry, log for manual investigation
    return TaskResult.failure(
      message: 'Auth failed: ${e.message}',
      canRetry: false,
    );
  } on Exception catch (e) {
    // Unknown error - retry with backoff
    return TaskResult.retryLater();
  }
});
```

### 2. Circuit Breaker Pattern

**Stop hammering failing APIs:**

```dart
class CircuitBreaker {
  int failureCount = 0;
  bool isOpen = false;
  DateTime lastFailureTime = DateTime.now();
  static const maxFailures = 5;
  static const resetWindowMs = 60000; // 1 minute

  bool canAttempt() {
    if (!isOpen) return true;

    final elapsed = DateTime.now().difference(lastFailureTime).inMilliseconds;
    if (elapsed > resetWindowMs) {
      // Try again after window
      isOpen = false;
      failureCount = 0;
      return true;
    }
    return false;
  }

  void recordFailure() {
    failureCount++;
    lastFailureTime = DateTime.now();
    if (failureCount >= maxFailures) {
      isOpen = true;
    }
  }

  void recordSuccess() {
    failureCount = 0;
    isOpen = false;
  }
}

final breaker = CircuitBreaker();

TaskFlow.registerHandler('apiCall', (ctx) async {
  if (!breaker.canAttempt()) {
    return TaskResult.failure(
      message: 'Circuit breaker open - service unavailable',
      canRetry: false,
    );
  }

  try {
    final result = await api.call();
    breaker.recordSuccess();
    return TaskResult.success(data: result);
  } catch (e) {
    breaker.recordFailure();
    return TaskResult.retryLater();
  }
});
```

### 3. Fallback Data

**Use cached/fallback data when API fails:**

```dart
TaskFlow.registerHandler('syncUserProfile', (ctx) async {
  try {
    final userId = ctx.input['userId'] as String;
    final profile = await api.getProfile(userId);

    // Cache for fallback
    await cache.set('profile_$userId', profile);

    return TaskResult.success(data: {'synced': true, 'profile': profile});
  } catch (e) {
    // Try fallback from cache
    final cached = await cache.get('profile_${ctx.input['userId']}');
    if (cached != null) {
      return TaskResult.success(
        data: {'synced': false, 'cached': true, 'profile': cached},
      );
    }
    return TaskResult.retryLater();
  }
});
```

---

## Retry Patterns

### 1. Exponential Backoff (Recommended)

**Intelligent retry with increasing delays:**

```dart
// Start at 5s, double each time, max 10 minutes, ±15% jitter
await TaskFlow.enqueue(
  'apiCall',
  retry: RetryPolicy.exponential(
    maxAttempts: 5,
    initialDelay: Duration(seconds: 5),
    maxDelay: Duration(minutes: 10),
    multiplier: 2.0,
    jitter: true,
  ),
);

// Retry schedule: 5s → 10s → 20s → 40s → 80s (±jitter)
```

### 2. Linear Backoff (Constant Spacing)

**Fixed delays between retries:**

```dart
// Retry every 30 seconds, 3 times
await TaskFlow.enqueue(
  'syncData',
  retry: RetryPolicy.linear(
    maxAttempts: 3,
    delay: Duration(seconds: 30),
    jitter: true,  // Add randomness to avoid thundering herd
  ),
);
```

### 3. Custom Backoff (Maximum Control)

**For complex scenarios:**

```dart
await TaskFlow.enqueue(
  'payment',
  retry: RetryPolicy.custom(
    maxAttempts: 4,
    delayForAttempt: (attempt) {
      // Attempt 1: 5s
      if (attempt == 1) return Duration(seconds: 5);
      // Attempt 2: 30s
      if (attempt == 2) return Duration(seconds: 30);
      // Attempt 3: 2 minutes
      if (attempt == 3) return Duration(minutes: 2);
      // Attempt 4: 10 minutes (last resort)
      return Duration(minutes: 10);
    },
  ),
);
```

### 4. No Retry (For Idempotent Operations)

**When retrying would cause duplicates:**

```dart
// Sending notification - don't retry, user already saw it
await TaskFlow.enqueue(
  'sendNotification',
  retry: RetryPolicy.none(),  // No retry
);
```

---

## Monitoring & Alerting

### 1. Lifecycle Hooks for Observability

**Track everything happening in your background tasks:**

```dart
// Log task start
TaskFlow.onTaskStart((entry) {
  analytics.logEvent('task_started', {
    'taskName': entry.taskName,
    'executionId': entry.executionId,
    'timestamp': DateTime.now().toString(),
  });
});

// Log task completion with metrics
TaskFlow.onTaskComplete((entry) {
  metrics.recordTask(
    name: entry.taskName,
    durationMs: entry.durationMs,
    status: entry.status,
    success: entry.status == 'succeeded',
  );

  logger.info('Task completed: ${entry.taskName} in ${entry.durationMs}ms');
});

// Alert on failure
TaskFlow.onTaskFailed((entry) {
  // Send to error tracking
  errorTracking.captureException(
    Exception('Task failed: ${entry.taskName}'),
    context: {
      'executionId': entry.executionId,
      'error': entry.error,
      'stackTrace': entry.stackTrace,
      'attempt': entry.attempt,
    },
  );

  // Send alert if critical
  if (entry.taskName == 'processPayment' || entry.taskName == 'syncCriticalData') {
    alerting.sendAlert(
      channel: 'critical',
      message: 'Critical task failed: ${entry.taskName}',
      details: entry,
    );
  }
});

// Log chain completion
TaskFlow.onChainComplete((chainId, status) {
  metrics.recordChain(chainId, status);
  logger.info('Chain $chainId completed: $status');
});
```

### 2. Task History for Debugging

**Investigate failures:**

```dart
// Get recent failures
final failures = await TaskFlow.getHistory(
  'syncData',
  status: 'failed',
  limit: 50,
);

for (final failure in failures) {
  print('Failed at: ${failure.completedAt}');
  print('Error: ${failure.error}');
  print('Stack trace: ${failure.stackTrace}');
  print('Duration: ${failure.durationMs}ms');
}

// Get slow tasks
final slow = (await TaskFlow.getHistory('uploadFile', limit: 100))
  .where((e) => e.durationMs > 30000)
  .toList();

print('Found ${slow.length} slow uploads');
```

### 3. Real-Time Monitoring

**Dashboard for task status:**

```dart
// Monitor all payment tasks
TaskFlow.monitor('processPayment').listen((status) {
  switch (status) {
    case TaskRunning():
      ui.showProgress(status.progress);
    case TaskSucceeded():
      ui.showSuccess('Payment processed');
      analytics.logPurchase();
    case TaskFailed():
      ui.showError('Payment failed: ${status.error}');
      alerting.notifySupport('Payment failure: ${status.error}');
  }
});
```

---

## Performance Optimization

### 1. Concurrency Control

**Prevent overwhelming your server:**

```dart
// Limit uploads to 3 concurrent
await TaskFlow.enqueue(
  'uploadFile',
  concurrency: ConcurrencyControl.limited,  // Max 3
);

// Custom: max 5 concurrent, process highest priority first
await TaskFlow.enqueue(
  'processData',
  concurrency: ConcurrencyControl(
    maxConcurrent: 5,
    strategy: ConcurrencyStrategy.byPriority,
  ),
);
```

### 2. Rate Limiting

**Respect API rate limits:**

```dart
// 10 API calls per minute
await TaskFlow.enqueue(
  'apiCall',
  rateLimit: RateLimit(
    maxExecutions: 10,
    window: Duration(minutes: 1),
  ),
);

// 100 operations per hour
await TaskFlow.enqueue(
  'bulkOp',
  rateLimit: RateLimit.hourly,
);
```

### 3. Priority Queues

**Ensure critical tasks complete first:**

```dart
// Payment = critical, analytics = low priority
await TaskFlow.enqueue(
  'processPayment',
  queue: TaskQueue.critical,  // 100x weight
);

await TaskFlow.enqueue(
  'trackAnalytics',
  queue: TaskQueue.low,       // 0.1x weight
);

// Result: Payment tasks execute 1000x more often than analytics
```

### 4. Batch Operations

**Handle bulk work efficiently:**

```dart
final batch = await TaskFlow.batch(
  'uploadPhotos',
  items: photos,
  handler: (ctx, photo) async {
    await cloudStorage.upload(photo);
    return TaskResult.success();
  },
);

batch
  .then((results) => ui.showSuccess('${results.length} uploaded'))
  .catch((error) => ui.showError('Upload failed: $error'))
  .finally_(() => ui.hideProgress());
```

---

## Security Best Practices

### 1. Encrypt Sensitive Data

**Protect PII, financial data, health information:**

```dart
// Encrypt payment card data
await TaskFlow.enqueue(
  'processPayment',
  input: {
    'cardNumber': '4532-****-****-1234',  // PII
    'cvv': '***',
    'amount': 99.99,
  },
  encryption: TaskEncryption.aes256,  // AES-256-GCM
);

// Keys stored in platform keychain
// Android: Keystore (hardware-backed if available)
// iOS: Keychain with secure enclave
```

### 2. Input Validation

**Never trust user input:**

```dart
TaskFlow.registerHandler('updateProfile', (ctx) async {
  final userId = ctx.input['userId'] as String?;
  final name = ctx.input['name'] as String?;

  // Validate inputs
  if (userId == null || userId.isEmpty) {
    return TaskResult.failure(message: 'Invalid userId');
  }

  if (name == null || name.length > 100) {
    return TaskResult.failure(message: 'Invalid name');
  }

  // Only proceed with validated data
  await api.updateProfile(userId, name);
  return TaskResult.success();
});
```

### 3. Authentication & Authorization

**Verify access before background work:**

```dart
TaskFlow.registerHandler('syncUserData', (ctx) async {
  final userId = ctx.input['userId'] as String;
  final token = await auth.getValidToken();

  if (token == null) {
    // Token expired - can't proceed
    return TaskResult.failure(message: 'Auth expired');
  }

  try {
    final data = await api.syncWithAuth(userId, token);
    return TaskResult.success(data: data);
  } on UnauthorizedException {
    // Token revoked - don't retry
    return TaskResult.failure(
      message: 'Unauthorized',
      canRetry: false,
    );
  }
});
```

### 4. Deduplication to Prevent Double-Charges

**Critical for payments:**

```dart
// Prevent duplicate payment processing
await TaskFlow.enqueue(
  'processPayment',
  input: {'orderId': '12345', 'amount': 99.99},
  dedupPolicy: DedupPolicy.byInput(
    ttl: Duration(hours: 24),  // Don't re-process same order within 24h
  ),
);
```

---

## Troubleshooting

### Issue: Tasks Not Running

**Checklist:**

1. **Is TaskFlow initialized?**
   ```dart
   await TaskFlow.initialize();
   ```

2. **Is handler registered before initialize?**
   ```dart
   TaskFlow.registerHandler('myTask', (ctx) async { ... });
   await TaskFlow.initialize();
   ```

3. **Android: Minimum 15 minutes?**
   ```dart
   // ❌ Wrong - less than 15 minutes
   await TaskFlow.schedule('sync', interval: Duration(minutes: 5));

   // ✅ Correct
   await TaskFlow.schedule('sync', interval: Duration(minutes: 30));
   ```

4. **iOS: Info.plist configured?**
   ```xml
   <key>BGTaskSchedulerPermittedIdentifiers</key>
   <array>
       <string>dev.taskflow.refresh</string>
       <string>dev.taskflow.processing</string>
   </array>
   ```

5. **Android: App killed by system?**
   - Check logcat: `adb logcat | grep TaskFlow`
   - Ensure handler completes quickly
   - Use constraints wisely

### Issue: Tasks Running Too Often

**Solution:**

```dart
// Use concurrency control
await TaskFlow.enqueue('sync', concurrency: ConcurrencyControl.limited);

// Use rate limiting
await TaskFlow.enqueue('sync', rateLimit: RateLimit.moderate);

// Use deduplication
await TaskFlow.enqueue(
  'sync',
  dedupPolicy: DedupPolicy.byInput(ttl: Duration(minutes: 5)),
);
```

### Issue: Tasks Failing Silently

**Debug:**

```dart
// Check execution history
final history = await TaskFlow.getHistory('myTask', limit: 10);
for (final entry in history) {
  if (entry.status == 'failed') {
    print('Failed: ${entry.error}');
    print('Stack: ${entry.stackTrace}');
  }
}

// Add logging
TaskFlow.onTaskFailed((entry) {
  print('🔥 Task failed: ${entry.taskName}');
  print('Error: ${entry.error}');
  print('Attempt: ${entry.attempt}');
});
```

### Issue: Memory Leaks

**Prevention:**

```dart
// Don't keep references to context outside handler
TaskFlow.registerHandler('sync', (ctx) async {
  // ❌ Don't capture ctx in callback
  // Future.delayed(..., () => doSomething(ctx));

  // ✅ Extract data and use locally
  final userId = ctx.input['userId'] as String;
  final data = await api.fetch(userId);

  return TaskResult.success(data: data);
});
```

---

## Real-World Examples

### Example 1: Reliable Payment Processing

```dart
TaskFlow.registerHandler('processPayment', (ctx) async {
  try {
    final orderId = ctx.input['orderId'] as String;
    final amount = ctx.input['amount'] as double;

    // Validate
    if (amount <= 0) {
      return TaskResult.failure(message: 'Invalid amount', canRetry: false);
    }

    // Report progress
    await ctx.reportProgress(0.3);

    // Process
    final txn = await paymentGateway.charge(orderId, amount);
    await ctx.reportProgress(0.7);

    // Verify
    final verified = await paymentGateway.verify(txn.id);
    if (!verified) {
      return TaskResult.failure(message: 'Verification failed');
    }

    await ctx.reportProgress(1.0);
    return TaskResult.success(data: {
      'transactionId': txn.id,
      'amount': amount,
      'status': 'completed',
    });
  } on PaymentGatewayException catch (e) {
    return TaskResult.retryLater();  // Retry on gateway issues
  }
});

// Enqueue with full protection
await TaskFlow.enqueue(
  'processPayment',
  input: {'orderId': order.id, 'amount': order.total},
  encryption: TaskEncryption.aes256,      // Encrypt payment data
  queue: TaskQueue.critical,               // Top priority
  dedupPolicy: DedupPolicy.byInput(       // Prevent double-charge
    ttl: Duration(hours: 24),
  ),
  retry: RetryPolicy.exponential(         // Robust retries
    maxAttempts: 5,
    initialDelay: Duration(seconds: 10),
    maxDelay: Duration(minutes: 5),
  ),
  timeout: TaskTimeout.moderate,           // 5 min timeout
);
```

### Example 2: Resilient Data Sync

```dart
TaskFlow.registerHandler('syncUserData', (ctx) async {
  final userId = ctx.input['userId'] as String;

  try {
    // Check auth first
    if (!await auth.isTokenValid()) {
      return TaskResult.failure(
        message: 'Auth expired',
        canRetry: false,
      );
    }

    // Fetch with timeout
    final data = await api.syncData(userId)
      .timeout(Duration(seconds: 30));

    // Save locally
    await db.save(userId, data);

    return TaskResult.success(data: {'synced': true});
  } on TimeoutException {
    return TaskResult.retryLater();  // Network timeout
  } on AuthException {
    return TaskResult.failure(message: 'Auth failed', canRetry: false);
  } catch (e) {
    return TaskResult.retryLater();  // Unknown - retry
  }
});

await TaskFlow.enqueue(
  'syncUserData',
  input: {'userId': user.id},
  constraints: TaskConstraints(
    network: NetworkConstraint.connected,
    batteryNotLow: true,
  ),
  retry: RetryPolicy.exponential(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 5),
  ),
  window: TimeWindow.offPeak,  // Only 2am-5am
);
```

### Example 3: Bulk Upload with Progress

```dart
final batch = await TaskFlow.batch(
  'uploadPhotos',
  items: photos.map((p) => {'photoId': p.id, 'path': p.path}).toList(),
  handler: (ctx, photo) async {
    try {
      final photoId = photo['photoId'] as String;
      final path = photo['path'] as String;

      final url = await cloudStorage.upload(path);
      await db.updatePhotoUrl(photoId, url);

      return TaskResult.success();
    } catch (e) {
      return TaskResult.retryLater();
    }
  },
);

batch
  .then((results) {
    final succeeded = results.where((r) => r.isSuccess).length;
    ui.showSuccess('$succeeded photos uploaded');
  })
  .catch((error) {
    ui.showError('Upload failed: $error');
  });
```

---

## Summary: The Reliability Checklist

Before going to production:

- ✅ All handlers have try-catch blocks
- ✅ Appropriate retry policies configured
- ✅ Lifecycle hooks for monitoring
- ✅ Sensitive data encrypted
- ✅ Rate limiting on API calls
- ✅ Concurrency control on resource-heavy tasks
- ✅ Deduplication for critical operations
- ✅ Circuit breaker for failing services
- ✅ Execution history reviewed for issues
- ✅ Tested on real device with poor network

**Your app is now production-ready and reliable.** 🚀

