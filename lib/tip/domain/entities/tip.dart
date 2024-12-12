class Tip {
  final String? id;
  final double amount;
  final DateTime date;
  final String shift;
  final Map<String, Map<String, dynamic>> employeePayments; // Incluye isDeleted
  final double adminShare;
  final bool isDeleted;

  Tip({
    this.id,
    required this.amount,
    required this.date,
    required this.shift,
    required this.employeePayments,
    required this.adminShare,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'shift': shift,
      'employeePayments': employeePayments.map((key, value) => MapEntry(key, {
            'cash': value['cash'] ?? 0.0,
            'card': value['card'] ?? 0.0,
            'isDeleted': value['isDeleted'] ?? false,
          })),
      'adminShare': adminShare,
      'isDeleted': isDeleted,
    };
  }

  static Tip fromMap(String id, Map<String, dynamic> data) {
    final employeePayments = (data['employeePayments'] as Map<dynamic, dynamic>)
        .map<String, Map<String, dynamic>>((key, value) {
      final Map<String, dynamic> parsedValue =
          Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
      return MapEntry(key.toString(), {
        'cash': (parsedValue['cash'] as num?)?.toDouble() ?? 0.0,
        'card': (parsedValue['card'] as num?)?.toDouble() ?? 0.0,
        'isDeleted': parsedValue['isDeleted'] ?? false,
      });
    });

    return Tip(
      id: id,
      amount: (data['amount'] as num).toDouble(),
      date: DateTime.parse(data['date']),
      shift: data['shift'] ?? '',
      employeePayments: employeePayments,
      adminShare: (data['adminShare'] as num).toDouble(),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Tip copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? shift,
    Map<String, Map<String, dynamic>>? employeePayments,
    double? adminShare,
    bool? isDeleted,
  }) {
    return Tip(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      shift: shift ?? this.shift,
      employeePayments: employeePayments ?? this.employeePayments,
      adminShare: adminShare ?? this.adminShare,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
