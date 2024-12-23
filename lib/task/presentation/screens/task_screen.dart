import 'package:flutter/material.dart';
import 'package:gestion_propinas/task/application/services/task_service.dart';
import 'package:gestion_propinas/task/domain/entities/task.dart';
import 'package:gestion_propinas/task/presentation/screens/task_card_screen.dart';

class TaskScreen extends StatefulWidget {
  final String userId;
  final String userRole;
  final TaskService taskService;
  final Map<String, dynamic>? loggedInUser; // Nuevo parámetro
  final Future<List<Task>> Function(String) getUserTasks;
  final Future<void> Function(String, String, bool) updateTaskStatus;

  const TaskScreen({
    Key? key,
    required this.userId,
    required this.userRole,
    required this.loggedInUser, // Asegúrate de incluirlo aquí
    required this.getUserTasks,
    required this.updateTaskStatus,
    required this.taskService,
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
  if (_selectedFilter == "Creadas por mí") {
    // Cargar tareas creadas por el usuario
    setState(() {
      _tasks = widget.loggedInUser!['role'] == 'Admin' ||
              widget.loggedInUser!['role'] == 'Encargado'
          ? widget.taskService.getTasksCreatedBy(widget.userId)
          : Future.value([]); // No cargar nada si no es Admin o Encargado
    });
  } else {
    // Cargar tareas asignadas al usuario
    setState(() {
      _tasks = widget.getUserTasks(widget.userId).then((tasks) {
        if (_selectedFilter == "Pendientes") {
          return tasks.where((task) {
            final isCompleted = task.assignedToStatus[widget.userId] ?? false;
            return !isCompleted; // Filtra las tareas no completadas
          }).toList();
        } else if (_selectedFilter == "Completadas") {
          return tasks.where((task) {
            final isCompleted = task.assignedToStatus[widget.userId] ?? false;
            return isCompleted; // Filtra las tareas completadas
          }).toList();
        }
        return tasks; // Si no hay filtro, devuelve todas las tareas
      });
    });
  }
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
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Mis Tareas'),
      actions: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = "Pendientes";
                  _loadTasks();
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
                  _loadTasks();
                });
              },
              child: _buildBadge(
                "Completadas",
                _selectedFilter == "Completadas",
              ),
            ),
            const SizedBox(width: 8),
            if (widget.loggedInUser!['role'] == 'Admin' ||
                widget.loggedInUser!['role'] == 'Encargado')
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = "Creadas por mí";
                    _loadTasks();
                  });
                },
                child: _buildBadge(
                  "Creadas por mí",
                  _selectedFilter == "Creadas por mí",
                ),
              ),
          ],
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

        if (tasks.isEmpty) {
          return const Center(child: Text('No hay tareas para mostrar.'));
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return TaskCard(
              task: task,
              userId: widget.userId,
              isEditable: _selectedFilter == "Creadas por mí", // Mostrar botón de editar
              onStatusChange: (taskId, isCompleted) async {
                if (_selectedFilter != "Creadas por mí") {
                  try {
                    await widget.updateTaskStatus(taskId, widget.userId, isCompleted);
                    _loadTasks(); // Recarga las tareas después de actualizar el estado
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al cambiar estado: $e')),
                    );
                  }
                }
              },
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
}}
