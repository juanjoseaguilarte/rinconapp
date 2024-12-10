// lib/cash/presentation/screens/movements_list_screen.dart
import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/domain/entities/transaction_entity.dart';
import 'package:intl/intl.dart';

class MovementsListScreen extends StatefulWidget {
  final List<TransactionEntity> transactions;
  final Map<String, dynamic>
      loggedUser; // Agregamos el usuario logueado para chequear su rol

  const MovementsListScreen({
    Key? key,
    required this.transactions,
    required this.loggedUser,
  }) : super(key: key);

  @override
  _MovementsListScreenState createState() => _MovementsListScreenState();
}

class _MovementsListScreenState extends State<MovementsListScreen> {
  DateTime selectedDate = DateTime.now();

  bool get isAdmin => widget.loggedUser['role'] == 'Admin';

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }

  String _formatDay(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  Future<void> _pickDate() async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (newDate != null) {
      setState(() {
        selectedDate = newDate;
      });
    }
  }

  List<TransactionEntity> get _filteredTransactions {
    return widget.transactions.where((t) {
      return t.date.year == selectedDate.year &&
          t.date.month == selectedDate.month &&
          t.date.day == selectedDate.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
      ),
      body: Column(
        children: [
          // Selector de fecha
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('Seleccionar Fecha'),
                ),
                const SizedBox(width: 20),
                Text(
                  'Fecha: ${_formatDay(selectedDate)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child:
                        Text('No hay movimientos registrados para esta fecha.'),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final t = filtered[index];
                      final dateString = _formatDate(t.date);
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text('$dateString - ${t.userName}'),
                          subtitle: isAdmin
                              ? Text(
                                  'Importe: ${t.amount.toStringAsFixed(2)} €\nMotivo: ${t.reason} -- ${t.type.toUpperCase()}',
                                )
                              : null, // Si no es admin, no mostramos el detalle
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
