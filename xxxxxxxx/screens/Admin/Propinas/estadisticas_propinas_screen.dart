import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_propinas/services/Databases/tip_database_service.dart';
import 'package:gestion_propinas/services/Databases/employee_database_service.dart';
import 'package:gestion_propinas/models/tip.dart';
import 'package:gestion_propinas/models/employee.dart';

class EstadisticasPropinasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas Propinas'),
        backgroundColor: const Color.fromARGB(255, 31, 98, 154),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WeekSelectorBar(),
          
          
        ],
      ),
    );
  }
}

class WeekSelectorBar extends StatefulWidget {
  @override
  _WeekSelectorBarState createState() => _WeekSelectorBarState();
}

class _WeekSelectorBarState extends State<WeekSelectorBar> {
  final TipDatabaseService _tipService = TipDatabaseService();
  final EmployeeDatabaseService _employeeService = EmployeeDatabaseService();

  int _selectedWeekIndex = 0;
  late ScrollController _scrollController;
  DateTime? _selectedMonday;
  Map<String, double> _weeklyTipsByEmployee = {};
  Map<String, String> _employeeNames = {};
  double _weeklyTotal = 0.0;
  double _monthlyTotal = 0.0;
  double _yearlyTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    final currentWeek = DateTime.now().weekday == DateTime.monday
        ? DateTime.now()
        : DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    _selectedWeekIndex = _getWeekNumber(currentWeek) - 1;
    _selectedMonday = currentWeek;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerSelectedWeek();
      _loadEmployeeNames();
      _loadWeeklyTips();
      _calculateMonthlyTotal(); // Usamos el nuevo método aquí
      _calculateWeeklyAndYearlyTotals();
    });
  }

  void _centerSelectedWeek() {
    final screenWidth = MediaQuery.of(context).size.width;
    const itemWidth = 58.0;
    final totalWidth = itemWidth * 52;

    double targetOffset =
        (_selectedWeekIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

    if (targetOffset < 0) targetOffset = 0;
    if (targetOffset > totalWidth - screenWidth) {
      targetOffset = totalWidth - screenWidth;
    }

    _scrollController.jumpTo(targetOffset);
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays + 1;
    return (daysSinceFirstDay / 7).ceil();
  }

  Future<void> _loadEmployeeNames() async {
    final employees = await _employeeService.fetchEmployees();
    setState(() {
      _employeeNames = {for (var e in employees) e.id: e.name};
    });
  }

  Future<void> _loadWeeklyTips() async {
    if (_selectedMonday == null) return;

    final endOfWeek = _selectedMonday!.add(const Duration(days: 6));
    final tips = await _fetchTipsForPeriod(_selectedMonday!, endOfWeek);

    setState(() {
      _weeklyTipsByEmployee = tips;
      _weeklyTotal = tips.values.fold(0, (sum, tip) => sum + tip);
    });
  }

  Future<void> _calculateWeeklyAndYearlyTotals() async {
    if (_selectedMonday == null) return;

    // Cálculo de la propina semanal
    final endOfWeek = _selectedMonday!.add(const Duration(days: 6));
    final weeklyTips = await _fetchTipsForPeriod(_selectedMonday!, endOfWeek);
    setState(() {
      _weeklyTotal = weeklyTips.values.fold(0, (sum, tip) => sum + tip);
    });

    // Cálculo de la propina anual
    final startOfYear = DateTime(_selectedMonday!.year, 1, 1);
    final endOfYear = DateTime(_selectedMonday!.year, 12, 31);
    print("Calculando propina anual para el rango $startOfYear al $endOfYear");

    final yearlyTips = await _fetchTipsForPeriod(startOfYear, endOfYear);
    setState(() {
      _yearlyTotal = yearlyTips.values.fold(0, (sum, tip) => sum + tip);
    });
  }

  // Nuevo método específico para el cálculo mensual
  Future<void> _calculateMonthlyTotal() async {
    if (_selectedMonday == null) return;

    final startOfMonth =
        DateTime(_selectedMonday!.year, _selectedMonday!.month, 1);
    final endOfMonth =
        DateTime(_selectedMonday!.year, _selectedMonday!.month + 1, 1)
            .subtract(const Duration(days: 1));

    final monthlyTips = await _fetchTipsForPeriod(startOfMonth, endOfMonth);

    double monthlyTotal = monthlyTips.values.fold(0, (sum, tip) => sum + tip);

    setState(() {
      _monthlyTotal = monthlyTotal;
    });
  }

  Future<Map<String, double>> _fetchTipsForPeriod(
      DateTime startOfPeriod, DateTime endOfPeriod) async {
    try {
      List<Tip> tips =
          await _tipService.fetchTipsForWeek2(startOfPeriod, endOfPeriod);

      print("Datos obtenidos para el rango $startOfPeriod al $endOfPeriod:");
      tips.forEach((tip) => print("Tip: ${tip.amount} en fecha ${tip.date}"));

      Map<String, double> tipsByEmployee = {};

      for (var tip in tips) {
        tip.employeePayments.forEach((employeeId, _) {
          double employeeTip = tip.amount / tip.employeePayments.length;
          tipsByEmployee.update(
            employeeId,
            (existingTip) => existingTip + employeeTip,
            ifAbsent: () => employeeTip,
          );
        });
      }
      return tipsByEmployee;
    } catch (e) {
      print("Error al procesar las propinas: $e");
      return {};
    }
  }

  List<Widget> _buildWeeks() {
    return List.generate(52, (index) {
      final isSelected = index == _selectedWeekIndex;
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedWeekIndex = index;
            _selectedMonday = DateTime(DateTime.now().year, 1, 1)
                .add(Duration(days: index * 7));
            _loadWeeklyTips();
            _centerSelectedWeek();
            _calculateMonthlyTotal(); // Llamar al nuevo cálculo mensual al seleccionar una semana
          });
        },
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blueAccent
                : const Color.fromARGB(255, 31, 98, 154),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCircle(String label, double amount) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueAccent,
          ),
          child: Center(
            child: Text(
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de selección de semanas
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                children: _buildWeeks(),
              ),
            ),
            const SizedBox(height: 16),
            // Lista de propinas por usuario en la semana seleccionada
            if (_weeklyTipsByEmployee.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Seleccione una semana para ver las estadísticas"),
              )
            else
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  child: Column(
                    children: _weeklyTipsByEmployee.entries.map((entry) {
                      final employeeId = entry.key;
                      final totalTips = entry.value;
                      final employeeName =
                          _employeeNames[employeeId] ?? 'Desconocido';
                      return ListTile(
                        title: Text(employeeName),
                        subtitle: Text(
                          'Propina total: \$${totalTips.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Círculos de totales de propinas semanal, mensual y anual
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircle("Propina Semanal", _weeklyTotal),
                _buildCircle("Propina Mensual", _monthlyTotal),
                _buildCircle("Propina Anual", _yearlyTotal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
