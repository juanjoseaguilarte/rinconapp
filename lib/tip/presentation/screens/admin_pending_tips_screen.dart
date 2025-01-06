import 'package:flutter/material.dart';
import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';

class AdminPendingTipsScreen extends StatefulWidget {
  final TipRepository tipRepository;

  const AdminPendingTipsScreen({
    Key? key,
    required this.tipRepository,
  }) : super(key: key);

  @override
  _AdminPendingTipsScreenState createState() => _AdminPendingTipsScreenState();
}

class _AdminPendingTipsScreenState extends State<AdminPendingTipsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _adminPendingTips = [];
  double _totalPendingAdminShare = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAdminPendingTips();
  }

  Future<void> _loadAdminPendingTips() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tips = await widget.tipRepository.fetchTips();
      print('Propinas obtenidas: $tips');

      double totalPending = 0.0;
      final List<Map<String, dynamic>> pendingTips = [];

      for (var tip in tips) {
        if (!tip.isDeleted && tip.adminShare > 0) {
          totalPending += tip.adminShare;
          pendingTips.add({
            'tip': tip,
            'amount': tip.adminShare,
          });
        }
      }

      // Ordenar las propinas pendientes por fecha (más recientes primero)
      pendingTips.sort((a, b) {
        final dateA = (a['tip'] as Tip).date;
        final dateB = (b['tip'] as Tip).date;
        return dateB.compareTo(dateA); // Orden descendente
      });

      print('Propinas pendientes de admin (ordenadas): $pendingTips');
      print('Total de propinas pendientes para admin: $totalPending');

      setState(() {
        _adminPendingTips = pendingTips;
        _totalPendingAdminShare = totalPending;
      });
    } catch (e) {
      print('Error al cargar propinas pendientes de admin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar las propinas de admin')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _payAdminTip(Map<String, dynamic> tipDetails) async {
    try {
      final tip = tipDetails['tip'] as Tip;

      // Marcar la propina como pagada
      final updatedTip = tip.copyWith(isDeleted: true);
      await widget.tipRepository.updateTip(updatedTip);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propina de admin marcada como pagada')),
      );

      // Actualizar la lista y el total
      setState(() {
        _adminPendingTips.remove(tipDetails);
        _totalPendingAdminShare -= tipDetails['amount'];
      });
    } catch (e) {
      print('Error al pagar propina de admin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al pagar la propina de admin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propinas Pendientes de Admin'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Propinas Pendientes: €${_totalPendingAdminShare.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _adminPendingTips.length,
                      itemBuilder: (context, index) {
                        final tipDetails = _adminPendingTips[index];
                        final tip = tipDetails['tip'] as Tip;
                        final amount = tipDetails['amount'] as double;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              'Fecha: ${tip.date.year}-${tip.date.month}-${tip.date.day}',
                            ),
                            subtitle: Text(
                              'Propina Pendiente: €${amount.toStringAsFixed(2)}',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _payAdminTip(tipDetails),
                              child: const Text('Pagar'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
