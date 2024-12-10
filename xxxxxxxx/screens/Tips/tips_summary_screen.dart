import 'package:flutter/material.dart';
import 'package:gestion_propinas/services/Databases/tip_database_service.dart';
import 'package:gestion_propinas/services/Databases/employee_database_service.dart';

class TipsSummaryScreen extends StatefulWidget {
  const TipsSummaryScreen({Key? key}) : super(key: key);

  @override
  _TipsSummaryScreenState createState() => _TipsSummaryScreenState();
}

class _TipsSummaryScreenState extends State<TipsSummaryScreen> {
  final TipDatabaseService _tipService = TipDatabaseService();
  final EmployeeDatabaseService _employeeService = EmployeeDatabaseService();
  DateTime? _selectedMonday;
  Map<String, double> _weeklyTipsByEmployee = {};

  @override
  void initState() {
    super.initState();
    _selectedMonday = _getNearestMonday(DateTime.now());
    _loadWeeklyTips();
  }

  DateTime _getNearestMonday(DateTime date) {
    return date.subtract(Duration(days: (date.weekday - DateTime.monday) % 7));
  }

  Future<void> _selectMonday(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonday!,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      selectableDayPredicate: (date) => date.weekday == DateTime.monday,
    );
    if (picked != null) {
      setState(() {
        _selectedMonday = picked;
      });
      _loadWeeklyTips();
    }
  }

  Future<void> _loadWeeklyTips() async {
    if (_selectedMonday == null) return;
    final endOfWeek = _selectedMonday!.add(Duration(days: 6));

    final tips =
        await _tipService.fetchTipsForWeek(_selectedMonday!, endOfWeek);
    final employees = await _employeeService.fetchEmployees();
    final employeeNames = {for (var e in employees) e.id: e.name};

    final Map<String, double> weeklyTipsByEmployee = {};
    for (var tip in tips) {
      tip.employeePayments.forEach((employeeId, isPaid) {
        if (isPaid == 0) {
          weeklyTipsByEmployee[employeeId] =
              (weeklyTipsByEmployee[employeeId] ?? 0) +
                  tip.amount / tip.employeePayments.length;
        }
      });
    }

    setState(() {
      _weeklyTipsByEmployee = {
        for (var id in weeklyTipsByEmployee.keys)
          employeeNames[id] ?? 'Desconocido': weeklyTipsByEmployee[id]!
      };
    });
  }

  Future<void> _payTipsForEmployee(String employeeId) async {
    if (_selectedMonday == null) return;
    final endOfWeek = _selectedMonday!.add(Duration(days: 6));
    await _tipService.markTipsAsPaidForWeek(
        employeeId, _selectedMonday!, endOfWeek);
    _loadWeeklyTips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Propinas Semanales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectMonday(context),
          ),
        ],
      ),
      body: _weeklyTipsByEmployee.isEmpty
          ? const Center(
              child: Text('No hay propinas registradas para esta semana.'))
          : ListView(
              padding: const EdgeInsets.all(8),
              children: _weeklyTipsByEmployee.entries.map((entry) {
                final employeeName = entry.key;
                final totalTips = entry.value;
                return Card(
                    child: ListTile(
                  title: Text('Empleado: $employeeName'),
                  subtitle:
                      Text('Propina total: \$${totalTips.toStringAsFixed(2)}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final employeeId = await _employeeService
                          .getEmployeeIdByName(employeeName);
                      if (employeeId != null) {
                        await _payTipsForEmployee(employeeId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Propinas pagadas para $employeeName.'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 31, 98, 154), // Color de fondo del botón
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12), // Espaciado del botón
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8), // Bordes redondeados
                      ),
                    ),
                    child: const Text(
                      'Pagar',
                      style: TextStyle(
                        color: Colors.white, // Color de la letra en blanco
                        fontSize: 16, // Tamaño de la fuente
                        fontWeight: FontWeight.bold, // Grosor de la fuente
                      ),
                    ),
                  ),
                ));
              }).toList(),
            ),
    );
  }
}
