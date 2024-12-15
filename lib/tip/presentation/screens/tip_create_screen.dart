import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';

class TipCreateScreen extends StatefulWidget {
  final EmployeeService employeeService;
  final TipRepository tipRepository;

  const TipCreateScreen({
    Key? key,
    required this.employeeService,
    required this.tipRepository,
  }) : super(key: key);

  @override
  _TipCreateScreenState createState() => _TipCreateScreenState();
}

class _TipCreateScreenState extends State<TipCreateScreen> {
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
    _dateController.text =
        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
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
                fontSize: 16,
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

    if (_selectedEmployees.isEmpty || cashTip <= 0 && cardTip <= 0) {
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

      // Incluye al "Admin" en la lista de reparto
      final allParticipants = [..._selectedEmployees, admin];
      print(allParticipants);
      final sharePerPerson =
          (totalTip / allParticipants.length).roundToDouble();

      // Crear el mapa de pagos con isDeleted = false para todos
      final employeePayments = {
        for (var employee in _selectedEmployees)
          employee.id: {
            'cash': cashTip / (_selectedEmployees.length + 1),
            'card': cardTip / (_selectedEmployees.length + 1),
            'isDeleted': false,
          }
      };

      final tip = Tip(
        amount: totalTip,
        date: _selectedDate,
        shift: _selectedShift,
        employeePayments: employeePayments,
        adminShare: sharePerPerson,
      );

      await widget.tipRepository.addTip(tip);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propina registrada exitosamente')),
      );

      setState(() {
        _cashTipController.clear();
        _cardTipController.clear();
        _selectedEmployees.clear();
        _selectedShift = "mañana";
        _selectedDate = DateTime.now();
      });

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      print('Error al procesar la propina: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar la propina')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Propinas')),
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedShift,
                    borderRadius: const BorderRadius.all(Radius.zero),
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
                  onChanged: (value) {
                    // Reemplaza la coma por un punto al instante
                    _cashTipController.text = value.replaceAll(',', '.');
                    _cashTipController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _cashTipController.text.length),
                    );
                  },
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
                    onChanged: (value) {
                      // Reemplaza la coma por un punto al instante
                      _cardTipController.text = value.replaceAll(',', '.');
                      _cardTipController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _cashTipController.text.length),
                      );
                    }),
                const SizedBox(height: 20),
                const Center(
                  child: Column(
                    children: [
                      Text('Total Propina:',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    children: [
                      Text(
                        '$_totalTip €',
                        style:
                            const TextStyle(fontSize: 30, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitTip,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    textStyle: const TextStyle(fontSize: 30),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Añadir Propina'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
