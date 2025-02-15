// lib/infrastructure/repositories/firebase_arqueo_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_propinas/cash/domain/entities/arqueo_record.dart';
import 'package:gestion_propinas/cash/domain/repositories/arqueo_repository.dart';

class FirebaseArqueoRepository implements ArqueoRepository {
  final FirebaseFirestore firestore;

  FirebaseArqueoRepository({required this.firestore});

  @override
  Future<double> getInitialAmount() async {
    final doc =
        await firestore.collection('config').doc('initial_amount').get();
    if (doc.exists) {
      return (doc.data()?['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  @override
  Future<void> setInitialAmount(double amount) {
    return firestore
        .collection('config')
        .doc('initial_amount')
        .set({'amount': amount, 'updatedAt': DateTime.now().toIso8601String()});
  }

  @override
  Future<DateTime?> getLastArqueoDate() async {
    // Opcional: si quieres llevar control de la fecha del último arqueo
    final doc =
        await firestore.collection('config').doc('initial_amount').get();
    if (doc.exists && doc.data()?['updatedAt'] != null) {
      return DateTime.parse(doc.data()?['updatedAt']);
    }
    return null;
  }

  @override
  Future<void> setLastArqueoDate(DateTime date) {
    return firestore
        .collection('config')
        .doc('initial_amount')
        .update({'updatedAt': date.toIso8601String()});
  }

  @override
  Future<void> addArqueoRecord(
      double expectedAmount, double countedAmount, String userId) async {
    await firestore.collection('arqueos').add({
      'expectedAmount': expectedAmount,
      'countedAmount': countedAmount,
      'amount':
          expectedAmount, // Para mantener compatibilidad con registros antiguos
      'userId': userId,
      'date': FieldValue.serverTimestamp(),
    });
    await setInitialAmount(countedAmount); // Cambiado a countedAmount
  }

  @override
  Future<List<ArqueoRecord>> getArqueoHistory() async {
    try {
      final snapshot = await firestore
          .collection('arqueos')
          .orderBy('date', descending: true)
          .get();

      List<ArqueoRecord> records = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          print('------------------------------');
          print('ID: ${doc.id}');
          print('expectedAmount: ${data['expectedAmount']}');
          print('countedAmount: ${data['countedAmount']}');
          print('amount: ${data['amount']}');
          print('userId: ${data['userId']}');
          print('date: ${data['date']}');

          final record = ArqueoRecord.fromFirestore(data, doc.id);
          records.add(record);

          print('Valores convertidos:');
          print('expectedAmount: ${record.expectedAmount}');
          print('countedAmount: ${record.countedAmount}');
          print('------------------------------');
        } catch (e) {
          print('Error en documento ${doc.id}: $e');
        }
      }

      return records;
    } catch (e) {
      print('Error general: $e');
      throw e;
    }
  }
}
