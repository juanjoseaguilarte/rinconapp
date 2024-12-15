// lib/presentation/screens/cash_menu_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/infrastucture/repositories/firebase_arqueo_repository.dart';
import 'package:gestion_propinas/cash/infrastucture/repositories/firebase_cash_adapter.dart';
import 'package:gestion_propinas/cash/presentation/screens/cash_count_screen.dart';
import 'package:gestion_propinas/cash/presentation/screens/cash_entry_form_screen.dart';
import 'package:gestion_propinas/cash/presentation/screens/movements_list_screen.dart';
import 'package:gestion_propinas/cash/presentation/screens/pay_screen.dart';

class CashMenuScreen extends StatelessWidget {
  final Map<String, dynamic> loggedUser;

  const CashMenuScreen({Key? key, required this.loggedUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cashTransactionRepository = FirebaseCashTransactionRepository(
      firestore: FirebaseFirestore.instance,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opciones de Caja'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 20, // Espacio horizontal entre botones
          runSpacing: 20, // Espacio vertical entre filas
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CashEntryFormScreen(
                      loggedUser: loggedUser,
                      transactionType: 'entrada',
                      cashTransactionRepository: cashTransactionRepository,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 100), // Cuadrado de 100x100
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(0), // esquinas no redondeadas
                ),
              ),
              child: const Text('Entrada Dinero Caja'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CashEntryFormScreen(
                      loggedUser: loggedUser,
                      transactionType: 'salida',
                      cashTransactionRepository: cashTransactionRepository,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 100), // Cuadrado de 100x100
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(0), // esquinas no redondeadas
                ),
              ),
              child: const Text('Salida Dinero Caja'),
            ),
            ElevatedButton(
              onPressed: () async {
                final arqueoRepository = FirebaseArqueoRepository(
                  firestore: FirebaseFirestore.instance,
                );
                final transactionRepo = FirebaseCashTransactionRepository(
                  firestore: FirebaseFirestore.instance,
                );

                double initialAmount =
                    await arqueoRepository.getInitialAmount();
                DateTime? lastArqueoDate =
                    await arqueoRepository.getLastArqueoDate() ??
                        DateTime(2000);

                final transactions = await transactionRepo
                    .fetchTransactionsSince(lastArqueoDate);

                double entradas = 0.0;
                double salidas = 0.0;
                for (var t in transactions) {
                  if (t.type == 'entrada') {
                    entradas += t.amount;
                  } else if (t.type == 'salida') {
                    salidas += t.amount;
                  }
                }

                final expectedAmount = initialAmount + entradas - salidas;
                final loggedUser = this.loggedUser;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CashCountScreen(
                      expectedAmount: expectedAmount,
                      arqueoRepository: arqueoRepository,
                      loggedUser: loggedUser,
                      transactionRepository: transactionRepo,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 100), // Cuadrado de 100x100
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(0), // esquinas no redondeadas
                ),
              ),
              child: const Text('Arqueo Domingo'),
            ),
            if (loggedUser['role'] == 'Admin')
              ElevatedButton(
                onPressed: () async {
                  final transactions =
                      await cashTransactionRepository.fetchAllTransactions();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovementsListScreen(
                        transactions: transactions,
                        loggedUser: loggedUser,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 100), // Cuadrado de 100x100
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(0), // esquinas no redondeadas
                  ),
                ),
                child: const Text('Listado De Movimientos'),
              ),
            ElevatedButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PayScreen(
                      loggedUser: loggedUser,
                      cashTransactionRepository: cashTransactionRepository,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 100), // Cuadrado de 100x100
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(0), // esquinas no redondeadas
                ),
              ),
              child: const Text('Cobro Mesas Cashlogy Bloqueado'),
            ),
          ],
        ),
      ),
    );
  }
}
