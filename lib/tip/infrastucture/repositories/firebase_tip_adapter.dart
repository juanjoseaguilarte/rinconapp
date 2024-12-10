import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';

class FirebaseTipAdapter implements TipRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<void> addTip(Tip tip) async {
    try {
      await _db.collection('tips').add(tip.toMap());
      print('Propina guardada exitosamente en Firestore.');
    } catch (e) {
      print('Error al guardar la propina: $e');
    }
  }

  @override
  Future<List<Tip>> fetchTips() async {
    final snapshot = await _db
        .collection('tips')
        .where('isDeleted', isEqualTo: false)
        // .where('employeePayments', isNotEqualTo: 'LWFwojdvqZCuppnPB9Be')
        .get();
    return snapshot.docs.map((doc) => Tip.fromMap(doc.id, doc.data())).toList();
  }

  @override
  Future<void> updateTip(Tip tip) async {
    try {
      await _db.collection('tips').doc(tip.id).update(tip.toMap());
    } catch (e) {
      print("Error al actualizar la propina: $e");
    }
  }

  @override
  Future<void> deleteTip(String id) async {
    try {
      await _db.collection('tips').doc(id).update({'isDeleted': true});
    } catch (e) {
      print("Error al realizar el borrado lógico: $e");
    }
  }
}
