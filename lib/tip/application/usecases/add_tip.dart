import 'package:gestion_propinas/tip/domain/entities/tip.dart';

import '../../domain/repositories/tip_repository.dart';

class AddTip {
  final TipRepository repository;

  AddTip(this.repository);

  Future<void> execute(Tip tip) async {
    await repository.addTip(tip);
  }
}
