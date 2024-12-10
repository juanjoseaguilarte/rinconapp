// tip_list_screen.dart
import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';
import 'tip_edit_screen.dart';

class TipListScreen extends StatefulWidget {
  final TipRepository tipRepository;
  final EmployeeService employeeService;
  final List<Tip>
      tips; // Se pasan las propinas ya cargadas desde TipAdminScreen

  const TipListScreen({
    Key? key,
    required this.tipRepository,
    required this.employeeService,
    required this.tips,
  }) : super(key: key);

  @override
  _TipListScreenState createState() => _TipListScreenState();
}

class _TipListScreenState extends State<TipListScreen> {
  late List<Tip> sortedTips;

  @override
  void initState() {
    super.initState();
    _sortTips(widget.tips);
  }

  void _sortTips(List<Tip> tips) {
    sortedTips = List<Tip>.from(tips);
    sortedTips
        .sort((a, b) => b.date.compareTo(a.date)); // más nueva a más vieja
  }

  Future<void> _reloadTips() async {
    final updatedTips = await widget.tipRepository.fetchTips();
    setState(() {
      _sortTips(updatedTips);
    });
  }

  bool _isTipPaid(Tip tip) {
    // Ahora se considera "pagada" si al menos una entrada de employeePayments tiene isDeleted == true
    for (var payment in tip.employeePayments.values) {
      final isDeleted = payment['isDeleted'] ?? false;
      if (isDeleted) {
        return true; // Encontramos una pagada, por lo tanto la propina se considera "no editable"
      }
    }
    return false; // Ninguna parte está pagada, se puede editar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Propinas'),
      ),
      body: ListView.builder(
        itemCount: sortedTips.length,
        itemBuilder: (context, index) {
          final tip = sortedTips[index];
          final isPaid = _isTipPaid(tip);

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(
                'Fecha: ${tip.date.year}-${tip.date.month}-${tip.date.day}, Turno: ${tip.shift}',
              ),
              subtitle: Text('Total: €${tip.amount.toStringAsFixed(2)}'),
              trailing: ElevatedButton(
                onPressed: isPaid
                    ? null // Si está pagada, se deshabilita el botón
                    : () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TipEditScreen(
                              tipRepository: widget.tipRepository,
                              employeeService: widget.employeeService,
                              tip: tip,
                            ),
                          ),
                        );

                        if (result == true) {
                          await _reloadTips(); // Recarga al volver de edición
                        }
                      },
                child: const Text('Editar'),
              ),
            ),
          );
        },
      ),
    );
  }
}
