import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_propinas/task/domain/entities/task.dart';
import 'package:gestion_propinas/task/domain/repositories/task_repository.dart';

class FirebaseTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> addTask(Task task) async {
    await _firestore.collection('tasks').add(task.toMap());
  }

  @override
  Future<List<Task>> getUserTasks(String userId) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
  }

  @override
  Future<void> updateTaskStatus(String taskId, bool isCompleted) async {
    await _firestore
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': !isCompleted});
  }
}
