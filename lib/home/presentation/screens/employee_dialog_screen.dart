import 'package:flutter/material.dart';

Future<void> showPinDialog({
  required BuildContext context,
  required TextEditingController pinController,
  required Map<String, dynamic> user,
  required Future<bool> Function(int pin) validatePin,
  required Function onSuccess,
}) async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Ingrese PIN para ${user['name']}'),
      content: TextField(
        controller: pinController,
        decoration: const InputDecoration(hintText: 'PIN'),
        keyboardType: TextInputType.number,
        obscureText: true,
      ),
      actions: [
        TextButton(
          onPressed: () {
            pinController.clear();
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final pin = int.tryParse(pinController.text) ?? -1;
            final isValid = await validatePin(pin);
            Navigator.of(context).pop();
            pinController.clear();
            if (isValid) {
              onSuccess();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN incorrecto')),
              );
            }
          },
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}
