import 'package:flutter/material.dart';
import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_edit_screen.dart';

class TipListScreen extends StatefulWidget {
  final TipRepository tipRepository;
  final EmployeeService employeeService; // Añadido

  const TipListScreen({
    Key? key,
    required this.tipRepository,
    required this.employeeService, // Añadido
  }) : super(key: key);

  @override
  _TipListScreenState createState() => _TipListScreenState();
}

class _TipListScreenState extends State<TipListScreen> {
  late Future<List<Tip>> _tipsFuture;

  @override
  void initState() {
    super.initState();
    _fetchTips();
  }

  void _fetchTips() {
    _tipsFuture = widget.tipRepository.fetchTips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Propinas'),
      ),
      body: FutureBuilder<List<Tip>>(
        future: _tipsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay propinas registradas.'),
            );
          }

          final tips = snapshot.data!;
          tips.sort((a, b) =>
              b.date.compareTo(a.date)); // Ordenar por fecha descendente

          return ListView.builder(
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Card(
                child: ListTile(
                  title: Text(
                    'Fecha: ${tip.date.day}/${tip.date.month}/${tip.date.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Total: €${tip.amount.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TipEditScreen(
                            tip: tip,
                            tipRepository: widget.tipRepository,
                            employeeService: widget.employeeService, // Añadido
                          ),
                        ),
                      ).then((_) {
                        // Recargar la lista tras editar
                        _fetchTips();
                        setState(() {});
                      });
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
