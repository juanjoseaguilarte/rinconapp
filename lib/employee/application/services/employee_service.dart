import 'package:gestion_propinas/employee/application/usecases/add_employee_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/delete_employee_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/fetch_employees_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/get_employee_by_pin_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/update_employee_use_case.dart';
import 'package:gestion_propinas/employee/domain/entities/employee.dart';

class EmployeeService {
  final FetchEmployeesUseCase fetchEmployeesUseCase;
  final AddEmployeeUseCase addEmployeeUseCase;
  final GetEmployeeByPinUseCase getEmployeeByPinUseCase;
  final UpdateEmployeeUseCase updateEmployeeUseCase;
  final DeleteEmployeeUseCase deleteEmployeeUseCase;

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

  /// Obtiene el empleado actual basado en un PIN u otra credencial
  Future<Employee?> getCurrentUser(int currentUserPin) async {
    return await getEmployeeByPin(currentUserPin);
  }
}
