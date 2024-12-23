// task/application/usecases/get_tasks_created_by_usecase.dart
import 'package:gestion_propinas/task/domain/entities/task.dart';
import 'package:gestion_propinas/task/domain/repositories/task_repository.dart';

class GetTasksCreatedBy {
  final TaskRepository taskRepository;

  GetTasksCreatedBy(this.taskRepository);

  Future<List<Task>> execute(String userId) {
    return taskRepository.getTasksCreatedBy(userId);
  }
}
