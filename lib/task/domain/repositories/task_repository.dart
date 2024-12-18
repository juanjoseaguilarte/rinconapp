import 'package:gestion_propinas/task/domain/entities/task.dart';

abstract class TaskRepository {
  Future<void> addTask(Task task);
  Future<List<Task>> getUserTasks(String userId);
  Future<void> updateTaskStatus(String taskId, String userId, bool isCompleted);
}
