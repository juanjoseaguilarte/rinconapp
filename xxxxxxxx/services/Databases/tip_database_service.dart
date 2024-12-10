import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_propinas/models/tip.dart';
import 'package:intl/intl.dart';

class TipDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Método para agregar propina
  Future<void> insertTip(Tip tip) async {
    await _db.collection('tips').add(tip.toMap());
  }

  // Método para obtener propinas no pagadas
  Future<List<Tip>> fetchUnpaidTips() async {
    try {
      final snapshot =
          await _db.collection('tips').where('isPaid', isEqualTo: 0).get();
      return snapshot.docs
          .map((doc) => Tip.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching unpaid tips: $e");
      return [];
    }
  }

  // Marcar propinas como pagadas para un empleado específico
  Future<void> markTipsAsPaid(String employeeId) async {
    final batch = _db.batch();
    try {
      final snapshot = await _db
          .collection('tips')
          .where('employeeIds', arrayContains: employeeId)
          .where('isPaid', isEqualTo: 0)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isPaid': 1});
      }
      await batch.commit();
    } catch (e) {
      print("Error marking tips as paid: $e");
    }
  }

  Future<void> fetchAndPrintAllTips() async {
    try {
      final snapshot = await _db.collection('tips').get();
      final tips =
          snapshot.docs.map((doc) => Tip.fromMap(doc.id, doc.data())).toList();

      print("All Tips:");
      for (var tip in tips) {
        print(tip);
      }
    } catch (e) {
      print("Error fetching all tips: $e");
    }
  }

  // Obtener propinas no pagadas para una semana específica
  Future<List<Tip>> fetchUnpaidTipsForWeek(DateTime monday) async {
    final sunday = monday.add(const Duration(days: 6));
    final snapshot = await _db
        .collection('tips')
        .where('isPaid', isEqualTo: 0)
        .where('date', isGreaterThanOrEqualTo: monday)
        .where('date', isLessThanOrEqualTo: sunday)
        .get();
    print("Fetched tips: ${snapshot.docs.map((doc) => doc.data()).toList()}");

    return snapshot.docs.map((doc) => Tip.fromMap(doc.id, doc.data())).toList();
  }

  // Marcar propinas como pagadas para una semana específica
  Future<void> markTipsAsPaidForWeek(
      String employeeId, DateTime startOfWeek, DateTime endOfWeek) async {
    try {
      final snapshot = await _db
          .collection('tips')
          .where('date',
              isGreaterThanOrEqualTo:
                  DateFormat('yyyy-MM-dd').format(startOfWeek))
          .where('date',
              isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endOfWeek))
          .get();

      if (snapshot.docs.isEmpty) {
        print("No se encontraron propinas para actualizar.");
        return;
      }

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final Map<String, dynamic> employeePayments =
            Map<String, dynamic>.from(data['employeePayments']);

        if (employeePayments[employeeId] == 0) {
          employeePayments[employeeId] = 1;
          batch.update(doc.reference, {'employeePayments': employeePayments});
          print(
              "Actualizado estado de pago para empleado $employeeId en propina ${doc.id}");
        } else {
          print(
              "Propina ${doc.id} ya fue pagada o no aplica para el empleado $employeeId.");
        }
      }

      await batch.commit();
      print("Propinas pagadas para el empleado $employeeId en la semana.");
    } catch (e) {
      print("Error al marcar las propinas como pagadas: $e");
    }
  }

  // Método para actualizar una propina existente
  Future<void> updateTip(Tip tip) async {
    if (tip.id == null) {
      throw ArgumentError(
          "El ID de la propina no puede ser nulo al actualizar.");
    }
    await _db.collection('tips').doc(tip.id).update(tip.toMap());
  }

  // Obtener todas las propinas
  Future<List<Tip>> fetchAllTips() async {
    final snapshot = await _db.collection('tips').get();
    return snapshot.docs.map((doc) => Tip.fromMap(doc.id, doc.data())).toList();
  }

  // Actualizar el estado de pago de un empleado específico en una propina
  Future<void> updateEmployeePaymentStatus(
      String tipId, String employeeId, int status) async {
    try {
      final tipRef = _db.collection('tips').doc(tipId);

      await tipRef.update({
        'employeePayments.$employeeId': status,
      });

      print(
          "Estado de pago actualizado para el empleado $employeeId en la propina $tipId.");
    } catch (e) {
      print("Error actualizando el estado de pago: $e");
    }
  }

  // Obtener propinas para un rango semanal
  Future<List<Tip>> fetchTipsForWeek(DateTime startDay, DateTime endDay) async {
    String start = DateFormat('yyyy-MM-dd').format(startDay);
    String end = DateFormat('yyyy-MM-dd').format(endDay);

    final snapshot = await _db
        .collection('tips')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    return snapshot.docs.map((doc) => Tip.fromMap(doc.id, doc.data())).toList();
  }

  // Método alternativo para obtener propinas en un rango, con impresión de datos
  Future<List<Tip>> fetchTipsForWeek2(
      DateTime startDay, DateTime endDay) async {
    String start = DateFormat('yyyy-MM-dd').format(startDay);
    String end = DateFormat('yyyy-MM-dd').format(endDay);

    final snapshot = await _db
        .collection('tips')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    print("Propinas recuperadas entre $start y $end:");
    for (var doc in snapshot.docs) {
      print(doc.data());
    }

    return snapshot.docs.map((doc) => Tip.fromMap(doc.id, doc.data())).toList();
  }

  Future<Tip?> fetchTipByEmployeeAndWeek(
      String employeeId, DateTime monday) async {
    try {
      DateTime sunday = monday.add(const Duration(days: 6));
      String start = DateFormat('yyyy-MM-dd').format(monday);
      String end = DateFormat('yyyy-MM-dd').format(sunday);

      final snapshot = await _db
          .collection('tips')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .where('employeePayments.$employeeId',
              isEqualTo: 0) // Buscar solo propinas no pagadas
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Tip.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print("Error al obtener la propina: $e");
      return null;
    }
  }
}
