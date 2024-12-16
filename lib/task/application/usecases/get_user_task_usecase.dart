import 'package:gestion_propinas/task/domain/entities/task.dart';
import 'package:gestion_propinas/task/domain/repositories/task_repository.dart';

class GetUserTasks {
  final TaskRepository taskRepository;

  GetUserTasks(this.taskRepository);

  Future<List<Task>> call(String userId) {
    return taskRepository.getUserTasks(userId);
  }
}
