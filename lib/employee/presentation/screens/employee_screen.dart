import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:uuid/uuid.dart';

class EmployeeScreen extends StatefulWidget {
  final EmployeeService employeeService;

  const EmployeeScreen({Key? key, required this.employeeService})
      : super(key: key);

  @override
  _EmployeeScreenState createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  late Future<List<Employee>> _employeeFuture;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  String selectedRole = 'Empleado';

  @override
  void initState() {
    super.initState();
    _reloadEmployees();
  }

  void _reloadEmployees() {
    setState(() {
      _employeeFuture = widget.employeeService.getAllEmployees();
    });
  }

  void _showAddOrEditEmployeeDialog(BuildContext context,
      {Employee? employee}) {
    final isEditing = employee != null;
    _nameController.text = isEditing ? employee.name : '';
    _pinController.text = isEditing ? employee.pin.toString() : '';
    selectedRole = isEditing ? employee.role : 'Empleado';
    String selectedPosition = isEditing ? employee.position : 'Sin especificar';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Empleado' : 'Añadir Nuevo Empleado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(hintText: 'Nombre del empleado'),
            ),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(hintText: 'PIN del empleado'),
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
              decoration: const InputDecoration(hintText: 'Selecciona un puesto'),
            ),
            DropdownButtonFormField<String>(
              value: selectedPosition,
              items: ['Sala', 'Cocina', 'Admin'].map((position) {
                return DropdownMenuItem(
                  value: position,
                  child: Text(position),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedPosition = value;
                }
              },
              decoration:
                  const InputDecoration(hintText: 'Selecciona un puesto'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text;
              final pinText = _pinController.text;
              if (name.isNotEmpty && pinText.isNotEmpty) {
                final pin = int.tryParse(pinText) ?? 0;
                if (isEditing) {
                  // Editar empleado
                  final updatedEmployee = Employee(
                    id: employee!.id,
                    name: name,
                    pin: pin,
                    role: selectedRole,
                    position: selectedPosition,
                  );
                  await widget.employeeService.updateEmployee(updatedEmployee);
                } else {
                  // Añadir nuevo empleado
                  final uuid = Uuid();
                  final newEmployee = Employee(
                    id: uuid.v4(),
                    name: name,
                    pin: pin,
                    role: selectedRole,
                    position: selectedPosition,
                  );
                  await widget.employeeService.addEmployee(newEmployee);
                }
                Navigator.of(context).pop();
                _reloadEmployees(); // Recargar la lista
              }
            },
            child: Text(isEditing ? 'Guardar Cambios' : 'Agregar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEmployee(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar al empleado "${employee.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEmployee(employee);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteEmployee(Employee employee) async {
    if (employee.role == 'Admin') {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
            content: Text('No se puede eliminar a un usuario Admin')),
      );
      return;
    }

    await widget.employeeService.deleteEmployee(employee.id);

    _scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Empleado eliminado')),
    );

    _reloadEmployees(); // Recargar la lista
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(title: const Text('Empleados')),
      body: FutureBuilder<List<Employee>>(
        future: _employeeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return ErrorDisplay(
              onRetry: _reloadEmployees,
              message:
                  'Error al cargar empleados. Por favor, intenta de nuevo.',
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron empleados.'));
          } else {
            return EmployeeList(
              employees: snapshot.data!,
              onEdit: (employee) =>
                  _showAddOrEditEmployeeDialog(context, employee: employee),
              onDelete: (employee) => _confirmDeleteEmployee(context, employee),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditEmployeeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ErrorDisplay extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;

  const ErrorDisplay({Key? key, required this.onRetry, required this.message})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class EmployeeList extends StatelessWidget {
  final List<Employee> employees;
  final Function(Employee) onEdit;
  final Function(Employee) onDelete;

  const EmployeeList({
    Key? key,
    required this.employees,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return ListTile(
          title: Text(employee.name),
          subtitle: Text('Rol: ${employee.role}\nPuesto: ${employee.position}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => onEdit(employee),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDelete(employee),
              ),
            ],
          ),
        );
      },
    );
  }
}
