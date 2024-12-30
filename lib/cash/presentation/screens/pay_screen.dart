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
  final TextEditingController _tableNumberController = TextEditingController();

  @override
  void dispose() {
    _billAmountController.dispose();
    _customerAmountController.dispose();
    _tableNumberController.dispose();
    super.dispose();
  }

  double get _billAmount {
    final val = double.tryParse(_billAmountController.text) ?? 0.0;
    return val < 0 ? 0.0 : val;
  }

  double get _customerAmount {
    final val = double.tryParse(_customerAmountController.text) ?? 0.0;
    return val < 0 ? 0.0 : val;
  }

  double get _change =>
      (_customerAmount - _billAmount).clamp(0.0, double.infinity);

  Future<void> _saveTransaction() async {
    final bill = _billAmount;
    final given = _customerAmount;
    final change = _change;

    if (_tableNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe ingresar el número de la mesa')),
      );
      return;
    }

    if (bill <= 0 || given <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe ingresar importes válidos')),
      );
      return;
    }

    try {
      await widget.cashTransactionRepository.addTransaction(
        userId: widget.loggedUser['id'],
        userName: widget.loggedUser['name'],
        type: 'entrada',
        amount: bill,
        reason: "Pago mesa ${_tableNumberController.text}",
        date: DateTime.now(),
      );

      if (change > 0) {
        await widget.cashTransactionRepository.addTransaction(
          userId: widget.loggedUser['id'],
          userName: widget.loggedUser['name'],
          type: 'salida',
          amount: change,
          reason: 'Devolución de cambio',
          date: DateTime.now(),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Pago registrado correctamente. Cambio: ${change.toStringAsFixed(2)} €')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar pago: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobro Mesa Manual'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Usuario: ${widget.loggedUser['name']} (${widget.loggedUser['role']})'),
            const SizedBox(height: 20),
            TextField(
              controller: _tableNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número de la mesa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _billAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importe de la cuenta (€)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _customerAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importe entregado por el cliente (€)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text(
              'Cambio: ${_change.toStringAsFixed(2)} €',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _change < 0 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Guardar Pago'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
