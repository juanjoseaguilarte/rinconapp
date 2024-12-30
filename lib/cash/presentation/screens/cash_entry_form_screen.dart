import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/domain/repositories/cash_transation_repository.dart';

class CashEntryFormScreen extends StatefulWidget {
  final Map<String, dynamic> loggedUser;
  final String transactionType; // 'entrada' o 'salida'
  final CashTransactionRepository cashTransactionRepository;

  const CashEntryFormScreen({
    Key? key,
    required this.loggedUser,
    required this.transactionType,
    required this.cashTransactionRepository,
  }) : super(key: key);

  @override
  _CashEntryFormScreenState createState() => _CashEntryFormScreenState();
}

class _CashEntryFormScreenState extends State<CashEntryFormScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.trim();
    final reason = _reasonController.text.trim();

    if (amountText.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe ingresar un importe y un motivo')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('El importe debe ser un número válido mayor que 0')),
      );
      return;
    }

    try {
      await widget.cashTransactionRepository.addTransaction(
        userId: widget.loggedUser['id'],
        userName: widget.loggedUser['name'],
        type: widget.transactionType,
        amount: amount,
        reason: reason,
        date: DateTime.now(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Transacción guardada: ${widget.transactionType.toUpperCase()}, Importe: $amount €, Motivo: $reason'),
        ),
      );

      Navigator.pop(context); // Volver atrás después de guardar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar transacción: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.transactionType == 'entrada'
        ? 'Registrar Entrada'
        : 'Registrar Salida';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Usuario: ${widget.loggedUser['name']} (${widget.loggedUser['role']})'),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Importe (€)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
