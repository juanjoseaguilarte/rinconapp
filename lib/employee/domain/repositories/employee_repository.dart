
import 'package:gestion_propinas/employee/domain/entities/employee.dart';

abstract class EmployeeRepository {
  Future<void> insertEmployee(Employee employee);
  Future<List<Employee>> fetchEmployees();
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);
  Future<String?> getEmployeeIdByName(String name);
  Future<String?> getAdminId();
  Future<Employee?> getEmployeeByPin(int pin);
}
