// task/application/services/task_service.dart
import 'package:gestion_propinas/task/application/usecases/add_task_usecase.dart';
import 'package:gestion_propinas/task/application/usecases/get_tasks_created_by_usecase.dart';
import 'package:gestion_propinas/task/application/usecases/get_user_task_usecase.dart';
import 'package:gestion_propinas/task/application/usecases/update_task_usecase.dart';
import 'package:gestion_propinas/task/domain/entities/task.dart';

class TaskService {
  final GetUserTasks getUserTasksUseCase;
  final UpdateTaskStatus updateTaskStatusUseCase;
  final AddTask addTaskUseCase;
  final GetTasksCreatedBy getTasksCreatedByUseCase; // Nuevo caso de uso

  TaskService({
    required this.getUserTasksUseCase,
    required this.updateTaskStatusUseCase,
    required this.addTaskUseCase,
    required this.getTasksCreatedByUseCase,
  });

  Future<List<Task>> getTasksForUser(String userId) {
    return getUserTasksUseCase(userId);
  }

  Future<List<Task>> getTasksCreatedBy(String userId) {
    return getTasksCreatedByUseCase.execute(userId);
  }

  Future<void> updateTaskStatus(
      String taskId, String userId, bool isCompleted) {
    return updateTaskStatusUseCase(taskId, userId, isCompleted);
  }

  Future<void> addTask(String createdBy, List<String> userIds, String title,
      String description) {
    return addTaskUseCase(createdBy, userIds, title, description);
  }
}
