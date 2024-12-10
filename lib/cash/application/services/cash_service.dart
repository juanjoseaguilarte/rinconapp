import 'package:gestion_propinas/cash/domain/entities/cash.dart';
import 'package:gestion_propinas/cash/domain/repositories/cash_repository.dart';

class CashService {
  final CashRepository repository;

  CashService(this.repository);

  Future<void> addCash(Cash cash) async {
    await repository.addCash(cash);
  }

  Future<void> updateCash(Cash cash) async {
    await repository.updateCash(cash);
  }

  Future<void> deleteCash(String id) async {
    await repository.deleteCash(id);
  }

  Future<Cash?> getCashById(String id) async {
    return repository.getCashById(id);
  }

  Future<List<Cash>> fetchAllCash() async {
    return repository.fetchAllCash();
  }
}
