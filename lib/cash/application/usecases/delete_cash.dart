import 'package:gestion_propinas/cash/domain/repositories/cash_repository.dart';

class DeleteCash {
  final CashRepository repository;

  DeleteCash(this.repository);

  Future<void> call(String id) {
    return repository.deleteCash(id);
  }
}