import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/task/application/services/task_service.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';
import 'package:gestion_propinas/cash/presentation/screens/cash_menu_screen.dart';
import 'package:gestion_propinas/admin/presentation/screens/admin_screen.dart';
import 'package:gestion_propinas/task/presentation/screens/add_task_screen.dart';
import 'package:gestion_propinas/task/presentation/screens/task_screen.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_options_screen.dart';

class HomeScreen extends StatefulWidget {
  final EmployeeService employeeService;
  final TipRepository tipRepository;
  final TaskService taskService;

  const HomeScreen({
    super.key,
    required this.employeeService,
    required this.tipRepository,
    required this.taskService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _pinController = TextEditingController();
  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic>? _loggedInUser;
  Timer? _logoutTimer;
  Map<String, int> _pendingTasks = {};

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = await widget.employeeService.getAllEmployees();

    // Obtener tareas pendientes de cada empleado
    final Map<String, int> pendingTasks = {};
    for (var employee in employees) {
      final tasks = await widget.taskService.getTasksForUser(employee.id);
      final pending = tasks
          .where((task) => !(task.assignedToStatus[employee.id] ?? false))
          .length;
      pendingTasks[employee.id] = pending;
    }

    setState(() {
      _employees = employees
          .map((e) => {'id': e.id, 'name': e.name, 'role': e.role})
          .toList();
      _pendingTasks = pendingTasks;
    });
  }

  Future<void> _showPinDialog(Map<String, dynamic> user) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ingrese PIN para ${user['name']}'),
        content: TextField(
          controller: _pinController,
          decoration: const InputDecoration(hintText: 'PIN'),
          keyboardType: TextInputType.number,
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pinController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = int.tryParse(_pinController.text) ?? -1;
              final isValid =
                  await widget.employeeService.getEmployeeByPin(pin);
              Navigator.of(context).pop();
              _pinController.clear();
              if (isValid != null && isValid.id == user['id']) {
                setState(() {
                  _loggedInUser = user;
                });
                _startLogoutTimer();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN incorrecto')),
                );
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _startLogoutTimer() {
    _logoutTimer?.cancel();
    _logoutTimer = Timer(const Duration(seconds: 15), () {
      setState(() {
        _loggedInUser = null;
      });
    });
  }

  Widget _buildEmployeeSelection() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _employees.map((user) {
        final pendingTasksCount = _pendingTasks[user['id']] ?? 0;

        return GestureDetector(
          onTap: () => _showPinDialog(user),
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
                    user['name'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              if (pendingTasksCount > 0)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedInUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Seleccione Usuario'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _employees.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildEmployeeSelection(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido ${_loggedInUser!['name']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              setState(() {
                _loggedInUser = null;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loggedInUser!['role'] == 'Admin'
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminScreen(),
                        ),
                      )
                  : null,
              child: const Text('Configuración'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TipOptionsScreen(
                      employeeService: widget.employeeService,
                      tipRepository: widget.tipRepository,
                      loggedUser: _loggedInUser!,
                    ),
                  ),
                );
              },
              child: const Text('Propinas'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CashMenuScreen(loggedUser: _loggedInUser!),
                  ),
                );
              },
              child: const Text('Caja'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskScreen(
                      userId: _loggedInUser!['id'],
                      getUserTasks: widget.taskService.getTasksForUser,
                      updateTaskStatus: widget.taskService.updateTaskStatus,
                    ),
                  ),
                );
              },
              child: const Text('Tareas'),
            ),
            ElevatedButton(
              onPressed: _loggedInUser!['role'] == 'Admin' ||
                      _loggedInUser!['role'] == 'Encargado'
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTaskScreen(
                            addTask: widget.taskService.addTask,
                            fetchEmployees:
                                widget.employeeService.getAllEmployees,
                          ),
                        ),
                      )
                  : null,
              child: const Text('Agregar Tarea'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _printTest,
              child: const Text('Test de Impresión'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logoutTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }
}
