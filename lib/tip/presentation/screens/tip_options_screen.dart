import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_create_screen.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_pay_screen.dart';

class TipOptionsScreen extends StatefulWidget {
  final EmployeeService employeeService;
  final TipRepository tipRepository;
  final Map<String, dynamic> loggedUser;

  const TipOptionsScreen({
    Key? key,
    required this.employeeService,
    required this.tipRepository,
    required this.loggedUser,
  }) : super(key: key);

  @override
  _TipOptionsScreenState createState() => _TipOptionsScreenState();
}

class _TipOptionsScreenState extends State<TipOptionsScreen> {
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _dataFuture = Future.wait([
      widget.tipRepository.fetchTips(),
      widget.employeeService.getAllEmployees(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(100, 100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opciones de Propinas'),
      ),
      body: FutureBuilder(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data is! List) {
            return const Center(child: Text('Error al cargar datos.'));
          }

          final List<Tip> tips = snapshot.data![0] as List<Tip>;
          final employees = snapshot.data![1];

          final employeesWithPendingTips =
              _getEmployeesWithPendingTips(tips, employees);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TipCreateScreen(
                          employeeService: widget.employeeService,
                          tipRepository: widget.tipRepository,
                        ),
                      ),
                    );
                  },
                  style: buttonStyle,
                  child:
                      const Text('Añadir Propina', textAlign: TextAlign.center),
                ),
                ElevatedButton(
                  onPressed: employeesWithPendingTips.isNotEmpty
                      ? () => _showEmployeeSelectionModal(
                          context, employeesWithPendingTips)
                      : null,
                  style: buttonStyle,
                  child: const Text(
                    'Pagar Propina Individual',
                    textAlign: TextAlign.center,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TipPayScreen(
                          tipRepository: widget.tipRepository,
                          employeeService: widget.employeeService,
                        ),
                      ),
                    );
                  },
                  style: buttonStyle,
                  child: const Text(
                    'Pagar Todas Las Propinas',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getEmployeesWithPendingTips(
      List<Tip> tips, List employees) {
    final Map<String, double> employeeTotals = {};

    for (var tip in tips) {
      tip.employeePayments.forEach((employeeId, paymentDetails) {
        if (!(paymentDetails['isDeleted'] ?? false)) {
          final amount = (paymentDetails['amount'] as num?)?.toDouble() ?? 0.0;
          employeeTotals[employeeId] =
              (employeeTotals[employeeId] ?? 0.0) + amount;
        }
      });
    }

    final Map<String, String> employeeNames = {
      for (var employee in employees) employee.id: employee.name,
    };

    final List<Map<String, dynamic>> filteredEmployees = employeeTotals.entries
        .where((entry) => employeeNames[entry.key] != null)
        .map((entry) => {
              'id': entry.key,
              'amount': entry.value,
              'name': employeeNames[entry.key] ?? 'Desconocido',
            })
        .toList();

    return filteredEmployees
        .where((employee) =>
            employees.any((e) => e.id == employee['id'] && e.role != 'Admin'))
        .toList();
  }

  void _showEmployeeSelectionModal(
      BuildContext context, List<Map<String, dynamic>> employees) {
    String? selectedEmployeeId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Seleccionar Camarero'),
              content: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Selecciona un camarero'),
                value: selectedEmployeeId,
                onChanged: (value) {
                  setState(() {
                    selectedEmployeeId = value;
                  });
                },
                items: employees.map((employee) {
                  return DropdownMenuItem(
                    value: employee['id'] as String,
                    child: Text(employee['name'] as String),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedEmployeeId != null
                      ? () {
                          Navigator.pop(context);

                          final employee = employees.firstWhere(
                            (e) => e['id'] == selectedEmployeeId,
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IndividualTipPayScreen(
                                employeeName: employee['name'] as String,
                                amount: employee['amount'] as double,
                                employeeId: employee['id'] as String,
                                tipRepository: widget.tipRepository,
                                reloadData: _loadData, // Agregando recarga
                              ),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class IndividualTipPayScreen extends StatelessWidget {
  final String employeeName;
  final double amount;
  final String employeeId;
  final TipRepository tipRepository;
  final VoidCallback reloadData;

  const IndividualTipPayScreen({
    Key? key,
    required this.employeeName,
    required this.amount,
    required this.employeeId,
    required this.tipRepository,
    required this.reloadData,
  }) : super(key: key);

  Future<void> _payTips(BuildContext context) async {
    try {
      final tips = await tipRepository.fetchTips();

      for (var tip in tips) {
        if (tip.employeePayments.containsKey(employeeId)) {
          final updatedPayments = Map.of(tip.employeePayments);

          if (!(updatedPayments[employeeId]!['isDeleted'] ?? false)) {
            updatedPayments[employeeId]!['isDeleted'] = true;

            final updatedTip = tip.copyWith(employeePayments: updatedPayments);
            await tipRepository.updateTip(updatedTip);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Propina pagada exitosamente a $employeeName')),
      );

      reloadData(); // Recargar datos al finalizar
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al pagar la propina: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pagar Propina a $employeeName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Propina Total: €${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Una vez confirmes, no habrá vuelta atrás. ¿Deseas continuar?',
              style: TextStyle(fontSize: 16),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _payTips(context),
              child: const Text('Confirmar Pago'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
