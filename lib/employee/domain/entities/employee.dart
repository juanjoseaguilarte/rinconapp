class Employee {
  final String id;
  final String name;
  final int pin;
  final String role;
  final String position; // Nuevo campo

  Employee({
    required this.id,
    required this.name,
    required this.pin,
    required this.role,
    required this.position, // Incluye `position` en el constructor
  });

  factory Employee.fromMap(Map<String, dynamic> data) {
    return Employee(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      pin: data['pin'] as int? ?? 0,
      role: data['role'] as String? ?? 'Empleado',
      position:
          data['position'] as String? ?? 'Sin especificar', // Valor por defecto
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pin': pin,
      'role': role,
      'position': position, // Incluye `position` al convertir a mapa
    };
  }
}
