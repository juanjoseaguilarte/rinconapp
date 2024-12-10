import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/domain/repositories/cash_transation_repository.dart';

class PayScreen extends StatefulWidget {
  final Map<String, dynamic> loggedUser;
  final CashTransactionRepository cashTransactionRepository;

  const PayScreen({
    Key? key,
    required this.loggedUser,
    required this.cashTransactionRepository,
  }) : super(key: key);

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  final TextEditingController _billAmountController =
      TextEditingController(text: '0');
  final TextEditingController _customerAmountController =
      TextEditingController(text: '0');

  @override
  void dispose() {
    _billAmountController.dispose();
    _customerAmountController.dispose();
    super.dispose();
  }

  double get _billAmount {
    final val =
        double.tryParse(_billAmountController.text.replaceAll(',', '.')) ?? 0.0;
    return val < 0 ? 0.0 : val;
  }

  double get _customerAmount {
    final val =
        double.tryParse(_customerAmountController.text.replaceAll(',', '.')) ??
            0.0;
    return val < 0 ? 0.0 : val;
  }

  double get _change =>
      (_customerAmount - _billAmount).clamp(0.0, double.infinity);

  Future<void> _saveTransaction() async {
    final bill = _billAmount;
    final given = _customerAmount;
    final change = _change;

    if (bill <= 0 || given <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe ingresar importes válidos')),
      );
      return;
    }

    // Motivo fijo: "pago cuenta mesa"
    const reason = "pago cuenta mesa";

    try {
      // Transacción de entrada (el dinero recibido del cliente)
      await widget.cashTransactionRepository.addTransaction(
        userId: widget.loggedUser['id'],
        userName: widget.loggedUser['name'],
        type: 'entrada',
        amount: bill,
        reason: reason,
        date: DateTime.now(),
      );

      // Si hay cambio, registramos una salida
      if (change > 0) {
        await widget.cashTransactionRepository.addTransaction(
          userId: widget.loggedUser['id'],
          userName: widget.loggedUser['name'],
          type: 'salida',
          amount: change,
          reason: "devolución de cambio",
          date: DateTime.now(),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Transacción guardada. Cambio: ${change.toStringAsFixed(2)} €')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar transacción: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final change = _change;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
                'Usuario: ${widget.loggedUser['name']} (${widget.loggedUser['role']})'),
            const SizedBox(height: 20),
            TextField(
              controller: _billAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importe de la cuenta',
                border: OutlineInputBorder(),
              ),
              onTap: () {
                if (_billAmountController.text == '0') {
                  _billAmountController.clear();
                }
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _customerAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Entregado por el cliente',
                border: OutlineInputBorder(),
              ),
              onTap: () {
                if (_customerAmountController.text == '0') {
                  _customerAmountController.clear();
                }
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text(
              'Vuelta: ${change.toStringAsFixed(2)} €',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveTransaction,
              child: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
