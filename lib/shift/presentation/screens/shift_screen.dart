import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/shift/application/services/shift_service.dart';
import 'package:gestion_propinas/shift/domain/entities/shift.dart';

class ShiftScreen extends StatefulWidget {
  final Map<String, dynamic> loggedUser;

  const ShiftScreen({Key? key, required this.loggedUser}) : super(key: key);

  @override
  _ShiftScreenState createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final EmployeeService _employeeService = GetIt.instance<EmployeeService>();
  final ShiftService _shiftService = GetIt.instance<ShiftService>();

  late DateTime _currentWeekStart;
  List<DateTime> _weekDates = [];
  List<Employee> _allEmployees = [];
  List<Shift> _shifts = [];
  bool _isLoading = true;
  Map<String, int> _workedShiftsCount = {};
  Map<String, int> _freeShiftsCount = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null).then((_) {
      _currentWeekStart = _getStartOfWeek(DateTime.now());
      _generateWeekDates();
      _loadData();
    });
  }

  DateTime _getStartOfWeek(DateTime date) {
    int daysToSubtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
  }

  void _generateWeekDates() {
    _weekDates = List.generate(
        7, (index) => _currentWeekStart.add(Duration(days: index)));
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final employees = await _employeeService.getAllEmployees();
      final shifts = await _shiftService.getShiftsForWeek(_currentWeekStart);

      if (!mounted) return;
      setState(() {
        _allEmployees = employees;
        _shifts = shifts;
        _calculateShiftCounts();
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
      );
    }
  }

  void _calculateShiftCounts() {
    _workedShiftsCount.clear();
    _freeShiftsCount.clear();
    for (var emp in _allEmployees) {
      _workedShiftsCount[emp.id] = 0;
      _freeShiftsCount[emp.id] = 0;
    }

    final weekShifts = _shifts
        .where((shift) =>
            shift.date
                .isAfter(_currentWeekStart.subtract(const Duration(days: 1))) &&
            shift.date.isBefore(_currentWeekStart.add(const Duration(days: 7))))
        .toList();

    for (var shift in weekShifts) {
      if (_workedShiftsCount.containsKey(shift.employeeId)) {
        if (shift.entryTime == "LIBRE") {
          _freeShiftsCount[shift.employeeId] =
              (_freeShiftsCount[shift.employeeId] ?? 0) + 1;
        } else {
          _workedShiftsCount[shift.employeeId] =
              (_workedShiftsCount[shift.employeeId] ?? 0) + 1;
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Shift? _getShift(String employeeId, DateTime date, ShiftPeriod period) {
    try {
      return _shifts.firstWhere(
        (shift) =>
            shift.employeeId == employeeId &&
            shift.date.year == date.year &&
            shift.date.month == date.month &&
            shift.date.day == date.day &&
            shift.period == period,
      );
    } catch (e) {
      return null;
    }
  }

  String _formatDateHeader(DateTime date) {
    return DateFormat('E d', 'es_ES').format(date);
  }

  void _changeWeek(int days) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: days));
      _generateWeekDates();
      _loadData();
    });
  }

  Future<void> _showEditShiftDialog(
      Employee employee, DateTime date, ShiftPeriod period) async {
    Shift? existingShift = _getShift(employee.id, date, period);
    final cleanDate = DateTime(date.year, date.month, date.day);
    Shift shiftData = existingShift ??
        Shift(
          id: Shift.generateId(employee.id, cleanDate, period),
          employeeId: employee.id,
          employeeName: employee.name,
          date: cleanDate,
          period: period,
          entryTime: "LIBRE",
          isImaginaria: false,
        );

    Shift? result = await showDialog<Shift>(
      context: context,
      builder: (context) => _EditShiftDialogContent(
        initialShift: shiftData,
        employeeName: employee.name,
      ),
    );

    if (result != null) {
      if (result.entryTime.isEmpty) {
        try {
          await _shiftService.deleteShift(employee.id, cleanDate, period);
          _loadData();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar turno: ${e.toString()}')),
          );
        }
      } else {
        try {
          final shiftToSave = result.copyWith(
              id: Shift.generateId(
                  result.employeeId, result.date, result.period),
              date: DateTime(
                  result.date.year, result.date.month, result.date.day));
          await _shiftService.saveShift(shiftToSave);
          _loadData();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar turno: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekStartFormatted =
        DateFormat('d MMM', 'es_ES').format(_currentWeekStart);
    final weekEndFormatted =
        DateFormat('d MMM', 'es_ES').format(_weekDates.last);

    final cocinaEmployees = _allEmployees
        .where((emp) => emp.position.toLowerCase() == 'cocina')
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final salaEmployees = _allEmployees
        .where((emp) => emp.position.toLowerCase() == 'sala')
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Turnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => _changeWeek(-7),
            tooltip: 'Semana Anterior',
          ),
          Expanded(
            child: Center(
              child: Text(
                '$weekStartFormatted - $weekEndFormatted',
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () => _changeWeek(7),
            tooltip: 'Semana Siguiente',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAreaSection("Cocina", cocinaEmployees),
                  const SizedBox(height: 20),
                  _buildAreaSection("Sala", salaEmployees),
                ],
              ),
            ),
    );
  }

  Widget _buildAreaSection(String title, List<Employee> employees) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          employees.isEmpty
              ? Center(child: Text('No hay empleados para el área "$title".'))
              : Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      border: TableBorder.all(color: Colors.grey.shade400),
                      columnSpacing: 5,
                      headingRowHeight: 40,
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 80,
                      headingRowColor: MaterialStateProperty.all(
                          Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                      columns: [
                      const DataColumn(
                          label: SizedBox(
                              width: 130,
                              child: Text('Empleado',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)))),
                      ..._weekDates.map((date) => DataColumn(
                            label: SizedBox(
                                width: 70,
                                child: Center(
                                    child: Text(_formatDateHeader(date),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)))),
                          )),
                    ],
                    rows: employees.map((employee) {
                      return DataRow(cells: [
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          width: 130,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    child: Text(
                                      employee.name.isNotEmpty
                                          ? employee.name[0]
                                          : '?',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      employee.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(
                                        '${_workedShiftsCount[employee.id] ?? 0}'),
                                    backgroundColor: Colors.blue.shade100,
                                    padding: EdgeInsets.zero,
                                    labelPadding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    visualDensity: VisualDensity.compact,
                                    labelStyle: const TextStyle(fontSize: 10),
                                  ),
                                  const SizedBox(width: 4),
                                  Chip(
                                    label: Text(
                                        '${_freeShiftsCount[employee.id] ?? 0}'),
                                    backgroundColor: Colors.green.shade100,
                                    padding: EdgeInsets.zero,
                                    labelPadding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    visualDensity: VisualDensity.compact,
                                    labelStyle: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                        ..._weekDates.map((date) {
                          final shiftManana =
                              _getShift(employee.id, date, ShiftPeriod.manana);
                          final shiftTarde =
                              _getShift(employee.id, date, ShiftPeriod.tarde);
                          return DataCell(SizedBox(
                            width: 70,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildShiftCell(employee, date,
                                    ShiftPeriod.manana, shiftManana),
                                const Divider(
                                    height: 1,
                                    thickness: 1,
                                    indent: 5,
                                    endIndent: 5),
                                _buildShiftCell(employee, date,
                                    ShiftPeriod.tarde, shiftTarde),
                              ],
                            ),
                          ));
                        }),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildShiftCell(
      Employee employee, DateTime date, ShiftPeriod period, Shift? shift) {
    return Expanded(
      child: InkWell(
        onTap: () => _showEditShiftDialog(employee, date, period),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          decoration: BoxDecoration(
            color: shift != null
                ? (shift.entryTime == 'LIBRE'
                    ? Colors.grey.shade200
                    : Colors.green.shade50)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (shift != null) ...[
                Text(
                  shift.entryTime,
                  style:
                      const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                if (shift.isImaginaria)
                  const Text('IMG',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold)),
              ] else ...[
                Icon(Icons.add, size: 16, color: Colors.grey.shade400),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EditShiftDialogContent extends StatefulWidget {
  final Shift initialShift;
  final String employeeName;

  const _EditShiftDialogContent({
    required this.initialShift,
    required this.employeeName,
  });

  @override
  __EditShiftDialogContentState createState() =>
      __EditShiftDialogContentState();
}

class __EditShiftDialogContentState extends State<_EditShiftDialogContent> {
  late Shift _currentShift;

  @override
  void initState() {
    super.initState();
    _currentShift = widget.initialShift;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMMM', 'es_ES');
    return AlertDialog(
      title: Text('Turno - ${widget.employeeName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fecha: ${dateFormat.format(_currentShift.date)}'),
            Text(
                'Periodo: ${_currentShift.period == ShiftPeriod.manana ? 'Mañana' : 'Tarde'}'),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _currentShift.entryTime,
              items: possibleEntryTimes.map((time) {
                return DropdownMenuItem(
                  value: time,
                  child: Text(time),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentShift = _currentShift.copyWith(entryTime: value);
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Horario Entrada',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Switch(
                  value: _currentShift.isImaginaria,
                  onChanged: (value) {
                    setState(() {
                      _currentShift =
                          _currentShift.copyWith(isImaginaria: value);
                    });
                  },
                ),
                const Text('IMAGINARIA'),
              ],
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_currentShift.copyWith(entryTime: ''));
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Eliminar'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(_currentShift);
              },
              child: const Text('Guardar'),
            ),
          ],
        )
      ],
    );
  }
}
