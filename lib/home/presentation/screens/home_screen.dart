import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/infrastructure/repositories/firebase_arqueo_repository.dart';
import 'package:gestion_propinas/cash/infrastructure/repositories/firebase_cash_adapter.dart';
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
import 'package:go_router/go_router.dart';

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

  Widget _buildMenuButton(
      BuildContext context, String title, IconData icon, String routePath) {
    final bool enabled = _loggedInUser != null;
    return InkWell(
      onTap: enabled
          ? () {
              context.push(routePath, extra: _loggedInUser);
            }
          : null,
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: enabled ? null : Colors.grey),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: enabled ? null : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedInUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Seleccione Usuario'),
        ),
        body: SingleChildScrollView(
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
        title: Text('Menú Principal - ${_loggedInUser!['name']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              setState(() {
                _loggedInUser = null;
                _logoutTimer?.cancel();
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuButton(context, 'Tareas', Icons.task_alt, '/tasks'),
            _buildMenuButton(context, 'Caja', Icons.point_of_sale, '/cash'),
            _buildMenuButton(context, 'Propinas', Icons.attach_money, '/tips'),
            _buildMenuButton(context, 'Encuestas', Icons.poll, '/surveys'),
            _buildMenuButton(context, 'Turnos', Icons.schedule, '/shifts'),
            if (_loggedInUser!['role'] == 'Admin')
              _buildMenuButton(
                  context, 'Gestionar Empleados', Icons.people, '/employees'),
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
