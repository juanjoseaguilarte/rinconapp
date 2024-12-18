import 'package:gestion_propinas/task/domain/repositories/task_repository.dart';

class UpdateTaskStatus {
  final TaskRepository taskRepository;

  UpdateTaskStatus(this.taskRepository);

  Future<void> call(String taskId, String userId, bool isCompleted) {
    return taskRepository.updateTaskStatus(taskId, userId, isCompleted);
  }
}
