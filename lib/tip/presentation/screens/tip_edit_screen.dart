import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';

class TipEditScreen extends StatefulWidget {
  final TipRepository tipRepository;
  final EmployeeService employeeService;
  final Tip tip;

  const TipEditScreen({
    Key? key,
    required this.tipRepository,
    required this.employeeService,
    required this.tip,
  }) : super(key: key);

  @override
  _TipEditScreenState createState() => _TipEditScreenState();
}

class _TipEditScreenState extends State<TipEditScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = "mañana";
  List<Employee> _employees = [];
  List<Employee> _selectedEmployees = [];
  final TextEditingController _cashTipController = TextEditingController();
  final TextEditingController _cardTipController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  double _totalTip = 0.0;

  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales desde widget.tip
    _selectedDate = widget.tip.date;
    _selectedShift = widget.tip.shift;
    _dateController.text =
        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
    _cashTipController.text = '0';
    _cardTipController.text = '0';

    // Dividir total entre cash y card si lo deseas, o dejar 0/0 y permitir edición manual.
    _totalTip = widget.tip.amount;

    _fetchEmployees();
    _cashTipController.addListener(_updateTotal);
    _cardTipController.addListener(_updateTotal);

    // Reconstruir la lista de empleados seleccionados a partir de employeePayments
    // Quitar admin y recalcular
  }

  @override
  void dispose() {
    _cashTipController.dispose();
    _cardTipController.dispose();
    super.dispose();
  }

  void _updateTotal() {
    final cashTip = double.tryParse(_cashTipController.text) ?? 0.0;
    final cardTip = double.tryParse(_cardTipController.text) ?? 0.0;
    setState(() {
      _totalTip = cashTip + cardTip;
    });
  }

  Future<void> _fetchEmployees() async {
    try {
      final employees = await widget.employeeService.getAllEmployees();
      setState(() {
        _employees = employees.where((e) => e.role != 'Admin').toList();
      });

      // Determinar empleados seleccionados a partir del tip
      // Sabemos que el tip tiene employeePayments,
      // Todos los IDs excepto el admin se marcan como seleccionados
      final admin = employees.firstWhere((e) => e.role == 'Admin',
          orElse: () => employees.first);
      final participantIds = widget.tip.employeePayments.keys
          .where((id) => id != admin.id)
          .toList();

      final selected =
          _employees.where((emp) => participantIds.contains(emp.id)).toList();
      setState(() {
        _selectedEmployees = selected;
      });
    } catch (e) {
      print('Error al obtener empleados: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar empleados')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  Widget _buildEmployeeSelection() {
    if (_employees.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Wrap(
      spacing: 10,
      children: _employees.map((employee) {
        final isSelected = _selectedEmployees.contains(employee);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedEmployees.remove(employee);
              } else {
                _selectedEmployees.add(employee);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.grey,
                width: 2,
              ),
            ),
            child: Text(
              employee.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submitTip() async {
    final cashTip = double.tryParse(_cashTipController.text) ?? 0.0;
    final cardTip = double.tryParse(_cardTipController.text) ?? 0.0;

    if (_selectedEmployees.isEmpty || (cashTip <= 0 && cardTip <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    final totalTip = cashTip + cardTip;

    try {
      // Obtén el admin dinámicamente
      final allEmployees = await widget.employeeService.getAllEmployees();
      final admin = allEmployees.firstWhere(
        (employee) => employee.role == 'Admin',
        orElse: () => throw Exception('No se encontró un Admin.'),
      );

      final allParticipants = [..._selectedEmployees, admin];
      final sharePerPerson =
          (totalTip / allParticipants.length).roundToDouble();

      final employeePayments = {
        for (var employee in allParticipants)
          employee.id: {'amount': sharePerPerson, 'isDeleted': false},
      };

      final updatedTip = widget.tip.copyWith(
        amount: totalTip,
        date: _selectedDate,
        shift: _selectedShift,
        employeePayments: employeePayments,
        adminShare: sharePerPerson,
      );

      await widget.tipRepository.updateTip(updatedTip);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propina actualizada exitosamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('Error al actualizar la propina: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar la propina')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Propina')),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Ocultar el teclado al tocar fuera
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seleccionar Fecha:',
                    style: TextStyle(fontSize: 16)),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Selecciona una fecha',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 20),
                const Text('Seleccionar Turno:',
                    style: TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: _selectedShift,
                  items: const [
                    DropdownMenuItem(value: 'mañana', child: Text('Mañana')),
                    DropdownMenuItem(value: 'noche', child: Text('Noche')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedShift = value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text('Seleccionar Empleados:',
                    style: TextStyle(fontSize: 16)),
                _buildEmployeeSelection(),
                const SizedBox(height: 20),
                const Text('Propina en Efectivo:',
                    style: TextStyle(fontSize: 16)),
                TextField(
                  controller: _cashTipController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Ingrese importe en efectivo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Propina en Tarjeta de Crédito:',
                    style: TextStyle(fontSize: 16)),
                TextField(
                  controller: _cardTipController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Ingrese importe en tarjeta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Total Propina:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '$_totalTip €',
                  style: const TextStyle(fontSize: 20, color: Colors.green),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitTip,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Actualizar Propina'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
