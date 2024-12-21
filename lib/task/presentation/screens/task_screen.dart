import 'package:flutter/material.dart';
import 'package:gestion_propinas/task/domain/entities/task.dart';

class TaskScreen extends StatefulWidget {
  final String userId;
  final Future<List<Task>> Function(String) getUserTasks;
  final Future<void> Function(String, String, bool) updateTaskStatus;

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
  String _selectedFilter = "Pendientes"; // Filtro por defecto

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
    final currentStatus = task.assignedToStatus[widget.userId] ?? false;

    try {
      await widget.updateTaskStatus(task.id, widget.userId, !currentStatus);
      _loadTasks(); // Recargar tareas después de actualizar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar tarea: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = "Pendientes";
                    });
                  },
                  child: _buildBadge(
                    "Pendientes",
                    _selectedFilter == "Pendientes",
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = "Completadas";
                    });
                  },
                  child: _buildBadge(
                    "Completadas",
                    _selectedFilter == "Completadas",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

          // Filtrar las tareas según el filtro seleccionado
          final filteredTasks = tasks.where((task) {
            final isCompleted = task.assignedToStatus[widget.userId] ?? false;
            return _selectedFilter == "Pendientes" ? !isCompleted : isCompleted;
          }).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          if (filteredTasks.isEmpty) {
            return const Center(child: Text('No hay tareas para mostrar.'));
          }

          return ListView.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              final isCompleted = task.assignedToStatus[widget.userId] ?? false;

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
                            isCompleted ? 'Completada' : 'Pendiente',
                            style: TextStyle(
                              fontSize: 14,
                              color: isCompleted ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: isCompleted,
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

  Widget _buildBadge(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
