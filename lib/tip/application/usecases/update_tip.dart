import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';


class UpdateTip {
  final TipRepository repository;

  UpdateTip(this.repository);

  Future<void> execute(Tip tip) async {
    await repository.updateTip(tip);
  }
}
