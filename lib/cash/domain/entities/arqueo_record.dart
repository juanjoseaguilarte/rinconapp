import 'package:cloud_firestore/cloud_firestore.dart';

class ArqueoRecord {
  final String id;
  final double expectedAmount;
  final double countedAmount;
  final String userId;
  final DateTime date;

  ArqueoRecord({
    required this.id,
    required this.expectedAmount,
    required this.countedAmount,
    required this.userId,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'expectedAmount': expectedAmount,
      'countedAmount': countedAmount,
      'userId': userId,
      'date': date.toIso8601String(),
    };
  }

  factory ArqueoRecord.fromMap(Map<String, dynamic> map) {
    return ArqueoRecord(
      id: '',
      expectedAmount: map['expectedAmount'],
      countedAmount: map['countedAmount'],
      userId: map['userId'],
      date: DateTime.parse(map['date']),
    );
  }

  factory ArqueoRecord.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    // Para registros nuevos
    final expectedAmount = data['expectedAmount'] as num?;
    final countedAmount = data['countedAmount'] as num?;

    // Para registros antiguos
    final amount = data['amount'] as num?;

    return ArqueoRecord(
      id: documentId,
      expectedAmount: expectedAmount?.toDouble() ?? amount?.toDouble() ?? 0.0,
      countedAmount: countedAmount?.toDouble() ??
          amount?.toDouble() ??
          0.0, // Para registros antiguos, usamos amount
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}
