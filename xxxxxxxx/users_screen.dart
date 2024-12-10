import 'package:flutter/material.dart';
import 'package:gestion_propinas/models/employee.dart';
import 'package:gestion_propinas/services/Databases/employee_database_service.dart';
import 'package:uuid/uuid.dart';

class UsersScreen extends StatefulWidget {
  final Employee employee;

  UsersScreen({required this.employee});

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final EmployeeDatabaseService _employeeService = EmployeeDatabaseService();
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = await _employeeService.fetchEmployees();
    setState(() {
      _employees = employees;
    });
  }

  void _showEditEmployeeDialog(BuildContext context, Employee employee) {
    final TextEditingController _nameController =
        TextEditingController(text: employee.name);
    final TextEditingController _pinController =
        TextEditingController(text: employee.pin.toString());
    String selectedRole = employee.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Empleado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(hintText: 'Nombre del empleado'),
            ),
            TextField(
              controller: _pinController,
              decoration: InputDecoration(hintText: 'PIN del empleado'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: ['Admin', 'Encargado', 'Empleado'].map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedRole = value;
                }
              },
              decoration: InputDecoration(hintText: 'Selecciona un rol'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text;
              final pinText = _pinController.text;
              if (name.isNotEmpty && pinText.isNotEmpty) {
                final pin = int.tryParse(pinText) ?? employee.pin;
                final updatedEmployee = Employee(
                  id: employee.id,
                  name: name,
                  pin: pin,
                  role: selectedRole,
                );
                await _employeeService.updateEmployee(updatedEmployee);
                Navigator.of(context).pop();
                _loadEmployees(); // Recargar la lista después de editar
              }
            },
            child: Text('Guardar Cambios'),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeDialog(BuildContext context) {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _pinController = TextEditingController();
    String selectedRole = 'Empleado';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Añadir Nuevo Empleado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(hintText: 'Nombre del empleado'),
            ),
            TextField(
              controller: _pinController,
              decoration: InputDecoration(hintText: 'PIN del empleado'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: ['Admin', 'Encargado', 'Empleado'].map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedRole = value;
                }
              },
              decoration: InputDecoration(hintText: 'Selecciona un rol'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text;
              final pinText = _pinController.text;
              if (name.isNotEmpty && pinText.isNotEmpty) {
                final pin = int.tryParse(pinText) ?? 0;
                final uuid = Uuid();
                final newEmployee = Employee(
                  id: uuid.v4(),
                  name: name,
                  pin: pin,
                  role: selectedRole,
                );
                await _employeeService.insertEmployee(newEmployee);
                Navigator.of(context).pop();
                _loadEmployees(); // Recargar la lista después de añadir
              }
            },
            child: Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _deleteEmployee(BuildContext context, Employee employee) async {
    if (employee.role == 'Admin') {
      // Mostrar un mensaje indicando que no se puede eliminar un Admin
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se puede eliminar a un usuario Admin')),
      );
      return;
    }

    await _employeeService.deleteEmployee(employee.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Empleado eliminado')),
    );
    _loadEmployees(); // Recargar la lista después de eliminar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestión de Usuarios')),
      body: Column(
        children: [
          Expanded(
            child: _employees.isEmpty
                ? Center(child: Text('No hay empleados guardados.'))
                : ListView.builder(
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final employee = _employees[index];
                      return ListTile(
                        title: Text(employee.name),
                        subtitle: Text('Rol: ${employee.role}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () =>
                                  _showEditEmployeeDialog(context, employee),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteEmployee(context, employee),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (widget.employee.role == 'Admin' ||
              widget.employee.role == 'Encargado')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => _showAddEmployeeDialog(context),
                child: Text('Añadir Usuario'),
              ),
            ),
        ],
      ),
    );
  }
}
