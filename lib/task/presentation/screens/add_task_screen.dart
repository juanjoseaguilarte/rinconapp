import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/domain/entities/employee.dart';

class AddTaskScreen extends StatefulWidget {
  final Future<void> Function(String userId, String title, String description)
      addTask;
  final Future<List<Employee>> Function()
      fetchEmployees; // Nueva función para obtener empleados

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
  Employee? selectedEmployee;

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
            DropdownButton<Employee>(
              hint: const Text('Selecciona un empleado'),
              value: selectedEmployee,
              items: employees.map((employee) {
                return DropdownMenuItem<Employee>(
                  value: employee,
                  child: Text(employee.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedEmployee = value;
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (selectedEmployee != null &&
                    titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  await widget.addTask(
                    selectedEmployee!.id,
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
