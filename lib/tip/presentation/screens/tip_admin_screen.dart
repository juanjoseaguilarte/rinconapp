import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_list_screen.dart';

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
  final String _employeeId = "LWFwojdvqZCuppnPB9Be";
  double _totalTips = 0.0;
  Map<DateTime, List<Map<String, dynamic>>> _weeklyTips = {};
  Map<String, double> _userTipHistory = {};
  Map<String, String> _employeeNames = {}; // Mapeo de IDs a nombres
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeNames();
    _loadEmployeeTips();
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

  Future<void> _loadEmployeeTips() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tips = await widget.tipRepository.fetchTips();

      double total = 0.0;
      final Map<DateTime, List<Map<String, dynamic>>> weeklyTips = {};

      for (var tip in tips) {
        if (!tip.employeePayments.containsKey(_employeeId)) continue;

        final paymentDetails = tip.employeePayments[_employeeId]!;
        final isDeleted = paymentDetails['isDeleted'] ?? false;
        final amount = paymentDetails['amount'] ?? 0.0;

        // Solo suma las propinas no pagadas al total
        if (!isDeleted) {
          total += amount;

          // Agrupar por semana
          final monday = _getStartOfWeek(tip.date);
          if (!weeklyTips.containsKey(monday)) {
            weeklyTips[monday] = [];
          }
          weeklyTips[monday]!.add({
            'tip': tip,
            'amount': amount,
            'isDeleted': isDeleted,
          });
        }
      }

      // Filtrar semanas con todas las propinas pagadas
      final filteredWeeklyTips = Map.fromEntries(
        weeklyTips.entries
            .where((entry) => entry.value.any((tip) => !tip['isDeleted'])),
      );

      setState(() {
        _totalTips = total;
        _weeklyTips = filteredWeeklyTips;
      });
    } catch (e) {
      print('Error al cargar propinas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar propinas')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTipHistory() async {
    try {
      final tips = await widget.tipRepository.fetchTips();

      final Map<String, double> userTipHistory = {};
      for (var tip in tips) {
        tip.employeePayments.forEach((employeeId, paymentDetails) {
          final amount = paymentDetails['amount'] ?? 0.0;
          userTipHistory[employeeId] =
              (userTipHistory[employeeId] ?? 0) + amount;
        });
      }

      setState(() {
        _userTipHistory = userTipHistory;
      });
    } catch (e) {
      print('Error al cargar historial de propinas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar historial')),
        );
      }
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  Future<void> _payTip(Map<String, dynamic> tipDetails) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: Text(
            '¿Estás seguro de que deseas pagar esta propina de \$${tipDetails['amount'].toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Cierra el modal

              try {
                final tip = tipDetails['tip'];

                final updatedPayments =
                    (tip.employeePayments as Map<dynamic, dynamic>).map(
                  (key, value) => MapEntry(
                    key.toString(),
                    Map<String, dynamic>.from(value as Map<dynamic, dynamic>),
                  ),
                );

                updatedPayments[_employeeId]?['isDeleted'] = true;

                final updatedTip =
                    tip.copyWith(employeePayments: updatedPayments);
                await widget.tipRepository.updateTip(updatedTip);

                setState(() {
                  _weeklyTips[_getStartOfWeek(tip.date)]!.remove(tipDetails);
                  _totalTips -= tipDetails['amount'];
                });

                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Pago realizado exitosamente')),
                );
              } catch (e) {
                print('Error al pagar la propina: $e');
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Error al realizar el pago')),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propinas por Empleado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Propinas Pendientes: €${_totalTips.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: _weeklyTips.entries.map((entry) {
                        final monday = entry.key;
                        final tips = entry.value;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Semana: ${monday.year}-${monday.month}-${monday.day} a ${monday.add(const Duration(days: 6)).year}-${monday.add(const Duration(days: 6)).month}-${monday.add(const Duration(days: 6)).day}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ...tips.map((tipDetails) {
                                  if (tipDetails['isDeleted'])
                                    return SizedBox.shrink();

                                  return ListTile(
                                    title: Text(
                                      'Propina: €${tipDetails['amount'].toStringAsFixed(2)}',
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () => _payTip(tipDetails),
                                      child: const Text('Pagar'),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Historial de Propinas Acumuladas',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: _userTipHistory.entries.map((entry) {
                        final employeeId = entry.key;
                        final amount = entry.value;
                        final employeeName =
                            _employeeNames[employeeId] ?? 'Sin Nombre';
                        return ListTile(
                          title: Text('Empleado: $employeeName'),
                          subtitle: Text(
                              'Propinas Acumuladas: €${amount.toStringAsFixed(2)}'),
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final tips = await widget.tipRepository.fetchTips();
                      // Navegar a la pantalla de listado
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TipListScreen(
                            tipRepository: widget.tipRepository,
                            employeeService: widget.employeeService,
                          ),
                        ),
                      );
                    },
                    child: const Text('Listado de Propinas'),
                  ),
                ],
              ),
      ),
    );
  }
}
