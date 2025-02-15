import 'package:gestion_propinas/cash/domain/entities/arqueo_record.dart';

abstract class ArqueoRepository {
  Future<double> getInitialAmount();
  Future<void> setInitialAmount(double amount);
  Future<DateTime?> getLastArqueoDate();
  Future<void> setLastArqueoDate(DateTime date);
  Future<void> addArqueoRecord(double expectedAmount, double countedAmount, String userId);
  Future<List<ArqueoRecord>> getArqueoHistory();
}
