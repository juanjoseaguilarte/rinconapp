import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/employee/domain/repositories/employee_repository.dart';

class GetEmployeeByPinUseCase {
  final EmployeeRepository repository;

  GetEmployeeByPinUseCase(this.repository);

  Future<Employee?> execute(int pin) async {
    try {
      return await repository.getEmployeeByPin(pin);
    } catch (e) {
      print("Error en GetEmployeeByPinUseCase: $e");
      rethrow;
    }
  }
}
