import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/employee/domain/repositories/employee_repository.dart';

class FetchEmployeesUseCase {
  final EmployeeRepository repository;

  FetchEmployeesUseCase(this.repository);

  Future<List<Employee>> execute() async {
    try {
      return await repository.fetchEmployees();
    } catch (e) {
      print("Error en FetchEmployeesUseCase: $e");
      rethrow; // Lanzar el error para que lo maneje la capa de presentación.
    }
  }
}
