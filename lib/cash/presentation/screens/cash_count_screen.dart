import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/domain/repositories/arqueo_repository.dart';
import 'package:gestion_propinas/cash/domain/repositories/cash_transation_repository.dart';
import 'package:gestion_propinas/cash/presentation/screens/arqueo_history_screen.dart';
import 'package:gestion_propinas/cash/presentation/screens/movements_list_screen.dart';

class CashCountScreen extends StatefulWidget {
  final double expectedAmount;
  final ArqueoRepository arqueoRepository;
  final Map<String, dynamic> loggedUser;
  final CashTransactionRepository
      transactionRepository; // Añadimos el repositorio de transacciones

  const CashCountScreen({
    Key? key,
    required this.expectedAmount,
    required this.arqueoRepository,
    required this.loggedUser,
    required this.transactionRepository,
  }) : super(key: key);

  @override
  _CashCountScreenState createState() => _CashCountScreenState();
}

class _CashCountScreenState extends State<CashCountScreen> {
  final denominations = <String, double>{
    '1c': 0.01,
    '2c': 0.02,
    '5c': 0.05,
    '10c': 0.10,
    '20c': 0.20,
    '50c': 0.50,
    '1€': 1.0,
    '2€': 2.0,
    '5€': 5.0,
    '10€': 10.0,
    '20€': 20.0,
    '50€': 50.0,
    '100€': 100.0,
    '200€': 200.0,
    '500€': 500.0,
  };

  final blisterConfig = <String, int>{
    '1c': 50,
    '2c': 50,
    '5c': 50,
    '10c': 40,
    '20c': 40,
    '50c': 40,
    '1€': 25,
    '2€': 25
  };

  Map<String, TextEditingController> unitControllers = {};
  Map<String, TextEditingController> packControllers = {};
  Map<String, FocusNode> unitFocusNodes = {};
  Map<String, FocusNode> packFocusNodes = {};

  bool get isAdmin => widget.loggedUser['role'] == 'Admin';
  bool get isAdminOrManager {
    final role = widget.loggedUser['role'];
    return role == 'Admin' || role == 'Encargado';
  }

  @override
  void initState() {
    super.initState();
    for (var denom in denominations.keys) {
      final unitController = TextEditingController(text: '0');
      final packController = TextEditingController(text: '0');
      final unitFocusNode = FocusNode();
      final packFocusNode = FocusNode();

      // Agregar listeners al FocusNode para unidades
      unitFocusNode.addListener(() {
        if (unitFocusNode.hasFocus) {
          if (unitController.text == '0') unitController.clear();
        } else {
          if (unitController.text.isEmpty) unitController.text = '0';
        }
      });

      // Agregar listeners al FocusNode para blísteres
      packFocusNode.addListener(() {
        if (packFocusNode.hasFocus) {
          if (packController.text == '0') packController.clear();
        } else {
          if (packController.text.isEmpty) packController.text = '0';
        }
      });

      // Listeners para actualizar total en tiempo real
      unitController.addListener(() {
        setState(() {});
      });
      packController.addListener(() {
        setState(() {});
      });

      unitControllers[denom] = unitController;
      packControllers[denom] = packController;
      unitFocusNodes[denom] = unitFocusNode;
      packFocusNodes[denom] = packFocusNode;
    }
  }

  @override
  void dispose() {
    for (var c in unitControllers.values) {
      c.dispose();
    }
    for (var c in packControllers.values) {
      c.dispose();
    }
    for (var node in unitFocusNodes.values) {
      node.dispose();
    }
    for (var node in packFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  double getCountedTotal() {
    double total = 0.0;
    denominations.forEach((denom, value) {
      final units = int.tryParse(unitControllers[denom]!.text) ?? 0;
      final packs = int.tryParse(packControllers[denom]!.text) ?? 0;
      final unitsValue = units * value;

      double packValue = 0.0;
      if (blisterConfig.containsKey(denom)) {
        final quantityPerPack = blisterConfig[denom]!;
        packValue = packs * (quantityPerPack * value);
      }

      total += unitsValue + packValue;
    });
    return total;
  }

  void _confirmCount() async {
    final countedAmount = getCountedTotal();
    final difference = countedAmount - widget.expectedAmount;
    final userId = widget.loggedUser['id']; // ID del usuario actual

    if (difference == 0) {
      await widget.arqueoRepository.addArqueoRecord(countedAmount, userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arqueo guardado correctamente.')),
      );
      Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Diferencia en el conteo'),
          content: const Text(
              'Hay un descuadre en el conteo. Por favor, vuelve a contar antes de guardar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver A Contar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await widget.arqueoRepository
                    .addArqueoRecord(countedAmount, userId);
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Arqueo guardado con descuadre.')),
                );
              },
              child: const Text('Guardar de todas formas'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showMovements() async {
    final transactions =
        await widget.transactionRepository.fetchAllTransactions();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovementsListScreen(
          transactions: transactions,
          loggedUser: {},
        ),
      ),
    );
  }

  Widget _buildDenominationRow(String denom) {
    final isCoin = blisterConfig.containsKey(denom);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(denom,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: unitControllers[denom],
              focusNode: unitFocusNodes[denom],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Unidades',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isCoin)
            Expanded(
              child: TextField(
                controller: packControllers[denom],
                focusNode: packFocusNodes[denom],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Blísteres',
                  border: OutlineInputBorder(),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counted = getCountedTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conteo de Caja (Arqueo)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (isAdmin) ...[
            Text(
              'Cantidad esperada en caja: ${widget.expectedAmount.toStringAsFixed(2)} €',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
          ],
          ...denominations.keys.map(_buildDenominationRow).toList(),
          const SizedBox(height: 16),
          Text(
            'Contado: ${counted.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _confirmCount,
            child: const Text('Confirmar Conteo'),
          ),
          const SizedBox(height: 20),
          if (isAdmin) ...[
            ElevatedButton(
              onPressed: _showMovements,
              child: const Text('Ver Movimientos'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArqueoHistoryScreen(
                      arqueoRepository: widget.arqueoRepository,
                    ),
                  ),
                );
              },
              child: const Text('Ver Historial de Arqueos'),
            ),
          ],
        ]),
      ),
    );
  }
}
