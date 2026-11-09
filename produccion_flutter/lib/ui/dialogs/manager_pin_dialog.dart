import 'package:flutter/material.dart';

class ManagerPinDialog extends StatefulWidget {
  const ManagerPinDialog({Key? key}) : super(key: key);

  @override
  State<ManagerPinDialog> createState() => _ManagerPinDialogState();
}

class _ManagerPinDialogState extends State<ManagerPinDialog> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Acceso de Gerente"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Ingrese el PIN de acceso para modificar este producto:"),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "PIN (ej. 1234)",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_pinController.text.trim() == "1234") {
              Navigator.of(context).pop(true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("PIN incorrecto")),
              );
            }
          },
          child: const Text("Aceptar"),
        ),
      ],
    );
  }
}
