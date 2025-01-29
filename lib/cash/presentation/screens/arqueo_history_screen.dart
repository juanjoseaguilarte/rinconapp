import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/domain/entities/arqueo_record.dart';
import 'package:intl/intl.dart';
import 'package:gestion_propinas/cash/domain/repositories/arqueo_repository.dart';

class ArqueoHistoryScreen extends StatefulWidget {
  final ArqueoRepository arqueoRepository;

  const ArqueoHistoryScreen({Key? key, required this.arqueoRepository}) : super(key: key);

  @override
  _ArqueoHistoryScreenState createState() => _ArqueoHistoryScreenState();
}

class _ArqueoHistoryScreenState extends State<ArqueoHistoryScreen> {
  late Future<List<ArqueoRecord>> _arqueoHistory;

  @override
  void initState() {
    super.initState();
    _arqueoHistory = widget.arqueoRepository.getArqueoHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Arqueos')),
      body: FutureBuilder<List<ArqueoRecord>>(
        future: _arqueoHistory,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final arqueos = snapshot.data!;
          return ListView.builder(
            itemCount: arqueos.length,
            itemBuilder: (context, index) {
              final arqueo = arqueos[index];
              return ListTile(
                title: Text('${arqueo.amount.toStringAsFixed(2)} €'),
                subtitle: Text(
                  'Usuario: ${arqueo.userId} - Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(arqueo.date)}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}