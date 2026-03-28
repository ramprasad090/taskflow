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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TaskFlow: Ride-Hailing Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const Text(
                  '1️⃣ Deferrable Task (Sync History)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildButton(
                  'End Ride → Sync History',
                  () async {
                    final id = await TaskFlow.enqueue(
                      'syncRideHistory',
                      input: {'rideId': 'ride_${DateTime.now().millisecondsSinceEpoch}'},
                      constraints: TaskConstraints(
                        network: NetworkConstraint.connected,
                      ),
                      retry: RetryPolicy.exponential(
                        maxAttempts: 3,
                        initialDelay: Duration(seconds: 5),
                      ),
                    );
                    setState(() => _executionId = id);
                    _monitorTask(id);
                  },
                ),
                const SizedBox(height: 16),
                // ===== MODE 2: Persistent Service =====
                const Text(
                  '2️⃣ Persistent Service (GPS Tracking)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildButton(
                  'Start Live Tracking (Foreground)',
                  () async {
                    // Note: In real app, this would start a foreground service
                    final id = await TaskFlow.enqueue(
                      'updateLocation',
                      input: {'lat': 12.9716, 'lng': 77.5946},
                    );
                    setState(() => _executionId = id);
                    _monitorTask(id);
                  },
                ),
                const SizedBox(height: 16),
                // ===== MODE 3: Expedited Task =====
                const Text(
                  '3️⃣ Expedited Task (Payment)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildButton(
                  'Process Payment (ASAP)',
                  () async {
                    final id = await TaskFlow.enqueue(
                      'processPayment',
                      priority: TaskPriority.high,
                      input: {'amount': 250.50},
                    );
                    setState(() => _executionId = id);
                    _monitorTask(id);
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                // ===== Legacy Examples =====
                const Text(
                  'Legacy Examples',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildButton(
                  'Enqueue Task',
                  () async {
                    final id = await TaskFlow.enqueue(
                      'exampleTask',
                      constraints: TaskConstraints(
                        network: NetworkConstraint.connected,
                      ),
                      retry: RetryPolicy.exponential(
                        maxAttempts: 3,
                        initialDelay: Duration(seconds: 5),
                      ),
                    );
                    setState(() => _executionId = id);
                    _monitorTask(id);
                  },
                ),
                const SizedBox(height: 12),
                _buildButton(
                  'Enqueue Failing Task (Will Retry)',
                  () async {
                    final id = await TaskFlow.enqueue(
                      'failingTask',
                      retry: RetryPolicy.linear(
                        maxAttempts: 2,
                        delay: Duration(seconds: 2),
                      ),
                    );
                    setState(() => _executionId = id);
                    _monitorTask(id);
                  },
                ),
                const SizedBox(height: 12),
                _buildButton(
                  'Enqueue Task with Input',
                  () async {
                    final id = await TaskFlow.enqueue(
                      'delayedTask',
                      input: {'seconds': 5},
                    );
                    setState(() => _executionId = id);
                    _monitorTask(id);
                  },
                ),
                const SizedBox(height: 24),
                if (_executionId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Execution ID: $_executionId',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        if (_currentStatus != null)
                          Text(
                            'Status: ${_statusString(_currentStatus!)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _statusColor(_currentStatus!),
                            ),
                          ),
                        if (_currentStatus is TaskRunning)
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: (_currentStatus as TaskRunning).progress,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Progress: ${((_currentStatus as TaskRunning).progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
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
                  '✅ Task priorities (high, normal, low)\n',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _monitorTask(String executionId) {
    TaskFlow.monitorExecution(executionId).listen((status) {
      setState(() => _currentStatus = status);
    });
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(label),
        ),
      ),
    );
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

  Color _statusColor(TaskStatus status) {
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
