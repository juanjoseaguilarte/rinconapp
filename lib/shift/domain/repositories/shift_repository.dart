import 'package:gestion_propinas/shift/domain/entities/shift.dart';

abstract class ShiftRepository {
  /// Obtiene los turnos para un rango de fechas específico.
  Future<List<Shift>> getShiftsForDateRange(
      DateTime startDate, DateTime endDate);

  /// Guarda (crea o actualiza) un turno. Usa el ID generado.
  Future<void> saveShift(Shift shift);

  /// Elimina un turno basado en su ID único (generado con employeeId, date, period).
  Future<void> deleteShift(String shiftId);
}
