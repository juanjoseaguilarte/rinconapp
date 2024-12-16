class Task {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isCompleted;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}
