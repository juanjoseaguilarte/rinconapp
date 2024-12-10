// lib/infrastructure/repositories/firebase_arqueo_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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


  
}
