import 'package:flutter/material.dart';
import 'package:bg_orchestrator/taskflow.dart';

// Entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register task handlers in main isolate (simple example)
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
      appBar: AppBar(title: const Text('TaskFlow Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'TaskFlow Background Task Orchestrator',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
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
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Features Demonstrated:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Enqueue one-off tasks\n'
                  '• Monitor task progress in real-time\n'
                  '• Automatic retry with exponential/linear backoff\n'
                  '• Pass input data to tasks\n'
                  '• Report progress from handlers\n'
                  '• Track task status via streams\n',
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
