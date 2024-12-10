import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/employee/domain/repositories/employee_repository.dart';

class UpdateEmployee {
  final EmployeeRepository repository;

  UpdateEmployee(this.repository);

  Future<void> execute(Employee employee) async {
    try {
      await repository.updateEmployee(employee);
    } catch (e) {
      print("Error en AddEmployee: $e");
      rethrow;
    }
  }
}
