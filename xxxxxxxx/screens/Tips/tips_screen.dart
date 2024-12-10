import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_propinas/models/employee.dart';
import 'package:gestion_propinas/models/tip.dart';
import 'package:gestion_propinas/screens/Tips/tips_summary_screen.dart';
import 'package:gestion_propinas/services/Databases/employee_database_service.dart';
import 'package:gestion_propinas/services/Databases/tip_database_service.dart';

class TipsScreen extends StatefulWidget {
  final Employee employee;

  const TipsScreen({Key? key, required this.employee}) : super(key: key);

  @override
  _TipsScreenState createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  Tip? _editingTip; // Propina en edición (si existe)
  DateTime _selectedDate = DateTime.now();
  List<Employee> _employees = [];
  List<Employee> _selectedEmployees = [];
  String _selectedShift = "Mañana";
  final TextEditingController _tipController = TextEditingController();

  final EmployeeDatabaseService _employeeService = EmployeeDatabaseService();
  final TipDatabaseService _tipService = TipDatabaseService();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = await _employeeService.fetchEmployees();
    setState(() {
      _employees = employees.where((employee) => employee.role != 'Admin').toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _toggleEmployeeSelection(Employee employee) {
    setState(() {
      if (_selectedEmployees.contains(employee)) {
        _selectedEmployees.remove(employee);
      } else {
        _selectedEmployees.add(employee);
      }
    });
  }

  // Método para cargar una propina para edición
  void _loadTipForEditing(Tip tip) {
    setState(() {
      _editingTip = tip;
      _selectedDate = tip.date;
      _selectedShift = tip.shift;
      _tipController.text = tip.amount.toString();
      _selectedEmployees = _employees.where((e) => tip.employeePayments.keys.contains(e.id)).toList();
    });
  }

  Future<void> _saveTip() async {
    final tipAmount = double.tryParse(_tipController.text) ?? 0;
    if (tipAmount <= 0 || _selectedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ingrese una propina válida y seleccione al menos un empleado')),
      );
      return;
    }

    Map<String, int> employeePayments = {
      for (var employee in _selectedEmployees) employee.id: 0
    };

    // Crear o actualizar el objeto Tip
    final newTip = Tip(
      id: _editingTip?.id, // Si está en edición, usa el ID existente
      amount: tipAmount,
      date: _selectedDate,
      shift: _selectedShift,
      employeePayments: employeePayments,
    );

    if (_editingTip == null) {
      // Crear una nueva propina
      await _tipService.insertTip(newTip);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propina guardada correctamente')),
      );
    } else {
      // Actualizar la propina existente
      await _tipService.updateTip(newTip);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propina actualizada correctamente')),
      );
    }

    // Limpiar el formulario
    _clearForm();
  }

  void _clearForm() {
    _tipController.clear();
    setState(() {
      _editingTip = null;
      _selectedEmployees.clear();
      _selectedDate = DateTime.now();
      _selectedShift = "Mañana";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Propinas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de fecha
            TextButton(
              onPressed: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de empleados como botones seleccionables
            const Text(
              'Selecciona los empleados:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  mainAxisExtent: 100,
                ),
                itemCount: _employees.length,
                itemBuilder: (context, index) {
                  final employee = _employees[index];
                  final isSelected = _selectedEmployees.contains(employee);

                  return SizedBox(
                    width: 100,
                    height: 100,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.blue : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => _toggleEmployeeSelection(employee),
                      child: Center(
                        child: Text(
                          employee.name,
                          textAlign: TextAlign.center,
                          maxLines: 1, // Limita el texto a una sola línea
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Selector de turno
            DropdownButtonFormField<String>(
              value: _selectedShift,
              items: ["Mañana", "Tarde"].map((shift) {
                return DropdownMenuItem(
                  value: shift,
                  child: Text(shift),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedShift = value ?? "Mañana";
                });
              },
              decoration: const InputDecoration(
                labelText: 'Selecciona el turno',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Campo de entrada de propina
            TextField(
              controller: _tipController,
              decoration: const InputDecoration(
                labelText: 'Propina Total',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Botón para guardar y botón para ver el resumen
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveTip,
                  child: Text(_editingTip == null ? 'Guardar Propina' : 'Actualizar Propina'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TipsSummaryScreen(),
                      ),
                    );
                  },
                  child: const Text('Ver Resumen de Propinas'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}