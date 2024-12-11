import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_edit_screen.dart';

class AdminTipScreen extends StatefulWidget {
  final TipRepository tipRepository;
  final EmployeeService employeeService;

  const AdminTipScreen({
    Key? key,
    required this.tipRepository,
    required this.employeeService,
  }) : super(key: key);

  @override
  _AdminTipScreenState createState() => _AdminTipScreenState();
}

class _AdminTipScreenState extends State<AdminTipScreen> {
  late Future<List<Tip>> _tipsFuture;

  @override
  void initState() {
    super.initState();
    _tipsFuture = widget.tipRepository.fetchTips();
  }

  Future<void> _refreshTips() async {
    setState(() {
      _tipsFuture = widget.tipRepository.fetchTips();
    });
  }

  void _editTip(Tip tip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TipEditScreen(
          tipRepository: widget.tipRepository,
          employeeService: widget.employeeService,
          tip: tip,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _refreshTips();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Propinas'),
      ),
      body: FutureBuilder<List<Tip>>(
        future: _tipsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar propinas: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay propinas registradas'),
            );
          }

          final tips = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshTips,
            child: ListView.builder(
              itemCount: tips.length,
              itemBuilder: (context, index) {
                final tip = tips[index];
                return Card(
                  child: ListTile(
                    title: Text(
                        'Fecha: ${tip.date.day}/${tip.date.month}/${tip.date.year}'),
                    subtitle: Text('Turno: ${tip.shift}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editTip(tip),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
