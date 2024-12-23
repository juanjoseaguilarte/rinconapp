import 'package:gestion_propinas/task/domain/entities/task.dart';

// task/domain/repositories/task_repository.dart
abstract class TaskRepository {
  Future<void> addTask(Task task);
  Future<List<Task>> getUserTasks(String userId);
  Future<List<Task>> getTasksCreatedBy(String userId); // Nuevo método
  Future<void> updateTaskStatus(String taskId, String userId, bool isCompleted);
}
