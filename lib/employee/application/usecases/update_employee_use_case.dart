import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/employee/domain/repositories/employee_repository.dart';

class UpdateEmployeeUseCase {
  final EmployeeRepository repository;

  UpdateEmployeeUseCase(this.repository);

  Future<void> execute(Employee employee) async {
    try {
      await repository.updateEmployee(employee);
    } catch (e) {
      print("Error en UpdateEmployeeUseCase: $e");
      rethrow;
    }
  }
}
