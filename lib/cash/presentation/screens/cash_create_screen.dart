import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/domain/entities/cash.dart';
import 'package:gestion_propinas/cash/application/usecases/add_cash.dart';
import 'package:uuid/uuid.dart';

class CashCreateScreen extends StatefulWidget {
  final AddCash addCashUseCase;

  const CashCreateScreen({Key? key, required this.addCashUseCase}) : super(key: key);

  @override
  _CashCreateScreenState createState() => _CashCreateScreenState();
}

class _CashCreateScreenState extends State<CashCreateScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final newCash = Cash(
      id: const Uuid().v4(),
      amount: amount,
      updatedAt: DateTime.now(),
    );
    await widget.addCashUseCase(newCash);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Registro de Caja'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}