import 'package:gestion_propinas/task/domain/entities/task.dart';
import 'package:gestion_propinas/task/domain/repositories/task_repository.dart';

class AddTask {
  final TaskRepository taskRepository;

  AddTask(this.taskRepository);

  Future<void> call(
      List<String> userIds, String title, String description) async {
    final Map<String, bool> assignedToStatus = {
      for (var userId in userIds) userId: false, // Inicializar estados en false
    };

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      assignedTo: userIds,
      assignedToStatus: assignedToStatus,
      createdAt: DateTime.now(),
    );

    await taskRepository.addTask(task);
  }
}
