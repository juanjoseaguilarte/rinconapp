import 'package:gestion_propinas/cash/domain/entities/cash.dart';
import 'package:gestion_propinas/cash/domain/repositories/cash_repository.dart';

class UpdateCash {
  final CashRepository repository;

  UpdateCash(this.repository);

  Future<void> call(Cash cash) {
    return repository.updateCash(cash);
  }
}