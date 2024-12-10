class Tip {
  final String? id; // Campo opcional para identificar la propina
  final double amount;
  final DateTime date;
  final String shift;
  final Map<String, int> employeePayments;

  Tip({
    this.id,
    required this.amount,
    required this.date,
    required this.shift,
    required this.employeePayments,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'shift': shift,
      'employeePayments': employeePayments,
    };
  }

  // Crear un método fromMap para cargar los datos
  static Tip fromMap(String id, Map<String, dynamic> data) {
    return Tip(
      id: id,
      amount: data['amount'],
      date: DateTime.parse(data['date']),
      shift: data['shift'],
      employeePayments: Map<String, int>.from(data['employeePayments']),
    );
  }
}
