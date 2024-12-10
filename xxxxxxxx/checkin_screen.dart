import 'package:flutter/material.dart';

import 'models/employee.dart';

class CheckInScreen extends StatelessWidget {
  final Employee employee;

  CheckInScreen({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fichajes - ${employee.name}')),
      body: Center(
        child: Text('Pantalla de Fichajes para ${employee.name}'),
      ),
    );
  }
}
