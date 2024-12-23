import 'package:flutter/material.dart';
import 'package:gestion_propinas/task/domain/entities/task.dart';
import 'package:gestion_propinas/task/presentation/screens/edit_task_screen.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Function(String, bool)
      onStatusChange; // Callback para manejar el cambio de estado
  final String userId;
  final bool isEditable; // Indica si el botón de editar debe mostrarse

  const TaskCard({
    Key? key,
    required this.task,
    required this.onStatusChange,
    required this.userId,
    this.isEditable = false, // Por defecto, no editable
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determina si la tarea está completada por el usuario actual
    final isCompleted = task.assignedToStatus[userId] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.warning,
          color: isCompleted ? Colors.green : Colors.red,
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(task.description),
        trailing: isEditable
            ? IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTaskScreen(task: task),
                    ),
                  );
                },
              )
            : Switch(
                value: isCompleted,
                onChanged: (newValue) {
                  onStatusChange(task.id,
                      newValue); // Llama al callback con el nuevo estado
                },
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
              ),
      ),
    );
  }
}
