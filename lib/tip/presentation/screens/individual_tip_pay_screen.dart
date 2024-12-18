import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';

class IndividualTipPayScreen extends StatelessWidget {
  final String employeeName;
  final double amount;
  final String employeeId;
  final TipRepository tipRepository;
  final EmployeeService employeeService;
  final VoidCallback reloadData;

  const IndividualTipPayScreen({
    Key? key,
    required this.employeeName,
    required this.amount,
    required this.employeeId,
    required this.tipRepository,
    required this.employeeService,
    required this.reloadData,
  }) : super(key: key);

  Future<void> _payTips(BuildContext context) async {
    try {
      final tips = await tipRepository.fetchTips();

      for (var tip in tips) {
        if (tip.employeePayments.containsKey(employeeId)) {
          final updatedPayments = Map.of(tip.employeePayments);

          if (!(updatedPayments[employeeId]!['isDeleted'] ?? false)) {
            updatedPayments[employeeId]!['isDeleted'] = true;

            final updatedTip = tip.copyWith(employeePayments: updatedPayments);
            await tipRepository.updateTip(updatedTip);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Propina pagada exitosamente a $employeeName')),
      );

      reloadData(); // Recargar datos al finalizar
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al pagar la propina: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pagar Propina a $employeeName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Propina Total a Pagar: €${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Una vez confirmes, no habrá vuelta atrás. ¿Deseas continuar?',
              style: TextStyle(fontSize: 16),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _payTips(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Confirmar Pago'),
            ),
          ],
        ),
      ),
    );
  }
}