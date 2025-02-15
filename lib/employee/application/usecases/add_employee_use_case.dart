import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/employee/domain/repositories/employee_repository.dart';

class AddEmployeeUseCase {
  final EmployeeRepository repository;

  AddEmployeeUseCase(this.repository);

  Future<void> execute(Employee employee) async {
    try {
      await repository.insertEmployee(employee);
    } catch (e) {
      print("Error en AddEmployeeUseCase: $e");
      rethrow;
    }
  }
}
