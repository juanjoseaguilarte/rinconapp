import 'package:gestion_propinas/employee/application/usecases/add_employee.dart';
import 'package:gestion_propinas/employee/application/usecases/delete_employee.dart';
import 'package:gestion_propinas/employee/application/usecases/fetch_employees.dart';
import 'package:gestion_propinas/employee/application/usecases/get_employee_by_pin.dart';
import 'package:gestion_propinas/employee/application/usecases/update_employee.dart';

import '../../domain/entities/employee.dart';

class EmployeeService {
  final FetchEmployees fetchEmployeesUseCase;
  final AddEmployee addEmployeeUseCase;
  final GetEmployeeByPin getEmployeeByPinUseCase;
  final UpdateEmployee updateEmployeeUseCase;
  final DeleteEmployee deleteEmployeeUseCase; 

  EmployeeService({
    required this.fetchEmployeesUseCase,
    required this.addEmployeeUseCase,
    required this.getEmployeeByPinUseCase,
    required this.updateEmployeeUseCase,
    required this.deleteEmployeeUseCase, 
  });

  Future<List<Employee>> getAllEmployees() async {
    return await fetchEmployeesUseCase.execute();
  }

  Future<void> addEmployee(Employee employee) async {
    await addEmployeeUseCase.execute(employee);
  }

  Future<Employee?> getEmployeeByPin(int pin) async {
    return await getEmployeeByPinUseCase.execute(pin);
  }

  Future<void> updateEmployee(Employee employee) async {
    await updateEmployeeUseCase.execute(employee);
  }

  Future<void> deleteEmployee(String id) async {
    await deleteEmployeeUseCase.execute(id);
  }
}
