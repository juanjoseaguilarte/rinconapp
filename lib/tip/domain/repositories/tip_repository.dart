
import 'package:gestion_propinas/tip/domain/entities/tip.dart';

abstract class TipRepository {
  Future<void> addTip(Tip tip);
  Future<List<Tip>> fetchTips();
  Future<void> updateTip(Tip tip);
  Future<void> deleteTip(String id);
}
