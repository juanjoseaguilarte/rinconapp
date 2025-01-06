import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/infrastucture/repositories/firebase_arqueo_repository.dart';
import 'package:gestion_propinas/cash/infrastucture/repositories/firebase_cash_adapter.dart';
import 'package:get_it/get_it.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/task/application/services/task_service.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';
import 'package:gestion_propinas/admin/presentation/screens/admin_screen.dart';
import 'package:gestion_propinas/cash/presentation/screens/cash_menu_screen.dart';
import 'package:gestion_propinas/employee/presentation/screens/employee_screen.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_options_screen.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_pay_screen.dart';
import 'package:gestion_propinas/task/presentation/screens/task_screen.dart'
    as TaskScreenView;
import 'package:gestion_propinas/task/presentation/screens/add_task_screen.dart';
import 'package:gestion_propinas/home/presentation/widgets/employee_selection_widget.dart';
import 'package:gestion_propinas/employee/domain/entities/employee.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _pinController = TextEditingController();

  final EmployeeService employeeService = GetIt.instance<EmployeeService>();
  final TipRepository tipRepository = GetIt.instance<TipRepository>();
  final TaskService taskService = GetIt.instance<TaskService>();

  List<Employee> _admins = [];
  List<Employee> _encargados = [];
  List<Employee> _salaEmployees = [];
  List<Employee> _cocinaEmployees = [];
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
      final employees = await employeeService.getAllEmployees();
      final Map<String, int> pendingTasks = {};

      for (var employee in employees) {
        final tasks = await taskService.getTasksForUser(employee.id);
        final pending = tasks
            .where((task) => !(task.assignedToStatus[employee.id] ?? false))
            .length;
        pendingTasks[employee.id] = pending;
      }

      setState(() {
        _admins = employees.where((e) => e.role == 'Admin').toList();
        _encargados = employees.where((e) => e.role == 'Encargado').toList();
        _salaEmployees = employees
            .where((e) => e.role == 'Empleado' && e.position == 'Sala')
            .toList();
        _cocinaEmployees = employees
            .where((e) => e.role == 'Empleado' && e.position == 'Cocina')
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

  Future<void> _showPinDialog(Employee user) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ingrese PIN para ${user.name}'),
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
              final isValid = await employeeService.getEmployeeByPin(pin);
              Navigator.of(context).pop();
              _pinController.clear();
              if (isValid != null && isValid.id == user.id) {
                setState(() {
                  _loggedInUser = {
                    'id': user.id,
                    'name': user.name,
                    'role': user.role,
                    'position': user.position,
                  };
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

  @override
  Widget build(BuildContext context) {
    if (_loggedInUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Seleccione Usuario Version 6 de enero'),
        ),
        body: SingleChildScrollView(
          // Permite el scroll
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: EmployeeSelectionWidget(
              admins: _admins,
              encargados: _encargados,
              salaEmployees: _salaEmployees,
              cocinaEmployees: _cocinaEmployees,
              onTapEmployee: _showPinDialog,
              pendingTasks: _pendingTasks,
            ),
          ),
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
      body: SingleChildScrollView(
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
                      employeeService: employeeService,
                      tipRepository: tipRepository,
                      loggedUser: _loggedInUser!,
                    ),
                  ),
                );
              },
              child: const Text('Propinas'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployeeScreen(
                      employeeService: employeeService,
                    ),
                  ),
                );
              },
              child: const Text('Empleados'),
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
                      expectedAmount: expectedAmount, // Pasa el monto calculado
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
                    builder: (context) => TaskScreenView.TaskScreen(
                      userId: _loggedInUser!['id'],
                      userRole: _loggedInUser!['role'],
                      taskService: taskService,
                      loggedInUser: _loggedInUser,
                      getUserTasks: taskService.getTasksForUser,
                      updateTaskStatus: taskService.updateTaskStatus,
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
                            await employeeService.getAllEmployees();
                        return employees
                            .map((e) => {'id': e.id, 'name': e.name})
                            .toList();
                      },
                      addTask: (userIds, title, description) {
                        return taskService.addTask(
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
    _refreshTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }
}
