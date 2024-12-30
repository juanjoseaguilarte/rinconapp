import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/domain/entities/employee.dart';

class EmployeeSelectionWidget extends StatelessWidget {
  final List<Employee> admins;
  final List<Employee> encargados;
  final List<Employee> salaEmployees;
  final List<Employee> cocinaEmployees;
  final Function(Employee) onTapEmployee;
  final Map<String, int> pendingTasks;

  const EmployeeSelectionWidget({
    super.key,
    required this.admins,
    required this.encargados,
    required this.salaEmployees,
    required this.cocinaEmployees,
    required this.onTapEmployee,
    required this.pendingTasks,
  });

  Widget _buildEmployeeGroup(String title, List<Employee> employees) {
    if (employees.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: employees.map((employee) {
            final pendingTasksCount = pendingTasks[employee.id] ?? 0;

            return GestureDetector(
              onTap: () => onTapEmployee(employee),
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        employee.name,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (pendingTasksCount > 0)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$pendingTasksCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEmployeeGroup("Admin", admins),
        _buildEmployeeGroup("Encargados", encargados),
        _buildEmployeeGroup("Empleados - Sala", salaEmployees),
        _buildEmployeeGroup("Empleados - Cocina", cocinaEmployees),
      ],
    );
  }
}
