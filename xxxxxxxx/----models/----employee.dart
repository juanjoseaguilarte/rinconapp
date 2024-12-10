class Employee {
  final String id;
  final String name;
  final int pin;
  final String role; // Añadir el campo `role`

  Employee({
    required this.id,
    required this.name,
    required this.pin,
    required this.role, // Incluir `role` en el constructor
  });

  // Método para crear una instancia de Employee desde un mapa
  factory Employee.fromMap(Map<String, dynamic> data) {
    return Employee(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      pin: data['pin'] as int? ?? 0,
      role: data['role'] as String? ??
          'Empleado', // Asegurarse de obtener `role` del mapa
    );
  }

  // Método para convertir una instancia de Employee a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pin': pin,
      'role': role, // Incluir `role` en el mapa
    };
  }
}
