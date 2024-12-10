import 'package:gestion_propinas/tip/application/usecases/add_tip.dart';
import 'package:gestion_propinas/tip/application/usecases/delete_tip.dart';
import 'package:gestion_propinas/tip/application/usecases/fetch_tips.dart';
import 'package:gestion_propinas/tip/application/usecases/update_tip.dart';
import 'package:gestion_propinas/tip/domain/entities/tip.dart';

class TipService {
  final FetchTips fetchTipsUseCase;
  final AddTip addTipUseCase;
  final UpdateTip updateTipUseCase;
  final DeleteTip deleteTipUseCase;

  TipService({
    required this.fetchTipsUseCase,
    required this.addTipUseCase,
    required this.updateTipUseCase,
    required this.deleteTipUseCase,
  });

  /// Obtiene todas las propinas
  Future<List<Tip>> getAllTips() async {
    return await fetchTipsUseCase.execute();
  }

  /// Añade una nueva propina
  Future<void> addTip(Tip tip) async {
    await addTipUseCase.execute(tip);
  }

  /// Actualiza una propina existente
  Future<void> updateTip(Tip tip) async {
    await updateTipUseCase.execute(tip);
  }

  /// Elimina una propina por su ID
  Future<void> deleteTip(String id) async {
    await deleteTipUseCase.execute(id);
  }
}
