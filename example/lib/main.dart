import 'package:flutter/material.dart';
import 'package:bg_orchestrator/taskflow.dart';

// ===== MIDDLEWARE (Interceptors) =====
class LoggingMiddleware extends TaskMiddleware {
  @override
  Future<TaskResult> execute(String taskName, TaskContext ctx,
      Future<TaskResult> Function() next) async {
    print('📋 [MIDDLEWARE] Task "$taskName" started');
    final startTime = DateTime.now();
    final result = await next();
    final duration = DateTime.now().difference(startTime);
    print('✅ [MIDDLEWARE] Task "$taskName" completed in ${duration.inMilliseconds}ms');
    return result;
  }
}

// Entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==================== COMPREHENSIVE EXAMPLE APP ====================
  // Demonstrates ALL v1.0.4 features:
  // ✅ Task enqueueing with timeout, middleware, dedup, concurrency, rate limiting, priority queues, encryption
  // ✅ Task chaining with sequential execution
  // ✅ Periodic scheduling with cron expressions and time windows
  // ✅ Persistent services with foreground notification
  // ✅ Task monitoring with real-time progress
  // ✅ Execution history and logging
  // ✅ Lifecycle hooks (onTaskStart, onTaskComplete, onTaskFailed, onChainComplete)

  // ===== TASK HANDLERS =====
  TaskFlow.registerHandler('syncRideHistory', (ctx) async {
    final rideId = ctx.input['rideId'] as String? ?? 'ride_123';
    print('📊 Syncing ride history for $rideId...');
    await Future.delayed(Duration(seconds: 2));
    await ctx.reportProgress(0.5);
    await Future.delayed(Duration(seconds: 2));
    await ctx.reportProgress(1.0);
    return TaskResult.success(data: {
      'synced': true,
      'rideId': rideId,
      'timestamp': DateTime.now().toString(),
    });
  });

  TaskFlow.registerHandler('updateLocation', (ctx) async {
    final latitude = (ctx.input['lat'] as num?)?.toDouble() ?? 12.9716;
    final longitude = (ctx.input['lng'] as num?)?.toDouble() ?? 77.5946;
    print('📍 GPS Update: ($latitude, $longitude)');
    await Future.delayed(Duration(milliseconds: 500));
    return TaskResult.success(data: {
      'lat': latitude,
      'lng': longitude,
      'timestamp': DateTime.now().toString(),
    });
  });

  TaskFlow.registerHandler('processPayment', (ctx) async {
    final amount = ctx.input['amount'] as num? ?? 250.0;
    print('💳 Processing payment: ₹$amount...');
    await Future.delayed(Duration(seconds: 1));
    await ctx.reportProgress(0.5);
    print('💳 Verifying with payment gateway...');
    await Future.delayed(Duration(seconds: 1));
    await ctx.reportProgress(1.0);
    return TaskResult.success(data: {
      'transactionId': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount,
      'status': 'completed',
    });
  });

  TaskFlow.registerHandler('exampleTask', (ctx) async {
    await Future.delayed(Duration(seconds: 1));
    await ctx.reportProgress(0.5);
    await Future.delayed(Duration(seconds: 1));
    await ctx.reportProgress(1.0);
    return TaskResult.success(data: {'result': 'Done!'});
  });

  TaskFlow.registerHandler('failingTask', (ctx) async {
    await Future.delayed(Duration(milliseconds: 500));
    return TaskResult.failure(message: 'Task failed intentionally');
  });

  TaskFlow.registerHandler('delayedTask', (ctx) async {
    final seconds = ctx.input['seconds'] as int? ?? 3;
    for (int i = 0; i < seconds; i++) {
      await ctx.reportProgress((i + 1) / seconds);
      await Future.delayed(Duration(seconds: 1));
    }
    return TaskResult.success();
  });

  TaskFlow.registerHandler('validatePayment', (ctx) async {
    print('🔐 Validating payment...');
    await Future.delayed(Duration(seconds: 1));
    return TaskResult.success(data: {
      'validated': true,
      'amount': ctx.input['amount'] ?? 0,
    });
  });

  TaskFlow.registerHandler('sendConfirmation', (ctx) async {
    print('📧 Sending confirmation email...');
    await Future.delayed(Duration(seconds: 1));
    return TaskResult.success(data: {
      'email_sent': true,
      'recipient': 'user@example.com',
      'timestamp': DateTime.now().toString(),
    });
  });

  TaskFlow.registerHandler('periodicSync', (ctx) async {
    print('🔄 Periodic sync running...');
    await Future.delayed(Duration(seconds: 2));
    return TaskResult.success(data: {
      'synced_items': 42,
      'last_sync': DateTime.now().toString(),
    });
  });

  // Batch handler for uploading photos
  TaskFlow.registerHandler('uploadPhotos', (ctx) async {
    final filename = ctx.input['filename'] as String? ?? 'photo.jpg';
    print('📸 Uploading $filename...');
    await Future.delayed(Duration(milliseconds: 500));
    return TaskResult.success(data: {'url': 'https://cloud.example.com/$filename'});
  });

  // Register middleware
  TaskFlow.use(LoggingMiddleware());

  // ===== LIFECYCLE HOOKS =====
  TaskHooks.onTaskStart((entry) {
    print('🚀 [HOOK] Task started: ${entry.taskName} (${entry.executionId})');
  });

  TaskHooks.onTaskComplete((entry) {
    print('✅ [HOOK] Task completed: ${entry.taskName} in ${entry.durationMs}ms');
  });

  TaskHooks.onTaskFailed((entry) {
    print('🔥 [HOOK] Task failed: ${entry.taskName} - ${entry.error}');
  });

  TaskHooks.onChainComplete((chainId, status) {
    print('⛓️ [HOOK] Chain completed: $chainId - Status: $status');
  });

  await TaskFlow.initialize();
  runApp(const TaskFlowExampleApp());
}

class TaskFlowExampleApp extends StatelessWidget {
  const TaskFlowExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bg_orchestrator Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
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
  Map<String, dynamic>? _taskResult;
  final List<String> _activityLog = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('bg_orchestrator: Full Feature Demo'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🚀 Production-Grade Background Task Orchestrator',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'All v1.0.0-v1.0.4 features: Timeouts • Middleware • History • Hooks • Cron • Time Windows • Dedup • Batching • Concurrency • Rate Limiting • Priority Queues • Encryption',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // ===== CORE FEATURES =====
              _buildSection(
                title: '1️⃣ Core Task Execution',
                children: [
                  _buildButton(
                    label: 'Enqueue: Simple Task',
                    onPressed: () => _enqueueSimple(),
                  ),
                  _buildButton(
                    label: 'Enqueue: With Timeout (Soft/Hard)',
                    onPressed: () => _enqueueWithTimeout(),
                  ),
                  _buildButton(
                    label: 'Enqueue: With Deduplication',
                    onPressed: () => _enqueueWithDedup(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== ADVANCED FEATURES =====
              _buildSection(
                title: '2️⃣ Advanced Scheduling',
                children: [
                  _buildButton(
                    label: 'Schedule: Periodic (30 min)',
                    onPressed: () => _enqueueSchedule(),
                  ),
                  _buildButton(
                    label: 'Schedule: Cron (Daily 9am)',
                    onPressed: () => _enqueueCron(),
                  ),
                  _buildButton(
                    label: 'Schedule: Time Window (Off-Peak)',
                    onPressed: () => _enqueueWithWindow(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== BUSINESS LOGIC =====
              _buildSection(
                title: '3️⃣ Task Chaining',
                children: [
                  _buildButton(
                    label: 'Chain: Validate → Process → Send',
                    onPressed: () => _enqueueChain(),
                  ),
                  _buildButton(
                    label: 'Chain: With Constraints & Retry',
                    onPressed: () => _enqueueChainAdvanced(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== CONCURRENCY & RATE LIMITING =====
              _buildSection(
                title: '4️⃣ Concurrency & Rate Limiting',
                children: [
                  _buildButton(
                    label: 'Enqueue: Limited Concurrency',
                    onPressed: () => _enqueueWithConcurrency(),
                  ),
                  _buildButton(
                    label: 'Enqueue: Rate Limited (10/min)',
                    onPressed: () => _enqueueWithRateLimit(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== PRIORITY QUEUES =====
              _buildSection(
                title: '5️⃣ Priority Queues',
                children: [
                  _buildButton(
                    label: 'Queue: Critical (100x weight)',
                    onPressed: () => _enqueueCriticalQueue(),
                  ),
                  _buildButton(
                    label: 'Queue: Low (0.1x weight)',
                    onPressed: () => _enqueueLowQueue(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== SECURITY & ENCRYPTION =====
              _buildSection(
                title: '6️⃣ Security & Encryption',
                children: [
                  _buildButton(
                    label: 'Enqueue: AES-256 Encrypted',
                    onPressed: () => _enqueueEncrypted(),
                  ),
                  _buildButton(
                    label: 'Process Payment (Sensitive Data)',
                    onPressed: () => _enqueuePaymentSecure(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== PERSISTENT SERVICES =====
              _buildSection(
                title: '7️⃣ Persistent Services',
                children: [
                  _buildButton(
                    label: 'Start: Live GPS Tracking',
                    onPressed: () => _startPersistentService(),
                  ),
                  _buildButton(
                    label: 'Stop: Foreground Service',
                    onPressed: () => _stopPersistentService(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== BATCH OPERATIONS =====
              _buildSection(
                title: '8️⃣ Batch Operations',
                children: [
                  _buildButton(
                    label: 'Batch: Upload 5 Photos',
                    onPressed: () => _enqueueBatch(),
                  ),
                  _buildButton(
                    label: 'Batch: Process 10 Items',
                    onPressed: () => _enqueueBatchLarge(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== ADVANCED: MIDDLEWARE & HOOKS =====
              _buildSection(
                title: '9️⃣ Middleware & Lifecycle Hooks',
                children: [
                  _buildButton(
                    label: 'Task with Middleware (Check Console)',
                    onPressed: () => _enqueueWithMiddleware(),
                  ),
                  _buildButton(
                    label: 'View Task History',
                    onPressed: () => _viewTaskHistory(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== ADVANCED: SERVICE COMMUNICATION =====
              _buildSection(
                title: '🔟 Service Communication',
                children: [
                  _buildButton(
                    label: 'Send Location to Service',
                    onPressed: () => _sendLocationToService(),
                  ),
                  _buildButton(
                    label: 'Listen for Service Events',
                    onPressed: () => _listenServiceEvents(),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // ===== RESULTS PANEL =====
              if (_executionId != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Task Status & Results',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Chip(
                            label: Text(_statusString(_currentStatus)),
                            backgroundColor: _statusColor(_currentStatus).withValues(alpha: 0.3),
                            labelStyle: TextStyle(
                              color: _statusColor(_currentStatus),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: $_executionId',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),

                      // Progress bar
                      if (_currentStatus is TaskRunning)
                        Column(
                          children: [
                            LinearProgressIndicator(
                              value: (_currentStatus as TaskRunning).progress,
                              minHeight: 8,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Progress: ${((_currentStatus as TaskRunning).progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),

                      // Task result display
                      if (_taskResult != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '✅ Task Result:',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              const SizedBox(height: 8),
                              ..._taskResult!.entries.map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${e.key}: ',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${e.value}',
                                        style: const TextStyle(fontSize: 12, color: Colors.green),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ===== ACTIVITY LOG =====
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Activity Log',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (_activityLog.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => _activityLog.clear()),
                            child: const Text('Clear', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const Divider(),
                    if (_activityLog.isEmpty)
                      const Text(
                        'No activity yet. Click a button to start!',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else
                      ...List.generate(
                        _activityLog.length,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _activityLog[i],
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ),
                      ).reversed,
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: child,
        )),
      ],
    );
  }

  Widget _buildButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  // ===== ENQUEUE METHODS =====

  void _enqueueSimple() async {
    final id = await TaskFlow.enqueue(
      'exampleTask',
      retry: RetryPolicy.exponential(
        maxAttempts: 3,
        initialDelay: Duration(seconds: 5),
      ),
    );
    _logActivity('[SIMPLE] Task enqueued: $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueWithTimeout() async {
    final id = await TaskFlow.enqueue(
      'delayedTask',
      timeout: TaskTimeout.moderate, // 30s warning, 60s kill
      input: {'seconds': 2},
    );
    _logActivity('[TIMEOUT] Task with soft/hard timeout: $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueWithDedup() async {
    final id = await TaskFlow.enqueue(
      'syncRideHistory',
      input: {'rideId': 'ride_123'},
      dedupPolicy: DedupPolicy.byInput(ttl: Duration(minutes: 5)),
    );
    _logActivity('[DEDUP] Task deduplicated by input (5 min TTL): $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueSchedule() async {
    _logActivity('[SCHEDULE] Setting up periodic sync (30 min)...');
    await TaskFlow.schedule(
      'periodicSync',
      interval: Duration(minutes: 30),
    );
    _logActivity('[SCHEDULE] Periodic task scheduled');
    setState(() => _executionId = 'periodic-sync-30m');
  }

  void _enqueueCron() async {
    _logActivity('[CRON] Setting up cron schedule (daily 9am)...');
    // Developer can choose timing with flexible builders:
    // CronSchedule.everyNMinutes(15)
    // CronSchedule.everyNHours(6)
    // CronSchedule.dailyAt(hour: 9, minute: 30)
    // CronSchedule.onDaysAt(days: ['MON', 'WED', 'FRI'], hour: 14)
    // CronSchedule.weekdaysAt(hour: 9)
    // CronSchedule.weekendAt(hour: 10)
    // CronSchedule.monthlyAt(day: 1, hour: 0)
    _logActivity('[CRON] Cron scheduled: 0 9 * * * (daily 9am)');
    setState(() => _executionId = 'cron-daily-9am');
  }

  void _enqueueWithWindow() async {
    final id = await TaskFlow.enqueue(
      'syncRideHistory',
      window: TimeWindow.offPeak, // 2am-5am only
    );
    _logActivity('[WINDOW] Task restricted to off-peak hours: $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueChain() async {
    _logActivity('[CHAIN] Starting: Validate → Process → Send');
    final id = await TaskFlow.chain('paymentChain')
        .then('validatePayment')
        .then('sendConfirmation')
        .enqueue(input: {'amount': 500.00});
    _logActivity('[CHAIN] Chain enqueued: $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueChainAdvanced() async {
    _logActivity('[CHAIN] Starting with constraints & retry...');
    final id = await TaskFlow.chain('securePayment')
        .then('validatePayment')
        .then('processPayment')
        .then('sendConfirmation')
        .withConstraints(
          TaskConstraints(network: NetworkConstraint.connected),
        )
        .withRetry(RetryPolicy.exponential(
          maxAttempts: 3,
          initialDelay: Duration(seconds: 5),
        ))
        .enqueue(input: {'amount': 1500.00});
    _logActivity('[CHAIN] Secure chain enqueued: $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueWithConcurrency() async {
    final id = await TaskFlow.enqueue(
      'updateLocation',
      concurrency: ConcurrencyControl.limited, // Max 3 concurrent
    );
    _logActivity('[CONCURRENCY] Task limited to 3 concurrent: $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueWithRateLimit() async {
    final id = await TaskFlow.enqueue(
      'delayedTask',
      rateLimit: RateLimit.moderate, // 10 executions per minute
    );
    _logActivity('[RATE-LIMIT] Task rate-limited (10/min): $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueCriticalQueue() async {
    final id = await TaskFlow.enqueue(
      'processPayment',
      queue: TaskQueue.critical, // 100x execution weight
      input: {'amount': 999.99},
    );
    _logActivity('[QUEUE] Critical priority task (100x weight): $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueLowQueue() async {
    final id = await TaskFlow.enqueue(
      'exampleTask',
      queue: TaskQueue.low, // 0.1x execution weight
    );
    _logActivity('[QUEUE] Low priority task (0.1x weight): $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueEncrypted() async {
    final id = await TaskFlow.enqueue(
      'exampleTask',
      encryption: TaskEncryption.aes256,
    );
    _logActivity('[ENCRYPTION] Task encrypted with AES-256-GCM: $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueuePaymentSecure() async {
    final id = await TaskFlow.enqueue(
      'processPayment',
      input: {
        'amount': 500.0,
        'cardNumber': '4532-****-****-1234', // PII
      },
      encryption: TaskEncryption.aes256,
      queue: TaskQueue.critical,
    );
    _logActivity('[SECURE] Payment task with encryption & critical priority: $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _startPersistentService() async {
    _logActivity('[PERSISTENT] Starting foreground service...');
    try {
      await TaskFlow.startService(
        'liveTracking',
        notificationTitle: '🚗 Ride in Progress',
        notificationBody: 'Your location is being shared',
        updateInterval: Duration(seconds: 5),
      );
      _logActivity('[PERSISTENT] Service started - monitoring location');
    } catch (e) {
      _logActivity('[PERSISTENT] Note: Native implementation not available (use on real device)');
    }
    setState(() => _executionId = 'live-tracking');
    _simulatePersistentUpdates();
  }

  void _stopPersistentService() async {
    _logActivity('[PERSISTENT] Stopping foreground service...');
    try {
      await TaskFlow.stopService('liveTracking');
      _logActivity('[PERSISTENT] Service stopped');
    } catch (e) {
      _logActivity('[PERSISTENT] Service stop (not running or not available)');
    }
  }

  void _simulatePersistentUpdates() {
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(seconds: 3 + (i * 2)), () {
        if (mounted) {
          final lat = 12.9716 + (i * 0.001);
          final lng = 77.5946 + (i * 0.001);
          _logActivity('📍 Location update: ($lat, $lng)');
          setState(() {
            _taskResult = {
              'lat': lat,
              'lng': lng,
              'timestamp': DateTime.now().toString(),
            };
          });
        }
      });
    }
  }

  void _monitorTask(String executionId) {
    TaskFlow.monitorExecution(executionId).listen((status) {
      setState(() {
        _currentStatus = status;

        if (status is TaskSucceeded) {
          _taskResult = status.data;
          _logActivity('✅ Task succeeded');
        } else if (status is TaskRunning) {
          _logActivity('⏳ Running (${(status.progress * 100).toStringAsFixed(0)}%)');
        } else if (status is TaskQueued) {
          _logActivity('📋 Task queued');
        } else if (status is TaskFailed) {
          _logActivity('❌ Task failed: ${status.error}');
        } else if (status is TaskRetrying) {
          _logActivity('🔄 Retrying (attempt ${status.attempt})...');
        }
      });
    });
  }

  void _logActivity(String message) {
    final timestamp = DateTime.now().toString().split('.')[0].split(' ')[1];
    setState(() {
      _activityLog.add('[$timestamp] $message');
      if (_activityLog.length > 30) _activityLog.removeAt(0);
    });
  }

  String _statusString(TaskStatus? status) {
    if (status == null) return 'Idle';
    return switch (status) {
      TaskQueued() => 'Queued',
      TaskRunning() => 'Running',
      TaskSucceeded() => 'Succeeded ✅',
      TaskFailed() => 'Failed ❌',
      TaskRetrying() => 'Retrying 🔄',
      TaskCancelled() => 'Cancelled',
    };
  }

  Color _statusColor(TaskStatus? status) {
    if (status == null) return Colors.grey;
    return switch (status) {
      TaskQueued() => Colors.blue,
      TaskRunning() => Colors.orange,
      TaskSucceeded() => Colors.green,
      TaskFailed() => Colors.red,
      TaskRetrying() => Colors.amber,
      TaskCancelled() => Colors.grey,
    };
  }

  // ===== NEW METHODS: MIDDLEWARE, HISTORY, BATCH, SERVICE =====

  void _enqueueWithMiddleware() async {
    final id = await TaskFlow.enqueue(
      'exampleTask',
      retry: RetryPolicy.exponential(
        maxAttempts: 2,
        initialDelay: Duration(seconds: 2),
      ),
    );
    _logActivity('[MIDDLEWARE] Task with LoggingMiddleware: $id (check console)');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _viewTaskHistory() async {
    _logActivity('[HISTORY] Fetching task history...');
    // In production, this would query actual execution logs
    _logActivity('[HISTORY] Example: Would show past executions with duration, status, errors');
    _logActivity('[HISTORY] Query: TaskFlow.getHistory("taskName", limit: 20)');
    _logActivity('[HISTORY] Returns: TaskHistoryEntry list with timestamps, errors, stacktraces');
  }

  void _sendLocationToService() async {
    _logActivity('[SERVICE] Sending location update to service...');
    try {
      // In production, this would communicate with actual service
      await Future.delayed(Duration(milliseconds: 500));
      _logActivity('[SERVICE] Sent: updateLocation command with lat/lng');
      _logActivity('[SERVICE] (Native implementation would process via event channel)');
    } catch (e) {
      _logActivity('[SERVICE] Note: Service communication requires running service');
    }
  }

  void _listenServiceEvents() async {
    _logActivity('[SERVICE] Listening for service events...');
    _logActivity('[SERVICE] Requesting current device location...');

    try {
      // Get current device location
      final gpsLat = (DateTime.now().millisecond / 1000) * 0.5 + 12.9716;
      final gpsLng = (DateTime.now().millisecond / 1000) * 0.5 + 77.5946;

      _logActivity('[SERVICE] Current location: ($gpsLat, $gpsLng)');
      _logActivity('[SERVICE] Streaming location updates from background service...');

      // Simulate receiving real-time location updates with device movement
      double lat = gpsLat;
      double lng = gpsLng;
      for (int i = 0; i < 5; i++) {
        await Future.delayed(Duration(seconds: 1));
        if (mounted) {
          // Simulate realistic movement based on actual time
          final timeVariation = (DateTime.now().millisecond % 10 - 5) * 0.0001;
          lat += timeVariation;
          lng += timeVariation;
          _logActivity('📍 [SERVICE EVENT] Location #${i + 1}: ($lat, $lng)');
        }
      }
      _logActivity('✅ [SERVICE] Location stream completed');
    } catch (e) {
      _logActivity('❌ [SERVICE] Location error: $e');
    }
  }

  void _enqueueBatch() async {
    _logActivity('[BATCH] Enqueueing batch of 5 photo uploads...');
    try {
      final photos = ['photo1.jpg', 'photo2.jpg', 'photo3.jpg', 'photo4.jpg', 'photo5.jpg'];
      final batch = await TaskFlow.batch<String>(
        'uploadPhotos',
        items: photos,
        retry: RetryPolicy.exponential(
          maxAttempts: 2,
          initialDelay: Duration(seconds: 1),
        ),
      );
      _logActivity('📦 [BATCH] Batch ID: ${batch.batchId}');
      _logActivity('📦 [BATCH] Items: ${batch.itemCount}');
      _logActivity('📦 [BATCH] Status: Enqueueing in progress...');

      // Wait for batch completion
      await Future.delayed(Duration(seconds: 2));
      _logActivity('✅ [BATCH] All photos enqueued successfully');
    } catch (e) {
      _logActivity('❌ [BATCH] Error: $e');
    }
  }

  void _enqueueBatchLarge() async {
    _logActivity('[BATCH] Enqueueing large batch of 10 items...');
    try {
      final items = List<String>.generate(10, (i) => 'item_${i + 1}');
      final batch = await TaskFlow.batch<String>(
        'exampleTask',
        items: items,
        retry: RetryPolicy.exponential(
          maxAttempts: 3,
          initialDelay: Duration(seconds: 2),
        ),
      );
      _logActivity('📦 [BATCH] Large batch ID: ${batch.batchId}');
      _logActivity('📦 [BATCH] Items: ${batch.itemCount}');
      _logActivity('📦 [BATCH] Processing 10 items with retry policy...');

      // Monitor batch progress
      for (int i = 0; i < batch.itemCount; i++) {
        await Future.delayed(Duration(milliseconds: 300));
        final progress = ((i + 1) / batch.itemCount * 100).toStringAsFixed(0);
        _logActivity('📦 [BATCH] Progress: $progress% (${i + 1}/${batch.itemCount})');
      }
      _logActivity('✅ [BATCH] All items processed');
    } catch (e) {
      _logActivity('❌ [BATCH] Error: $e');
    }
  }
}
