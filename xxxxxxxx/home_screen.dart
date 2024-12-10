// home_screen.dart
import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/screens/admin/admin_screen.dart';
import 'package:gestion_propinas/screens/tips/tips_screen.dart';

class HomeScreen extends StatefulWidget {
  final EmployeeService employeeService;

  const HomeScreen({Key? key, required this.employeeService}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showPinDialog(String option) {
    final TextEditingController _pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingrese su PIN'),
        content: TextField(
          controller: _pinController,
          decoration: const InputDecoration(hintText: 'PIN'),
          keyboardType: TextInputType.number,
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = int.tryParse(_pinController.text) ?? -1;
              final employee =
                  await widget.employeeService.authenticateEmployee(pin);
              if (employee != null) {
                Navigator.of(context).pop();
                _navigateToOptionScreen(option, employee);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('PIN incorrecto o usuario no encontrado')),
                );
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _navigateToOptionScreen(String option, Employee employee) {
    Widget? screen;
    switch (option) {
      case 'Usuarios':
        if (employee.role == 'Admin') {
          screen = UsersScreen(employee: employee);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tienes permiso para acceder a esta sección'),
            ),
          );
        }
        break;
      case 'Propinas':
        screen = TipsScreen(employee: employee);
        break;
      case 'Fichajes':
        screen = CheckInScreen(employee: employee);
        break;
      case 'Limpieza':
        screen = CleaningScreen(employee: employee);
        break;
      case 'Admin':
        screen = const AdminScreen();
        break;
      default:
        screen = UsersScreen(employee: employee);
    }

    if (screen != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => screen!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menú Principal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20.0,
          mainAxisSpacing: 20.0,
          childAspectRatio: 1.0,
          children: [
            _buildMenuButton('Usuarios', 'Usuarios'),
            _buildMenuButton('Propinas', 'Propinas'),
            _buildMenuButton('Fichajes', 'Fichajes'),
            _buildMenuButton('Limpieza', 'Limpieza'),
            _buildMenuButton('Admin', 'Admin'),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(String label, String option) {
    return ElevatedButton(
      onPressed: () => _showPinDialog(option),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(100, 100),
        backgroundColor: const Color.fromARGB(255, 26, 53, 74),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }
}
