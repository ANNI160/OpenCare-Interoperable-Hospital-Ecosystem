import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/task_model.dart';

class TasksTab extends StatefulWidget {
  final int wardNumber;

  const TasksTab({
    super.key,
    required this.wardNumber,
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  final _taskTitleController = TextEditingController();
  final _taskDescController = TextEditingController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadTasks());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _taskTitleController.dispose();
    _taskDescController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService();
      final tasks = await db.getTasksForWard(widget.wardNumber);
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addTask() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Task', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _taskTitleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                prefixIcon: Icon(Icons.task_alt),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _taskDescController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_taskTitleController.text.isEmpty) return;
                  final db = DatabaseService();
                  final task = TaskModel(
                    id: '',
                    title: _taskTitleController.text.trim(),
                    description: _taskDescController.text.trim().isEmpty
                        ? null
                        : _taskDescController.text.trim(),
                    wardNumber: widget.wardNumber,
                    assignedNurseId: user.id,
                    assignedNurseName: user.name,
                    createdAt: DateTime.now(),
                  );
                  await db.addTask(task);
                  _taskTitleController.clear();
                  _taskDescController.clear();
                  if (mounted) {
                    Navigator.pop(context);
                    _loadTasks();
                  }
                },
                child: const Text('Add Task'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTask(TaskModel task) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final db = DatabaseService();
    await db.updateTaskStatus(
      taskId: task.id,
      isCompleted: !task.isCompleted,
      completedByNurseId: authProvider.currentUser?.id,
      completedByNurseName: authProvider.currentUser?.name,
    );
    _loadTasks();
  }

  Future<void> _deleteTask(TaskModel task) async {
    final db = DatabaseService();
    await db.deleteTask(task.id);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks for Ward ${widget.wardNumber}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add a new task',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTasks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Dismissible(
                        key: Key(task.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteTask(task),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Checkbox(
                              value: task.isCompleted,
                              onChanged: (_) => _toggleTask(task),
                              activeColor: AppTheme.successColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted
                                    ? AppTheme.textSecondary
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: task.description != null
                                ? Text(
                                    task.description!,
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  )
                                : null,
                            trailing: task.patientName != null
                                ? Chip(
                                    label: Text(
                                      task.patientName!,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}
