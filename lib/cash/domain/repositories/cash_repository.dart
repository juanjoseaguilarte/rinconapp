// Interfaz que define las operaciones necesarias sobre la entidad Cash
import 'package:gestion_propinas/cash/domain/entities/cash.dart';

abstract class CashRepository {
  Future<void> addCash(Cash cash);
  Future<void> updateCash(Cash cash);
  Future<void> deleteCash(String id);
  Future<Cash?> getCashById(String id);
  Future<List<Cash>> fetchAllCash();
}