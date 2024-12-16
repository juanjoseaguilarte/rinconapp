import 'package:gestion_propinas/task/domain/entities/task.dart';
import 'package:gestion_propinas/task/domain/repositories/task_repository.dart';

class AddTask {
  final TaskRepository taskRepository;

  AddTask(this.taskRepository);

  Future<void> call(String userId, String title, String description) async {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Generar ID único
      userId: userId,
      title: title,
      description: description,
      isCompleted: false, // Por defecto no está completada
    );
    await taskRepository.addTask(task);
  }
}
