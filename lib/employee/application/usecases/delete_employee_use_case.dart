import 'package:gestion_propinas/employee/domain/repositories/employee_repository.dart';

class DeleteEmployeeUseCase {
  final EmployeeRepository repository;

  DeleteEmployeeUseCase(this.repository);

  Future<void> execute(String id) async {
    try {
      await repository.deleteEmployee(id);
    } catch (e) {
      print("Error en DeleteEmployeeUseCase: $e");
      rethrow;
    }
  }
}
