import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';

class TipEditScreen extends StatefulWidget {
  final Tip tip;
  final TipRepository tipRepository;
  final EmployeeService employeeService;

  const TipEditScreen({
    Key? key,
    required this.tip,
    required this.tipRepository,
    required this.employeeService,
  }) : super(key: key);

  @override
  _TipEditScreenState createState() => _TipEditScreenState();
}

class _TipEditScreenState extends State<TipEditScreen> {
  late DateTime _selectedDate;
  late String _selectedShift;
  List<Employee> _employees = [];
  List<Employee> _selectedEmployees = [];
  final TextEditingController _cashTipController = TextEditingController();
  final TextEditingController _cardTipController = TextEditingController();
  double _totalTip = 0.0;

  bool _isEditable = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.tip.date;
    _selectedShift = widget.tip.shift;
    _checkIfTipIsEditable();
    _initializeFields();
    _fetchEmployees();
    _cashTipController.addListener(_updateTotal);
    _cardTipController.addListener(_updateTotal);
  }

  @override
  void dispose() {
    _cashTipController.dispose();
    _cardTipController.dispose();
    super.dispose();
  }

  void _checkIfTipIsEditable() {
    final isPaid = widget.tip.employeePayments.values.any(
      (payment) => payment['isDeleted'] == true,
    );
    setState(() {
      _isEditable = !isPaid;
    });
  }

  void _initializeFields() {
    final cashTip = widget.tip.employeePayments.values.fold<double>(
      0.0,
      (sum, payment) => sum + (payment['cash'] ?? 0.0),
    );

    final cardTip = widget.tip.employeePayments.values.fold<double>(
      0.0,
      (sum, payment) => sum + (payment['card'] ?? 0.0),
    );

    _cashTipController.text = cashTip.toStringAsFixed(2);
    _cardTipController.text = cardTip.toStringAsFixed(2);
    _totalTip = cashTip + cardTip;
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
        _selectedEmployees = _employees
            .where((employee) =>
                widget.tip.employeePayments.keys.contains(employee.id))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar empleados')),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_isEditable) return;

    final cashTip = double.tryParse(_cashTipController.text) ?? 0.0;
    final cardTip = double.tryParse(_cardTipController.text) ?? 0.0;

    if (_selectedEmployees.isEmpty || cashTip <= 0 && cardTip <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    final totalTip = cashTip + cardTip;
    final employeePayments = {
      for (var employee in _selectedEmployees)
        employee.id: {
          'cash': cashTip / _selectedEmployees.length,
          'card': cardTip / _selectedEmployees.length,
          'isDeleted': false,
        }
    };

    final updatedTip = widget.tip.copyWith(
      adminShare: totalTip / (_selectedEmployees.length + 1),
      amount: totalTip,
      date: _selectedDate,
      shift: _selectedShift,
      employeePayments: employeePayments,
    );

    try {
      await widget.tipRepository.updateTip(updatedTip);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propina actualizada correctamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la propina')),
      );
    }
  }

  Widget _buildEmployeeSelection() {
    if (_employees.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Wrap(
      spacing: 10,
      alignment: WrapAlignment.center,
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
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Propina')),
      body: _isEditable
          ? GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Seleccionar Fecha:',
                          style: TextStyle(fontSize: 16)),
                      TextField(
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
                          DropdownMenuItem(
                              value: 'mañana', child: Text('Mañana')),
                          DropdownMenuItem(
                              value: 'noche', child: Text('Noche')),
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
                          hintText: 'Ingrese monto en efectivo',
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
                          hintText: 'Ingrese monto en tarjeta',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            const Text('Total Propina:',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            Text(
                              '$_totalTip €',
                              style: const TextStyle(
                                  fontSize: 30, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Guardar Cambios'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const Center(
              child: Text(
                'Esta propina ya ha sido pagada y no se puede editar.',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
    );
  }
}
