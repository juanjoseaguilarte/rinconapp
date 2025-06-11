import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_propinas/shift/domain/entities/shift.dart';
import 'package:gestion_propinas/shift/domain/repositories/shift_repository.dart';

class FirebaseShiftAdapter implements ShiftRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath =
      'shifts'; // Nombre de la colección en Firestore

  @override
  Future<List<Shift>> getShiftsForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      // Asegúrate de que las fechas no tengan componentes de hora/minuto/segundo
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      // El final debe ser el inicio del día siguiente para incluir todo el último día
      final end = DateTime(endDate.year, endDate.month, endDate.day)
          .add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .get();

      return snapshot.docs.map((doc) => Shift.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching shifts: $e");
      // Considera lanzar una excepción personalizada o devolver una lista vacía
      throw Exception('Failed to fetch shifts: $e');
    }
  }

  @override
  Future<void> saveShift(Shift shift) async {
    try {
      // Usamos el ID generado (empleado_fecha_periodo) como ID del documento
      // Esto asegura que solo haya un turno por empleado, fecha y período
      final docId =
          Shift.generateId(shift.employeeId, shift.date, shift.period);
      await _firestore
          .collection(_collectionPath)
          .doc(docId)
          .set(shift.toMap());
    } catch (e) {
      print("Error saving shift: $e");
      throw Exception('Failed to save shift: $e');
    }
  }

  @override
  Future<void> deleteShift(String shiftId) async {
    try {
      await _firestore.collection(_collectionPath).doc(shiftId).delete();
    } catch (e) {
      print("Error deleting shift: $e");
      throw Exception('Failed to delete shift: $e');
    }
  }
}
