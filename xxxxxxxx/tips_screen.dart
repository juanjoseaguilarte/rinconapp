import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_propinas/models/employee.dart';
import 'package:gestion_propinas/services/Databases/employee_database_service.dart';
import 'package:gestion_propinas/services/Databases/tip_database_service.dart';

class TipsSummaryScreen extends StatefulWidget {
  const TipsSummaryScreen({Key? key}) : super(key: key);

  @override
  _TipsSummaryScreenState createState() => _TipsSummaryScreenState();
}

class _TipsSummaryScreenState extends State<TipsSummaryScreen> {
  final TipDatabaseService _tipService = TipDatabaseService();
  final EmployeeDatabaseService _employeeService = EmployeeDatabaseService();

  DateTime? selectedMonday;
  Map<String, double> weeklyTipsSummary = {};
  List<Employee> employees = [];

  @override
  void initState() {
    super.initState();
    selectedMonday = _getNearestMonday(DateTime.now());
    _loadEmployees();
    _loadWeeklyTips();
  }

  DateTime _getNearestMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  Future<void> _selectMonday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonday!,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      selectableDayPredicate: (DateTime date) {
        return date.weekday == DateTime.monday;
      },
    );

    if (picked != null && picked != selectedMonday) {
      setState(() {
        selectedMonday = picked;
      });
      _loadWeeklyTips();
    }
  }

  Future<void> _loadEmployees() async {
    employees = await _employeeService.fetchEmployees();
  }

  Future<void> _loadWeeklyTips() async {
    if (selectedMonday == null) return;

    DateTime startOfWeek = selectedMonday!;
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    // Fetch tips for the selected week
    final tips = await _tipService.fetchTipsForWeek(startOfWeek, endOfWeek);

    // Reset weekly summary
    Map<String, double> summary = {};

    for (var tip in tips) {
      for (var employeeId in tip.employeePayments.keys) {
        double amountPerEmployee = tip.amount / tip.employeePayments.length;
        summary[employeeId] = (summary[employeeId] ?? 0) + amountPerEmployee;
      }
    }

    setState(() {
      weeklyTipsSummary = summary;
    });
  }

  String _getEmployeeName(String employeeId) {
    final employee = employees.firstWhere(
      (emp) => emp.id == employeeId,
      orElse: () => Employee(id: '', name: 'Desconocido', pin: 0, role: ''),
    );
    return employee.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Propinas Semanal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectMonday(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Semana de: ${DateFormat('dd/MM/yyyy').format(selectedMonday!)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            weeklyTipsSummary.isEmpty
                ? const Center(child: Text('No hay propinas registradas para esta semana.'))
                : Expanded(
                    child: ListView.builder(
                      itemCount: weeklyTipsSummary.length,
                      itemBuilder: (context, index) {
                        String employeeId = weeklyTipsSummary.keys.elementAt(index);
                        double totalTip = weeklyTipsSummary[employeeId]!;
                        String employeeName = _getEmployeeName(employeeId);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(
                              employeeName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Propina acumulada: \$${totalTip.toStringAsFixed(2)}'),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}