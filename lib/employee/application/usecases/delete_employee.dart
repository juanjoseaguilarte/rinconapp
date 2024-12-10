import 'package:gestion_propinas/employee/domain/repositories/employee_repository.dart';

class DeleteEmployee {
  final EmployeeRepository repository;

  DeleteEmployee(this.repository);

  Future<void> execute(String id) async {
    try {
      return await repository.deleteEmployee(id);
    } catch (e) {
      print("Error en FetchEmployees: $e");
      rethrow; // Lanzar el error para que lo maneje la capa de presentación.
    }
  }
}
