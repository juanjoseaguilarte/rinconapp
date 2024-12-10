import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/employee/domain/repositories/employee_repository.dart';

class AuthenticateEmployeeByPin {
  final EmployeeRepository _repository;

  AuthenticateEmployeeByPin(this._repository);

  Future<Employee?> execute(int pin) async {
    return await _repository.getEmployeeByPin(pin);
  }
}
