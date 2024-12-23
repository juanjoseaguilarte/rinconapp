import 'package:flutter/material.dart';

class AddTaskScreen extends StatefulWidget {
  final Future<void> Function(List<String>, String, String) addTask;
  final Future<List<Map<String, dynamic>>> Function() fetchEmployees;

  const AddTaskScreen({
    Key? key,
    required this.addTask,
    required this.fetchEmployees,
  }) : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _employees = [];
  List<String> _selectedEmployees = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final employees = await widget.fetchEmployees();
      setState(() {
        _employees = employees;
      });
    } catch (e) {
      debugPrint('Error al cargar empleados: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar empleados: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty || _selectedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    // Debugging: Imprimir valores antes de llamar a addTask
    debugPrint('Título: $title');
    debugPrint('Descripción: $description');
    debugPrint('Empleados seleccionados: $_selectedEmployees');

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.addTask(_selectedEmployees, title, description);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea agregada con éxito')),
      );
      Navigator.pop(context);
    } catch (e, stackTrace) {
      debugPrint('Error al agregar tarea: $e');
      debugPrint('StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar tarea: $e'),
          action: SnackBarAction(
            label: 'Detalles',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Detalles del Error'),
                  content: Text('Error técnico: $e'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Tarea')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _employees.isEmpty
                      ? const Center(
                          child: Text('No hay empleados disponibles'))
                      : DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                              labelText: 'Seleccionar Empleados'),
                          items: _employees
                              .map(
                                (e) => DropdownMenuItem<String>(
                                  value: e['id'],
                                  child: Text(e['name']),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null &&
                                !_selectedEmployees.contains(value)) {
                              setState(() {
                                _selectedEmployees.add(value);
                              });
                            }
                          },
                        ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    children: _selectedEmployees
                        .map((id) => Chip(
                              label: Text(_employees
                                  .firstWhere((e) => e['id'] == id)['name']),
                              onDeleted: () {
                                setState(() {
                                  _selectedEmployees.remove(id);
                                });
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addTask,
                    child: const Text('Agregar Tarea'),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
