import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/employee/domain/repositories/employee_repository.dart';

class FetchEmployees {
  final EmployeeRepository repository;

  FetchEmployees(this.repository);

  Future<List<Employee>> execute() async {
    try {
      return await repository.fetchEmployees();
    } catch (e) {
      print("Error en FetchEmployees: $e");
      rethrow; // Lanzar el error para que lo maneje la capa de presentación.
    }
  }
}
