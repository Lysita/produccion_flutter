import 'package:flutter/material.dart';

class EmployeeDialog extends StatefulWidget {
  final String currentName;
  final bool isChanging;

  const EmployeeDialog({
    Key? key,
    required this.currentName,
    required this.isChanging,
  }) : super(key: key);

  @override
  State<EmployeeDialog> createState() => _EmployeeDialogState();
}

class _EmployeeDialogState extends State<EmployeeDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.isChanging,
      child: AlertDialog(
        title: const Text("Identificación de Operador"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAlignment.start,
          children: [
            const Text(
              "Por favor ingrese el nombre y apellido del operador de producción:",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Ej. Juan Perez",
              ),
            ),
          ],
        ),
        actions: [
          if (widget.isChanging)
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text("Cancelar"),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
            ),
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(context).pop(text);
              }
            },
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
