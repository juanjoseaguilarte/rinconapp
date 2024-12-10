
import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';

class FetchTips {
  final TipRepository repository;

  FetchTips(this.repository);

  Future<List<Tip>> execute() async {
    return await repository.fetchTips();
  }
}
