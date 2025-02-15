import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/employee/domain/repositories/employee_repository.dart';

class AuthenticateEmployeeByPinUseCase {
  final EmployeeRepository _repository;

  AuthenticateEmployeeByPinUseCase(this._repository);

  Future<Employee?> execute(int pin) async {
    return await _repository.getEmployeeByPin(pin);
  }
}
