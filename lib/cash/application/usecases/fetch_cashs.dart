import 'package:gestion_propinas/cash/domain/entities/cash.dart';
import 'package:gestion_propinas/cash/domain/repositories/cash_repository.dart';

class FetchCashs {
  final CashRepository repository;

  FetchCashs(this.repository);

  Future<List<Cash>> call() {
    return repository.fetchAllCash();
  }
}