import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/employee/domain/repositories/employee_repository.dart';

class GetEmployeeByPin {
  final EmployeeRepository repository;

  GetEmployeeByPin(this.repository);

  Future<Employee?> execute(int pin) async {
    try {
      return await repository.getEmployeeByPin(pin);
    } catch (e) {
      print("Error en FetchEmployees: $e");
      rethrow; // Lanzar el error para que lo maneje la capa de presentación.
    }
  }
}
