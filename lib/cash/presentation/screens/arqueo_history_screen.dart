import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/domain/entities/arqueo_record.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:intl/intl.dart';
import 'package:gestion_propinas/cash/domain/repositories/arqueo_repository.dart';

class ArqueoHistoryScreen extends StatefulWidget {
  final ArqueoRepository arqueoRepository;
  final EmployeeService employeeService;

  const ArqueoHistoryScreen({
    Key? key,
    required this.arqueoRepository,
    required this.employeeService,
  }) : super(key: key);

  @override
  _ArqueoHistoryScreenState createState() => _ArqueoHistoryScreenState();
}

class _ArqueoHistoryScreenState extends State<ArqueoHistoryScreen> {
  late Future<List<ArqueoRecord>> _arqueoHistory;
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _arqueoHistory = _loadArqueoHistoryWithNames();
  }

  Future<List<ArqueoRecord>> _loadArqueoHistoryWithNames() async {
    final arqueos = await widget.arqueoRepository.getArqueoHistory();
    final employees = await widget.employeeService.getAllEmployees();

    _userNames = {for (var employee in employees) employee.id: employee.name};

    return arqueos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Arqueos')),
      body: FutureBuilder<List<ArqueoRecord>>(
        future: _arqueoHistory,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final arqueos = snapshot.data!;
          return ListView.builder(
            itemCount: arqueos.length,
            itemBuilder: (context, index) {
              final arqueo = arqueos[index];
              final difference = arqueo.countedAmount - arqueo.expectedAmount;
              return ListTile(
                title: Text(
                    'Esperado: ${arqueo.expectedAmount.toStringAsFixed(2)} € - Contado: ${arqueo.countedAmount.toStringAsFixed(2)} €'),
                subtitle: Text(
                  'Diferencia: ${difference.toStringAsFixed(2)} € - Usuario: ${_userNames[arqueo.userId] ?? 'Desconocido'} - Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(arqueo.date)}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

