import 'package:gestion_propinas/shift/domain/entities/shift.dart';
import 'package:gestion_propinas/shift/domain/repositories/shift_repository.dart';

class ShiftService {
  final ShiftRepository _shiftRepository;

  ShiftService(this._shiftRepository);

  Future<List<Shift>> getShiftsForWeek(DateTime weekStartDate) async {
    final weekEndDate = weekStartDate.add(const Duration(days: 6));
    return await _shiftRepository.getShiftsForDateRange(
        weekStartDate, weekEndDate);
  }

  Future<void> saveShift(Shift shift) async {
    // El ID se genera en el adaptador o antes de llamar a saveShift
    await _shiftRepository.saveShift(shift);
  }

  Future<void> deleteShift(
      String employeeId, DateTime date, ShiftPeriod period) async {
    final shiftId = Shift.generateId(employeeId, date, period);
    await _shiftRepository.deleteShift(shiftId);
  }
}
