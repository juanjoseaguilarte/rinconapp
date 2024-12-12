import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_create_screen.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_list_screen.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_pay_screen.dart';
import 'package:gestion_propinas/tip/presentation/screens/individual_tip_pay_screen.dart';

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
      widget.employeeService.getAllEmployees().then(
            (employees) => employees.cast<Employee>(),
          ),
    ]).then((data) {
      print('Datos cargados correctamente.');
      print('Tips: ${data[0]}');
      print('Empleados: ${data[1]}');
      return data;
    }).catchError((error) {
      print('Error cargando datos: $error');
      throw error;
    });
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
            print('Cargando datos...');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error detectado: ${snapshot.error}');
            return const Center(child: Text('Error en la carga de datos.'));
          }

          if (!snapshot.hasData || snapshot.data is! List) {
            print('Datos inválidos o no disponibles.');
            return const Center(child: Text('Error en la carga de datos.'));
          }

          final List<Tip> tips = snapshot.data![0] as List<Tip>;
          final employees = snapshot.data![1];

          print('Cantidad de Tips cargados: ${tips.length}');
          print('Cantidad de Empleados cargados: ${employees.length}');

          final employeesWithPendingTips =
              _getEmployeesWithPendingTips(tips, employees);

          if (employeesWithPendingTips.isEmpty) {
            print('Todas las propinas están pagadas.');
            return const Center(
              child: Text(
                'Actualmente están todas las propinas pagadas, no hay pendientes.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            );
          }

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
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirmación'),
                          content: const Text(
                            'Una vez dentro, las propinas se pagarán automáticamente y no podrás regresar. ¿Deseas continuar?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Cierra el modal
                              },
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Cierra el modal
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
                              child: const Text('Aceptar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: buttonStyle,
                  child: const Text(
                    'Pagar Todas Las Propinas',
                    textAlign: TextAlign.center,
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.loggedUser['role'] == 'Admin'
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TipListScreen(
                                tipRepository: widget.tipRepository,
                                employeeService: widget.employeeService,
                              ),
                            ),
                          );
                        }
                      : null, // Deshabilitar el botón si no es Admin
                  style: buttonStyle,
                  child: const Text('Listado de Propinas'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getEmployeesWithPendingTips(
      List<Tip> tips, List<Employee> employees) {
    final Map<String, double> employeeTotals = {};

    for (var tip in tips) {
      // Debugging: imprimir el ID del tip y sus pagos
      print('Tip ID: ${tip.id}, Employee Payments: ${tip.employeePayments}');

      tip.employeePayments.forEach((employeeId, paymentDetails) {
        // Debugging: imprimir detalles de cada empleado
        print('Empleado ID: $employeeId, Detalles del Pago: $paymentDetails');

        final cash = (paymentDetails['cash'] as num?)?.toDouble() ?? 0.0;
        final card = (paymentDetails['card'] as num?)?.toDouble() ?? 0.0;

        if (!(paymentDetails['isDeleted'] ?? false)) {
          employeeTotals[employeeId] =
              (employeeTotals[employeeId] ?? 0.0) + cash + card;
        }
      });
    }

    final Map<String, String> employeeNames = {
      for (var employee in employees) employee.id: employee.name,
    };

    // Debugging: imprimir los totales calculados
    print('Totales de propinas por empleado: $employeeTotals');
    print('Nombres de empleados: $employeeNames');

    return employeeTotals.entries
        .map((entry) => {
              'id': entry.key,
              'amount': entry.value,
              'name': employeeNames[entry.key] ?? 'Desconocido',
            })
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
                                employeeService: widget.employeeService,
                                reloadData: _loadData,
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
