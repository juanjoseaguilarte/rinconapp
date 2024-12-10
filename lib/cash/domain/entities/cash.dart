// Representa el estado de caja: cantidad total y fecha de actualización
class Cash {
  final String id;
  final double amount;
  final DateTime updatedAt;

  Cash({
    required this.id,
    required this.amount,
    required this.updatedAt,
  });

  Cash copyWith({
    String? id,
    double? amount,
    DateTime? updatedAt,
  }) {
    return Cash(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}