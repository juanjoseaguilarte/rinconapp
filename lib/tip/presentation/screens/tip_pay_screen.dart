import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';

class TipPayScreen extends StatefulWidget {
  final TipRepository tipRepository;
  final EmployeeService employeeService;
  final Map<String, dynamic> loggedUser;

  const TipPayScreen({
    Key? key,
    required this.tipRepository,
    required this.employeeService,
    required this.loggedUser,
  }) : super(key: key);

  @override
  _TipPayScreenState createState() => _TipPayScreenState();
}

class _TipPayScreenState extends State<TipPayScreen> {
  DateTime? _selectedMonday;
  Map<String, double> _employeeTips = {};
  Map<String, String> _employeeNames = {};
  bool _isLoading = false;
  late String? _currentUserRole;

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
      _currentUserRole = widget.loggedUser['role'];
    });

    await _calculateEmployeeTips(monday);
    setState(() {
      _isLoading = false;
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lunes seleccionado: ${pickedDate.toLocal()}'),
        ),
      );
      await _calculateEmployeeTips(pickedDate);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateEmployeeTips(DateTime monday) async {
    try {
      final sunday = monday.add(const Duration(days: 6));
      final startOfMonday = DateTime(monday.year, monday.month, monday.day);
      final endOfSunday =
          DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

      final tips = await widget.tipRepository.fetchTips();
      final employees = await widget.employeeService.getAllEmployees();

      final adminEmployee = employees.firstWhere((e) => e.role == 'Admin');
      final adminId = adminEmployee.id;
      final loggedUserId = widget.loggedUser['id'];

      final weeklyTips = tips.where((tip) {
        final tipDate = tip.date;
        return tipDate != null &&
            tipDate
                .isAfter(startOfMonday.subtract(const Duration(seconds: 1))) &&
            tipDate.isBefore(endOfSunday.add(const Duration(seconds: 1)));
      }).toList();

      final Map<String, double> employeeTotals = {};
      for (var tip in weeklyTips) {
        // Calcular propinas del administrador basadas en isDeleted
        if (loggedUserId == adminId && !tip.isDeleted) {
          employeeTotals[adminId] =
              (employeeTotals[adminId] ?? 0) + tip.adminShare;
        }

        // Calcular propinas de camareros ignorando isDeleted
        tip.employeePayments.forEach((employeeId, paymentDetails) {
          if (employeeId != adminId && !(paymentDetails['isDeleted'])) {
            final cash = (paymentDetails['cash'] as num?)?.toDouble() ?? 0.0;
            final card = (paymentDetails['card'] as num?)?.toDouble() ?? 0.0;
            employeeTotals[employeeId] =
                (employeeTotals[employeeId] ?? 0) + cash + card;
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
    } catch (e) {
      print('Error al calcular propinas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al calcular propinas')),
        );
      }
    }
  }

  Future<void> _payTipForEmployee(String employeeId) async {
    try {
      final tips = await widget.tipRepository.fetchTips();

      for (var tip in tips) {
        if (tip.employeePayments.containsKey(employeeId)) {
          final updatedPayments = Map.of(tip.employeePayments);

          if (!(updatedPayments[employeeId]?['isDeleted'] ?? false)) {
            updatedPayments[employeeId]?['isDeleted'] = true;

            final updatedTip = tip.copyWith(employeePayments: updatedPayments);
            await widget.tipRepository.updateTip(updatedTip);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Propina pagada exitosamente a ${_employeeNames[employeeId]}')),
      );

      setState(() {
        _employeeTips.remove(employeeId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al pagar la propina: $e')),
      );
    }
  }

  Future<void> markAllTipsAsUnpaid() async {
    try {
      final tips = await widget.tipRepository.fetchTips();

      for (var tip in tips) {
        final updatedPayments = Map.of(tip.employeePayments);
        updatedPayments.forEach((employeeId, paymentDetails) {
          paymentDetails['isDeleted'] = false;
        });

        final updatedTip = tip.copyWith(employeePayments: updatedPayments);
        await widget.tipRepository.updateTip(updatedTip);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Todas las propinas han sido marcadas como no pagadas.')),
      );
    } catch (e) {
      print('Error al marcar todas las propinas como no pagadas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error al marcar las propinas como no pagadas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = _selectedMonday;
    final endDate = startDate?.add(const Duration(days: 6));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar Todas Las Propinas'),
        actions: [
          if (_currentUserRole == 'Admin' || _currentUserRole == 'Encargado')
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.loggedUser['role'] == "Admin")
              ElevatedButton(
                onPressed: markAllTipsAsUnpaid,
                child: const Text('Restablecer Propinas'),
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
                        subtitle: Text('Total: €${amount.toStringAsFixed(2)}'),
                        trailing: ElevatedButton(
                          onPressed: _currentUserRole == 'Admin'
                              ? () => _payTipForEmployee(employeeId)
                              : null, // Deshabilitar si no es Admin
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
    );
  }
}
