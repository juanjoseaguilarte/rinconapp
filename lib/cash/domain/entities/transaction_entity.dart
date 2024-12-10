// lib/cash/domain/entities/transaction_entity.dart
class TransactionEntity {
  final String id;
  final String userId;
  final String userName;
  final String type; // 'entrada' o 'salida'
  final double amount;
  final String reason;
  final DateTime date;

  TransactionEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.amount,
    required this.reason,
    required this.date,
  });

  TransactionEntity copyWith({
    String? id,
    String? userId,
    String? userName,
    String? type,
    double? amount,
    String? reason,
    DateTime? date,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      date: date ?? this.date,
    );
  }
}