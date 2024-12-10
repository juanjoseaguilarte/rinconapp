// lib/infrastructure/repositories/firebase_cash_transaction_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_propinas/cash/domain/entities/transaction_entity.dart';
import 'package:gestion_propinas/cash/domain/repositories/cash_transation_repository.dart';

class FirebaseCashTransactionRepository implements CashTransactionRepository {
  final FirebaseFirestore firestore;

  FirebaseCashTransactionRepository({required this.firestore});

  @override
  Future<void> addTransaction({
    required String userId,
    required String userName,
    required String type,
    required double amount,
    required String reason,
    required DateTime date,
  }) {
    return firestore.collection('cash_transactions').add({
      'userId': userId,
      'userName': userName,
      'type': type,
      'amount': amount,
      'reason': reason,
      'date': date.toIso8601String(),
    });
  }

  Future<List<TransactionEntity>> fetchTransactionsSince(DateTime since) async {
    final query = await firestore
        .collection('cash_transactions')
        .where('date', isGreaterThanOrEqualTo: since.toIso8601String())
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return TransactionEntity(
        id: doc.id,
        userId: data['userId'],
        userName: data['userName'],
        type: data['type'],
        amount: (data['amount'] as num).toDouble(),
        reason: data['reason'],
        date: DateTime.parse(data['date']),
      );
    }).toList();
  }

  @override
  Future<List<TransactionEntity>> fetchAllTransactions() async {
    final query = await firestore.collection('cash_transactions').get();

    return query.docs.map((doc) {
      final data = doc.data();
      return TransactionEntity(
        id: doc.id,
        userId: data['userId'],
        userName: data['userName'],
        type: data['type'],
        amount: (data['amount'] as num).toDouble(),
        reason: data['reason'],
        date: DateTime.parse(data['date']),
      );
    }).toList();
  }
}
