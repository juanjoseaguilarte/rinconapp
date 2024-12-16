import 'package:flutter/material.dart';
import 'package:gestion_propinas/task/domain/entities/task.dart';

class TaskScreen extends StatefulWidget {
  final String userId;
  final Future<List<Task>> Function(String) getUserTasks;
  final Future<void> Function(String, bool) updateTaskStatus;

  const TaskScreen({
    Key? key,
    required this.userId,
    required this.getUserTasks,
    required this.updateTaskStatus,
  }) : super(key: key);

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late Future<List<Task>> _tasks;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _tasks = widget.getUserTasks(widget.userId);
    });
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      await widget.updateTaskStatus(task.id, !task.isCompleted);
      _loadTasks(); // Refresca la lista de tareas después de actualizar
    } catch (e) {
      // Muestra un mensaje de error si algo falla
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar tarea: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Tareas')),
      body: FutureBuilder<List<Task>>(
        future: _tasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const Center(child: Text('No tienes tareas asignadas.'));
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            task.isCompleted ? 'Completada' : 'Pendiente',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  task.isCompleted ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: task.isCompleted,
                            onChanged: (_) => _toggleTaskCompletion(task),
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
