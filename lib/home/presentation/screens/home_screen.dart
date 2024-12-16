import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/presentation/screens/cash_menu_screen.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/admin/presentation/screens/admin_screen.dart';
import 'package:gestion_propinas/task/application/services/task_service.dart';
import 'package:gestion_propinas/task/presentation/screens/add_task_screen.dart';
import 'package:gestion_propinas/task/presentation/screens/task_screen.dart'; // Importar TaskScreen
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_options_screen.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class HomeScreen extends StatefulWidget {
  final EmployeeService employeeService;
  final TipRepository tipRepository;
  final TaskService taskService;

  const HomeScreen({
    Key? key,
    required this.employeeService,
    required this.tipRepository,
    required this.taskService,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _pinController = TextEditingController();
  late final EmployeeService employeeService;
  late final TipRepository tipRepository;

  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic>? _loggedInUser;
  Timer? _logoutTimer;

  @override
  void initState() {
    super.initState();
    employeeService = widget.employeeService;
    tipRepository = widget.tipRepository;
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = await employeeService.getAllEmployees();
    setState(() {
      _employees = employees
          .map((e) => {'id': e.id, 'name': e.name, 'role': e.role})
          .toList();
    });
  }

  void _printTest() async {
    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);

      final PosPrintResult res =
          await printer.connect('192.168.1.100', port: 9100);

      if (res == PosPrintResult.success) {
        printer.text('Hola, esta es una prueba de impresión',
            styles: PosStyles(align: PosAlign.center));
        printer.feed(2); // Alimentar 2 líneas
        printer.cut();
        printer.disconnect();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impresión completada con éxito')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al conectar: ${res.msg}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al imprimir: $e')),
      );
    }
  }

  void _startLogoutTimer() {
    _logoutTimer?.cancel();
    _logoutTimer = Timer(const Duration(seconds: 15), () {
      setState(() {
        _loggedInUser = null;
      });
    });
  }

  Future<void> _showPinDialog(Map<String, dynamic> user) async {
    setState(() {
      _loggedInUser = null;
    });

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
              final isValid = await _authenticateUser(user['id'], pin);
              Navigator.of(context).pop();
              _pinController.clear();
              if (isValid) {
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

  Future<bool> _authenticateUser(String userId, int pin) async {
    final employee = await employeeService.getEmployeeByPin(pin);
    return employee != null && employee.id == userId;
  }

  Widget _buildEmployeeSelection() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _employees.map((user) {
        return GestureDetector(
          onTap: () => _showPinDialog(user),
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
            child: Center(
              child: Text(
                user['name'],
                style: const TextStyle(fontSize: 14),
              ),
            ),
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
                    builder: (context) =>
                        CashMenuScreen(loggedUser: _loggedInUser!),
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
                    builder: (context) => TaskScreen(
                      userId: _loggedInUser!['id'],
                      getUserTasks: widget.taskService
                          .getTasksForUser, // Pasa la función correcta
                      updateTaskStatus: widget.taskService
                          .updateTaskStatus, // Pasa la función correcta
                    ),
                  ),
                );
              },
              child: const Text('Tareas'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskScreen(
                      addTask: widget.taskService.addTask,
                      fetchEmployees:
                          employeeService.getAllEmployees, // Nueva función
                    ),
                  ),
                );
              },
              child: const Text('Agregar Tarea'),
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
