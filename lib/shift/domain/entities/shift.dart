import 'package:cloud_firestore/cloud_firestore.dart';

enum ShiftPeriod { manana, tarde }

// Define los horarios posibles como constantes o un enum si prefieres
const List<String> possibleEntryTimes = [
  "12:00",
  "12:30",
  "13:00",
  "13:30",
  "14:00",
  "19:30",
  "20:00",
  "20:30",
  "21:00",
  "LIBRE",
];

class Shift {
  final String
      id; // ID único del turno (Firestore puede generarlo o podemos crearlo)
  final String employeeId;
  final String employeeName; // Denormalizado para facilitar la visualización
  final DateTime date; // Solo la fecha, sin hora
  final ShiftPeriod period;
  final String entryTime; // Horario de entrada o "LIBRE"
  final bool isImaginaria;

  Shift({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.period,
    required this.entryTime,
    this.isImaginaria = false,
  });

  // Método para crear un ID compuesto único para Firestore
  static String generateId(
      String employeeId, DateTime date, ShiftPeriod period) {
    final dateString =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final periodString = period == ShiftPeriod.manana ? 'manana' : 'tarde';
    return '${employeeId}_${dateString}_$periodString';
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName, // Guardar nombre para facilitar consultas
      'date': Timestamp.fromDate(
          DateTime(date.year, date.month, date.day)), // Guardar solo fecha
      'period': period == ShiftPeriod.manana ? 'manana' : 'tarde',
      'entryTime': entryTime,
      'isImaginaria': isImaginaria,
    };
  }

  factory Shift.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final dateTimestamp = data['date'] as Timestamp;
    final date = dateTimestamp.toDate(); // Firestore devuelve DateTime con hora

    return Shift(
      id: doc.id,
      employeeId: data['employeeId'] as String,
      employeeName:
          data['employeeName'] as String? ?? '', // Manejar posible nulidad
      date: DateTime(date.year, date.month, date.day), // Asegurar solo fecha
      period:
          data['period'] == 'manana' ? ShiftPeriod.manana : ShiftPeriod.tarde,
      entryTime: data['entryTime'] as String,
      isImaginaria: data['isImaginaria'] as bool? ?? false,
    );
  }

  // CopyWith para facilitar la actualización en el diálogo
  Shift copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? date,
    ShiftPeriod? period,
    String? entryTime,
    bool? isImaginaria,
  }) {
    return Shift(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      period: period ?? this.period,
      entryTime: entryTime ?? this.entryTime,
      isImaginaria: isImaginaria ?? this.isImaginaria,
    );
  }
}
