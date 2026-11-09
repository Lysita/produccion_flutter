import 'package:flutter/material.dart';
import '../../models/product_item.dart';

class ModifyProductDialog extends StatefulWidget {
  final ProductItem product;

  const ModifyProductDialog({Key? key, required this.product}) : super(key: key);

  @override
  State<ModifyProductDialog> createState() => _ModifyProductDialogState();
}

class _ModifyProductDialogState extends State<ModifyProductDialog> {
  late TextEditingController _nameController;
  late TextEditingController _rateController;
  late bool _addToRotulos;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);

    final rate = widget.product.ratePerHour;
    _rateController = TextEditingController(
      text: rate == rate.roundToDouble() ? rate.toInt().toString() : rate.toString(),
    );
    _addToRotulos = widget.product.addToRotulos;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Modificar Producto"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAlignment.start,
          children: [
            const Text("Nombre del Producto:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            const Text("Cantidad producida por Hora:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Ej. 50"),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Sumar a Rótulos automáticamente", style: TextStyle(fontSize: 14)),
              value: _addToRotulos,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _addToRotulos = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
          onPressed: () {
            final newName = _nameController.text.trim();
            final rateStr = _rateController.text.trim();

            if (newName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("El nombre no puede estar vacío")),
              );
              return;
            }

            final newRate = double.tryParse(rateStr) ?? widget.product.ratePerHour;

            widget.product.name = newName;
            widget.product.ratePerHour = newRate;
            widget.product.addToRotulos = _addToRotulos;

            Navigator.of(context).pop(true);
          },
          child: const Text("Guardar", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
