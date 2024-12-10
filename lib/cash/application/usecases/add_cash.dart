import 'package:gestion_propinas/cash/domain/entities/cash.dart';
import 'package:gestion_propinas/cash/domain/repositories/cash_repository.dart';

class AddCash {
  final CashRepository repository;

  AddCash(this.repository);

  Future<void> call(Cash cash) {
    return repository.addCash(cash);
  }
}