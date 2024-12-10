import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/application/usecases/fetch_cashs.dart';
import 'package:gestion_propinas/cash/domain/entities/cash.dart';

class CashAdminScreen extends StatefulWidget {
  final FetchCashs fetchCashsUseCase;

  const CashAdminScreen({Key? key, required this.fetchCashsUseCase}) : super(key: key);

  @override
  _CashAdminScreenState createState() => _CashAdminScreenState();
}

class _CashAdminScreenState extends State<CashAdminScreen> {
  List<Cash> _cashList = [];

  @override
  void initState() {
    super.initState();
    _loadCash();
  }

  Future<void> _loadCash() async {
    final result = await widget.fetchCashsUseCase();
    setState(() {
      _cashList = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Administrar Caja'),
      ),
      body: ListView.builder(
        itemCount: _cashList.length,
        itemBuilder: (context, index) {
          final cash = _cashList[index];
          return ListTile(
            title: Text('ID: ${cash.id}'),
            subtitle: Text('Amount: ${cash.amount} €'),
          );
        },
      ),
    );
  }
}