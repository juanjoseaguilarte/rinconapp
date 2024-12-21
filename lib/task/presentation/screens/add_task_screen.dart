import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/domain/entities/employee.dart';

class AddTaskScreen extends StatefulWidget {
  final Future<void> Function(
      List<String> userIds, String title, String description) addTask;
  final Future<List<Employee>> Function() fetchEmployees;

  const AddTaskScreen({
    Key? key,
    required this.addTask,
    required this.fetchEmployees,
  }) : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<Employee> employees = [];
  List<String> selectedEmployeeIds = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employeeList = await widget.fetchEmployees();
    setState(() {
      employees = employeeList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Tarea')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecciona empleados:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final employee = employees[index];
                  final isSelected = selectedEmployeeIds.contains(employee.id);

                  return ListTile(
                    title: Text(employee.name),
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (isChecked) {
                        setState(() {
                          if (isChecked ?? false) {
                            selectedEmployeeIds.add(employee.id);
                          } else {
                            selectedEmployeeIds.remove(employee.id);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (selectedEmployeeIds.isNotEmpty &&
                    titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  await widget.addTask(
                    selectedEmployeeIds,
                    titleController.text,
                    descriptionController.text,
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, completa todos los campos')),
                  );
                }
              },
              child: const Text('Guardar Tarea'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
