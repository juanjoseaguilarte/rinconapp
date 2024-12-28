import 'package:flutter/material.dart';

class EmployeeSelection extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groupedEmployees;
  final Map<String, int> pendingTasks;
  final Function(Map<String, dynamic>) onEmployeeTap;

  const EmployeeSelection({
    super.key,
    required this.groupedEmployees,
    required this.pendingTasks,
    required this.onEmployeeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedEmployees.entries.map((entry) {
        final role = entry.key;
        final employees = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                role,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: employees.map((user) {
                final pendingTasksCount = pendingTasks[user['id']] ?? 0;

                return GestureDetector(
                  onTap: () => onEmployeeTap(user),
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
                            user['name'] ?? 'Sin Nombre',
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
      }).toList(),
    );
  }
}
