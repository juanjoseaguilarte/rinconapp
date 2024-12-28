import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/infrastucture/repositories/firebase_arqueo_repository.dart';
import 'package:gestion_propinas/cash/infrastucture/repositories/firebase_cash_adapter.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/task/application/services/task_service.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';
import 'package:gestion_propinas/admin/presentation/screens/admin_screen.dart';
import 'package:gestion_propinas/cash/presentation/screens/cash_menu_screen.dart';
import 'package:gestion_propinas/employee/presentation/screens/employee_screen.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_options_screen.dart';
import 'package:gestion_propinas/task/presentation/screens/task_screen.dart'
    as TaskScreenView;
import 'package:gestion_propinas/task/presentation/screens/add_task_screen.dart';

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
  Timer? _refreshTimer;
  Map<String, int> _pendingTasks = {};

  @override
  void initState() {
    super.initState();
    _loadEmployees();

    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _loadEmployees();
    });
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await widget.employeeService.getAllEmployees();
      final Map<String, int> pendingTasks = {};

      for (var employee in employees) {
        final tasks = await widget.taskService.getTasksForUser(employee.id);
        final pending = tasks
            .where((task) => !(task.assignedToStatus[employee.id] ?? false))
            .length;
        pendingTasks[employee.id] = pending;
      }

      employees.sort((a, b) {
        const rolePriority = {'Admin': 1, 'Encargado': 2, 'Empleado': 3};
        final priorityA = rolePriority[a.role] ?? 4;
        final priorityB = rolePriority[b.role] ?? 4;
        return priorityA.compareTo(priorityB);
      });

      setState(() {
        _employees = employees
            .map((e) => {
                  'id': e.id,
                  'name': e.name,
                  'role': e.role,
                  'position': e.position,
                })
            .toList();
        _pendingTasks = pendingTasks;
      });
    } catch (e) {
      print('Error al cargar empleados o tareas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar empleados o tareas')),
      );
    }
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
    final roles = ['Admin', 'Encargado', 'Empleado'];

    final groupedByRole = {
      for (var role in roles)
        role: _employees.where((e) => e['role'] == role).toList(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: roles.map((role) {
        final employeesByRole = groupedByRole[role] ?? [];
        if (employeesByRole.isEmpty) return const SizedBox();

        if (role == 'Empleado') {
          final positions = {'Sala', 'Cocina'};
          final groupedByPosition = {
            for (var position in positions)
              position: employeesByRole
                  .where((e) => e['position'] == position)
                  .toList(),
          };

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
              ...groupedByPosition.entries.map((entry) {
                final position = entry.key;
                final employeesForPosition = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        position,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: employeesForPosition.map((user) {
                        final pendingTasksCount =
                            _pendingTasks[user['id']] ?? 0;

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
                                  border:
                                      Border.all(color: Colors.grey, width: 1),
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
            ],
          );
        }

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
              children: employeesByRole.map((user) {
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
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final arqueoRepository = FirebaseArqueoRepository(
                  firestore: FirebaseFirestore.instance,
                );
                final transactionRepo = FirebaseCashTransactionRepository(
                  firestore: FirebaseFirestore.instance,
                );

                double initialAmount =
                    await arqueoRepository.getInitialAmount();
                DateTime? lastArqueoDate =
                    await arqueoRepository.getLastArqueoDate() ??
                        DateTime(2000);

                final transactions = await transactionRepo
                    .fetchTransactionsSince(lastArqueoDate);

                double entradas = 0.0;
                double salidas = 0.0;
                for (var t in transactions) {
                  if (t.type == 'entrada') {
                    entradas += t.amount;
                  } else if (t.type == 'salida') {
                    salidas += t.amount;
                  }
                }

                final expectedAmount = initialAmount + entradas - salidas;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CashMenuScreen(
                      loggedUser: _loggedInUser!,
                      expectedAmount: expectedAmount,
                    ),
                  ),
                );
              },
              child: const Text('Caja'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployeeScreen(
                      employeeService: widget.employeeService,
                    ),
                  ),
                );
              },
              child: const Text('Empleados'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskScreenView.TaskScreen(
                      userId: _loggedInUser!['id'],
                      userRole: _loggedInUser!['role'],
                      taskService: widget.taskService,
                      loggedInUser: _loggedInUser,
                      getUserTasks: widget.taskService.getTasksForUser,
                      updateTaskStatus: widget.taskService.updateTaskStatus,
                    ),
                  ),
                );
              },
              child: const Text('BETA Tareas'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskScreen(
                      fetchEmployees: () async {
                        final employees =
                            await widget.employeeService.getAllEmployees();
                        return employees
                            .map((e) => {'id': e.id, 'name': e.name})
                            .toList();
                      },
                      addTask: (userIds, title, description) {
                        return widget.taskService.addTask(
                          _loggedInUser!['id'],
                          userIds,
                          title,
                          description,
                        );
                      },
                    ),
                  ),
                );
              },
              child: const Text('BETA Agregar Tarea'),
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
