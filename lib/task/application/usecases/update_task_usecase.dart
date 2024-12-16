import 'package:gestion_propinas/task/infrastructure/repositories/firestore_task_repository.dart';

class UpdateTaskStatus {
  final FirebaseTaskRepository repository;

  UpdateTaskStatus(this.repository);

  Future<void> call(String taskId, bool isCompleted) {
    return repository.updateTaskStatus(taskId, isCompleted);
  }
}