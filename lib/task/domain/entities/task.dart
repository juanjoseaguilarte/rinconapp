class Task {
  final String id;
  final String title;
  final String description;
  final List<String> assignedTo;
  final Map<String, bool> assignedToStatus;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedToStatus,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedToStatus': assignedToStatus,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String? ?? '', // Valor por defecto: cadena vacía
      title: map['title'] as String? ?? 'Sin título',
      description: map['description'] as String? ?? 'Sin descripción',
      assignedTo: List<String>.from(map['assignedTo'] ?? []),
      assignedToStatus: Map<String, bool>.from(map['assignedToStatus'] ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(), // Valor por defecto: ahora
    );
  }
}
