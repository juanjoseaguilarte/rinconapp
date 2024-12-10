import '../../domain/repositories/tip_repository.dart';

class DeleteTip {
  final TipRepository repository;

  DeleteTip(this.repository);

  Future<void> execute(String id) async {
    await repository.deleteTip(id);
  }
}
