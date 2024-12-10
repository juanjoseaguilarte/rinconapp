

abstract class ArqueoRepository {
  Future<double> getInitialAmount();
  Future<void> setInitialAmount(double amount);
  Future<DateTime?> getLastArqueoDate();
  Future<void> setLastArqueoDate(DateTime date);
}
