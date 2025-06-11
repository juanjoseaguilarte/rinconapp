import 'package:gestion_propinas/cash/domain/entities/transaction_entity.dart';

abstract class CashTransactionRepository {
  Future<void> addTransaction({
    required String userId,
    required String userName,
    required String type,
    required double amount,
    required String reason,
    required DateTime date,
  });

  Future<List<TransactionEntity>> fetchAllTransactions();
  Future<List<TransactionEntity>> fetchTransactionsSince(DateTime since);
}
