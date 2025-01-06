import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';

class TipAdminScreen extends StatefulWidget {
  final TipRepository tipRepository;
  final EmployeeService employeeService;

  const TipAdminScreen({
    super.key,
    required this.tipRepository,
    required this.employeeService,
  });

  @override
  _TipAdminScreenState createState() => _TipAdminScreenState();
}

class _TipAdminScreenState extends State<TipAdminScreen> {
  double _totalPendingTips = 0.0;
  double _totalAccumulatedTips = 0.0;
  Map<String, List<Map<String, dynamic>>> _userPendingTips = {};
  Map<String, double> _userTipHistory = {};
  Map<String, String> _employeeNames = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeNames();
    _loadPendingTips();
    _loadTipHistory();
  }

  Future<void> _loadEmployeeNames() async {
    try {
      final employees = await widget.employeeService.getAllEmployees();
      setState(() {
        _employeeNames = {
          for (var employee in employees) employee.id: employee.name
        };
      });
    } catch (e) {
      print('Error al cargar nombres de empleados: $e');
    }
  }

  Future<void> _loadPendingTips() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tips = await widget.tipRepository.fetchTips();
      print('Propinas obtenidas: $tips');

      double totalPending = 0.0;
      final Map<String, List<Map<String, dynamic>>> userPendingTips = {};

      for (var tip in tips) {
        tip.employeePayments.forEach((employeeId, paymentDetails) {
          final isDeleted = paymentDetails['isDeleted'] ?? false;
          if (!isDeleted) {
            final cash = (paymentDetails['cash'] as num?)?.toDouble() ?? 0.0;
            final card = (paymentDetails['card'] as num?)?.toDouble() ?? 0.0;
            final amount = cash + card;

            totalPending += amount;

            if (!userPendingTips.containsKey(employeeId)) {
              userPendingTips[employeeId] = [];
            }
            userPendingTips[employeeId]!.add({
              'tip': tip,
              'amount': amount,
            });
          }
        });
      }

      print('Propinas agrupadas por usuario: $userPendingTips');
      print('Total de propinas pendientes: $totalPending');

      setState(() {
        _totalPendingTips = totalPending;
        _userPendingTips = userPendingTips;
      });
    } catch (e) {
      print('Error al cargar propinas pendientes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTipHistory() async {
    try {
      final tips = await widget.tipRepository.fetchTips();

      double totalAccumulated = 0.0;
      final Map<String, double> userTipHistory = {};
      for (var tip in tips) {
        tip.employeePayments.forEach((employeeId, paymentDetails) {
          final cash = (paymentDetails['cash'] as num?)?.toDouble() ?? 0.0;
          final card = (paymentDetails['card'] as num?)?.toDouble() ?? 0.0;
          final amount = cash + card;

          totalAccumulated += amount;
          userTipHistory[employeeId] =
              (userTipHistory[employeeId] ?? 0) + amount;
        });
      }

      print('Historial acumulado de propinas: $userTipHistory');

      setState(() {
        _totalAccumulatedTips = totalAccumulated;
        _userTipHistory = userTipHistory;
      });
    } catch (e) {
      print('Error al cargar historial de propinas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propinas por Empleado'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Propinas Pendientes: €${_totalPendingTips.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total Propinas Acumuladas: €${_totalAccumulatedTips.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: _userPendingTips.entries.map((entry) {
                        final employeeId = entry.key;
                        final tips = entry.value;
                        final employeeName =
                            _employeeNames[employeeId] ?? 'Sin Nombre';
                        final accumulated =
                            _userTipHistory[employeeId] ?? 0.0;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Empleado: $employeeName',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Propinas Acumuladas: €${accumulated.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}