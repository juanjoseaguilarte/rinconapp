import 'package:gestion_propinas/task/application/usecases/add_task_usecase.dart';
import 'package:gestion_propinas/task/application/usecases/get_user_task_usecase.dart';
import 'package:gestion_propinas/task/application/usecases/update_task_usecase.dart';
import 'package:gestion_propinas/task/domain/entities/task.dart';

class TaskService {
  final GetUserTasks getUserTasksUseCase;
  final UpdateTaskStatus updateTaskStatusUseCase;
  final AddTask addTaskUseCase;

  TaskService({
    required this.getUserTasksUseCase,
    required this.updateTaskStatusUseCase,
    required this.addTaskUseCase,
  });

  Future<List<Task>> getTasksForUser(String userId) {
    return getUserTasksUseCase(userId);
  }

  Future<void> updateTaskStatus(String taskId, bool isCompleted) {
    return updateTaskStatusUseCase(taskId, isCompleted);
  }

  Future<void> addTask(String userId, String title, String description) {
    return addTaskUseCase(userId, title, description);
  }
}