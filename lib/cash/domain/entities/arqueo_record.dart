import 'package:cloud_firestore/cloud_firestore.dart';

class ArqueoRecord {
  final double amount;
  final String userId;
  final DateTime date;

  ArqueoRecord({
    required this.amount,
    required this.userId,
    required this.date,
  });

  factory ArqueoRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArqueoRecord(
      amount: (data['amount'] as num).toDouble(),
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}