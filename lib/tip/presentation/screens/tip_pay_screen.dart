import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';

class TipPayScreen extends StatefulWidget {
  final TipRepository tipRepository;
  final EmployeeService employeeService;

  const TipPayScreen({
    Key? key,
    required this.tipRepository,
    required this.employeeService,
  }) : super(key: key);

  @override
  _TipPayScreenState createState() => _TipPayScreenState();
}

class _TipPayScreenState extends State<TipPayScreen> {
  DateTime? _selectedMonday;
  Map<String, double> _employeeTips = {};
  Map<String, String> _employeeNames = {};
  bool _isLoading = false;

  DateTime _getNearestMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final monday = _getNearestMonday(DateTime.now());
    setState(() {
      _selectedMonday = monday;
      _isLoading = true;
    });
    print('Lunes seleccionado: $_selectedMonday');
    await _loadTipsForSelectedMonday();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadTipsForSelectedMonday() async {
    if (_selectedMonday == null) return;
    print('Cargando propinas para: $_selectedMonday');
    await _calculateEmployeeTips(_selectedMonday!);
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedMonday ?? _getNearestMonday(DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      selectableDayPredicate: (date) => date.weekday == DateTime.monday,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedMonday = pickedDate;
        _isLoading = true;
      });
      print('Nuevo lunes seleccionado: $_selectedMonday');
      await _calculateEmployeeTips(pickedDate);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateEmployeeTips(DateTime monday) async {
    try {
      final sunday = monday.add(const Duration(days: 6));
      print('Calculando propinas desde $monday hasta $sunday');

      // Truncar lunes y domingo al inicio del día
      final startOfMonday = DateTime(monday.year, monday.month, monday.day);
      final endOfSunday =
          DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

      final tips = await widget.tipRepository.fetchTips();
      final employees = await widget.employeeService.getAllEmployees();

      // Encuentra el ID del administrador
      final adminEmployee =
          employees.firstWhere((employee) => employee.role == 'Admin');

      final adminId = adminEmployee?.id;

      print('Propinas obtenidas de fetchTips: ${tips.length}');

      final weeklyTips = tips.where((tip) {
        final tipDate = tip.date;
        // Comparar solo las fechas truncadas y excluir las propinas del Admin
        final inRange = tipDate != null &&
            tipDate
                .isAfter(startOfMonday.subtract(const Duration(seconds: 1))) &&
            tipDate.isBefore(endOfSunday.add(const Duration(seconds: 1))) &&
            !tip.isDeleted;

        if (!inRange) {
          print(
              'Propina fuera de rango: Fecha=${tip.date}, Eliminada=${tip.isDeleted}');
        }

        return inRange;
      }).toList();

      print('Propinas en rango: ${weeklyTips.length}');

      final Map<String, double> employeeTotals = {};
      for (var tip in weeklyTips) {
        tip.employeePayments.forEach((employeeId, paymentDetails) {
          if (!(paymentDetails['isDeleted'] ?? false) &&
              employeeId != adminId) {
            // Excluir propinas del Admin
            final amount =
                (paymentDetails['amount'] as num?)?.toDouble() ?? 0.0;
            employeeTotals[employeeId] =
                (employeeTotals[employeeId] ?? 0) + amount;
          }
        });
      }

      final Map<String, String> names = {
        for (var employee in employees) employee.id: employee.name
      };

      setState(() {
        _employeeTips = employeeTotals;
        _employeeNames = names;
      });
      print('Propinas calculadas: $_employeeTips');
    } catch (e) {
      print('Error al calcular propinas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al calcular propinas')),
        );
      }
    }
  }

  Future<void> _payTips(String employeeId, double amount) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: Text(
            '¿Estás seguro de que deseas pagar \$${amount.toStringAsFixed(2)} a este empleado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Cierra el modal

              try {
                final tips = await widget.tipRepository.fetchTips();
                for (var tip in tips) {
                  if (tip.employeePayments.containsKey(employeeId)) {
                    final updatedPayments = Map.of(tip.employeePayments);

                    // Marca como pagado para el empleado
                    updatedPayments[employeeId]?['isDeleted'] = true;

                    // Actualiza la propina
                    final updatedTip = tip.copyWith(
                      employeePayments: updatedPayments,
                    );
                    await widget.tipRepository.updateTip(updatedTip);
                  }
                }

                setState(() {
                  _employeeTips.remove(employeeId);
                });

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pago realizado a empleado ${_employeeNames[employeeId] ?? 'Sin Nombre'}',
                    ),
                  ),
                );
              } catch (e) {
                print('Error al realizar el pago: $e');
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

  Future<bool> _onWillPop() async {
    if (_employeeTips.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Atención'),
          content: const Text(
              'Aún quedan propinas pendientes por pagar. Si sales ahora, se procederá a pagar todas las propinas automáticamente (excepto Admin). ¿Deseas continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, true);
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _payAllRemainingTips();
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  Future<void> _payAllRemainingTips() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final tips = await widget.tipRepository.fetchTips();
      final employees = await widget.employeeService.getAllEmployees();

      // Encuentra el ID del empleado con rol de "Admin"
      final adminEmployee = employees.firstWhere(
        (employee) => employee.role == 'Admin',
      );

      final adminId = adminEmployee?.id;

      for (var tip in tips) {
        bool updated = false;
        final updatedPayments = Map.of(tip.employeePayments);

        updatedPayments.forEach((employeeId, paymentDetails) {
          // Excluye al empleado "Admin" y marca como pagado solo a otros
          if ((paymentDetails['isDeleted'] == false ||
                  paymentDetails['isDeleted'] == null) &&
              employeeId != adminId) {
            updatedPayments[employeeId]?['isDeleted'] = true;
            updated = true;
          }
        });

        if (updated) {
          final updatedTip = tip.copyWith(employeePayments: updatedPayments);
          await widget.tipRepository.updateTip(updatedTip);
        }
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Text('Se han pagado todas las propinas pendientes.')),
      );
    } catch (e) {
      print('Error al pagar todas las propinas: $e');
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Error al pagar todas las propinas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = _selectedMonday;
    final endDate = startDate?.add(const Duration(days: 6));

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pagar Todas Las Propinas'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: const Text('Seleccionar Lunes'),
              ),
              if (startDate != null && endDate != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Propinas desde ${startDate.year}-${startDate.month}-${startDate.day} '
                    'hasta ${endDate.year}-${endDate.month}-${endDate.day}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_employeeTips.isEmpty)
                const Center(
                  child: Text(
                    'No hay propinas para la semana seleccionada',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _employeeTips.length,
                    itemBuilder: (context, index) {
                      final employeeId = _employeeTips.keys.elementAt(index);
                      final amount = _employeeTips[employeeId]!;
                      final employeeName =
                          _employeeNames[employeeId] ?? 'Sin Nombre';

                      return Card(
                        child: ListTile(
                          title: Text('Empleado: $employeeName'),
                          subtitle:
                              Text('Total: €${amount.toStringAsFixed(2)}'),
                          trailing: ElevatedButton(
                            onPressed: () => _payTips(employeeId, amount),
                            child: const Text('Pagar'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
