import 'package:flutter/material.dart';
import 'package:bg_orchestrator/taskflow.dart';

// Entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==================== RIDE-HAILING EXAMPLE (Ola/Uber) ====================

  // Mode 1: Deferrable Task - Sync ride history after trip ends
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

  // Mode 2: Persistent Service - Live GPS tracking (always-on)
  TaskFlow.registerHandler('updateLocation', (ctx) async {
    final latitude = (ctx.input['lat'] as num?)?.toDouble() ?? 12.9716;
    final longitude = (ctx.input['lng'] as num?)?.toDouble() ?? 77.5946;
    print('📍 GPS Update: ($latitude, $longitude)');
    // Simulates GPS location broadcast
    await Future.delayed(Duration(milliseconds: 500));
    return TaskResult.success(data: {
      'lat': latitude,
      'lng': longitude,
      'timestamp': DateTime.now().toString(),
    });
  });

  // Mode 3: Expedited Task - Process payment immediately
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

  // Legacy example tasks
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

  // Chain example: validatePayment → processPayment → sendConfirmation
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

  // Schedule example: periodic sync
  TaskFlow.registerHandler('periodicSync', (ctx) async {
    print('🔄 Periodic sync running...');
    await Future.delayed(Duration(seconds: 2));
    return TaskResult.success(data: {
      'synced_items': 42,
      'last_sync': DateTime.now().toString(),
    });
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
      appBar: AppBar(title: const Text('TaskFlow: Ride-Hailing Example')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🚗 Ola/Uber Style Ride-Hailing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Three execution modes in one app',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // ===== MODE 1: Deferrable Task =====
              _buildModeSection(
                title: '1️⃣ Deferrable Task (Sync History)',
                description: 'Waits for network, retries on failure',
                buttonLabel: 'End Ride → Sync History',
                onPressed: () => _enqueueDeferrable(),
              ),
              const SizedBox(height: 16),

              // ===== MODE 2: Persistent Service =====
              _buildModeSection(
                title: '2️⃣ Persistent Service (GPS Tracking)',
                description: 'Foreground service, always-on, requires notification',
                buttonLabel: 'Start Live Tracking',
                onPressed: () => _enqueuePersistent(),
              ),
              const SizedBox(height: 16),

              // ===== MODE 3: Expedited Task =====
              _buildModeSection(
                title: '3️⃣ Expedited Task (Payment)',
                description: 'Runs ASAP, high priority, no constraints',
                buttonLabel: 'Process Payment (ASAP)',
                onPressed: () => _enqueueExpedited(),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // ===== TASK CHAINING =====
              _buildModeSection(
                title: '⛓️ Task Chaining (Sequential)',
                description: 'Run multiple tasks in sequence, pass data between them',
                buttonLabel: 'Chain: Validate → Process → Send',
                onPressed: () => _enqueueChain(),
              ),
              const SizedBox(height: 16),

              // ===== PERIODIC SCHEDULING =====
              _buildModeSection(
                title: '⏰ Periodic Scheduling (15+ min)',
                description: 'Run task on a schedule, survives app kill',
                buttonLabel: 'Schedule Sync (every 30 min)',
                onPressed: () => _enqueueSchedule(),
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
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                      ).reversed,
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // ===== FEATURES =====
              const Text(
                'Features Demonstrated:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '✅ Three execution modes (Deferrable, Persistent, Expedited)\n'
                '✅ Monitor task progress in real-time\n'
                '✅ Automatic retry with exponential/linear backoff\n'
                '✅ Pass input data to tasks\n'
                '✅ Report progress from handlers\n'
                '✅ Track task status via streams\n'
                '✅ Task constraints (network, battery, charging)\n'
                '✅ Task priorities (high, normal, low)\n'
                '✅ Display task results & activity log\n',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSection({
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(buttonLabel),
            ),
          ),
        ),
      ],
    );
  }

  void _enqueueDeferrable() async {
    final id = await TaskFlow.enqueue(
      'syncRideHistory',
      input: {'rideId': 'ride_${DateTime.now().millisecondsSinceEpoch}'},
      constraints: TaskConstraints(network: NetworkConstraint.connected),
      retry: RetryPolicy.exponential(maxAttempts: 3, initialDelay: Duration(seconds: 5)),
    );
    _logActivity('[DEFERRABLE] Task enqueued: $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueuePersistent() async {
    final id = await TaskFlow.enqueue(
      'updateLocation',
      input: {'lat': 12.9716, 'lng': 77.5946},
    );
    _logActivity('[PERSISTENT] Service started: $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueExpedited() async {
    final id = await TaskFlow.enqueue(
      'processPayment',
      priority: TaskPriority.high,
      input: {'amount': 250.50},
    );
    _logActivity('[EXPEDITED] Payment task queued: $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueChain() async {
    _logActivity('[CHAIN] Starting sequential task chain...');
    // Chain: validatePayment → sendConfirmation
    final id = await TaskFlow.chain('paymentChain')
        .then('validatePayment')
        .then('sendConfirmation')
        .enqueue(input: {'amount': 500.00});
    _logActivity('[CHAIN] Chain enqueued: $id');
    setState(() => _executionId = id);
    _monitorTask(id);
  }

  void _enqueueSchedule() async {
    _logActivity('[SCHEDULE] Setting up periodic sync...');
    // Schedule task to run every 30 minutes (minimum 15 min)
    await TaskFlow.schedule(
      'periodicSync',
      interval: Duration(minutes: 30),
    );
    _logActivity('[SCHEDULE] Periodic task scheduled');
    setState(() => _executionId = 'periodic-sync');
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
      if (_activityLog.length > 20) _activityLog.removeAt(0);
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
}
