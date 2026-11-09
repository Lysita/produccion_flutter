import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product_item.dart';
import '../../services/storage_service.dart';
import '../../services/report_generator_service.dart';
import '../dialogs/employee_dialog.dart';
import '../dialogs/manager_pin_dialog.dart';
import '../dialogs/modify_product_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String targetWhatsAppPhone = "5493464539349";

  List<ProductItem> productList = [];
  String employeeName = "";
  DateTime selectedDate = DateTime.now();

  final TextEditingController hoursController = TextEditingController();
  final TextEditingController rotulosController = TextEditingController();

  Map<int, TextEditingController> qtyControllers = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    hoursController.dispose();
    rotulosController.dispose();
    qtyControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  Future<void> _initData() async {
    // Setup default products
    productList = ProductItem.defaultNames
        .asMap()
        .entries
        .map((e) => ProductItem(name: e.value, originalIndex: e.key))
        .toList();

    await StorageService.loadProductCustomizations(productList);

    employeeName = await StorageService.getEmployeeName();
    if (employeeName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showEmployeeDialog(isChanging: false));
    } else {
      await StorageService.loadEmployeeFrequencies(employeeName, productList);
    }

    final stateMap = await StorageService.loadSavedState(productList);
    hoursController.text = stateMap["hours_worked"] ?? "";
    rotulosController.text = stateMap["rotulos_val"] ?? "";
    selectedDate = stateMap["selected_date"] ?? DateTime.now();

    _updateControllers();
    _sortProducts();
    setState(() {});
  }

  void _updateControllers() {
    for (int i = 0; i < productList.length; i++) {
      final p = productList[i];
      if (!qtyControllers.containsKey(i)) {
        qtyControllers[i] = TextEditingController();
      }
      if (p.isZeroMarked) {
        qtyControllers[i]!.text = "0";
      } else if (p.quantity > 0) {
        qtyControllers[i]!.text = p.quantity.toString();
      } else {
        qtyControllers[i]!.text = "";
      }
    }
  }

  int _getProductSortPriority(ProductItem item) {
    if (item.quantity > 0 || item.isZeroMarked) {
      return 0;
    } else if (_isLowPriorityProduct(item)) {
      return 2;
    } else {
      return 1;
    }
  }

  bool _isLowPriorityProduct(ProductItem item) {
    final lower = item.name.toLowerCase().trim();
    if (lower == "empanadas x3" || lower == "empanada x3") {
      return false;
    }
    return lower.contains("pizza") || lower.contains("ensalada") || lower.contains("empanadas x3");
  }

  void _sortProducts() {
    productList.sort((p1, p2) {
      int prio1 = _getProductSortPriority(p1);
      int prio2 = _getProductSortPriority(p2);
      if (prio1 != prio2) {
        return prio1.compareTo(prio2);
      }
      if (p1.frequency != p2.frequency) {
        return p2.frequency.compareTo(p1.frequency);
      }
      return p1.originalIndex.compareTo(p2.originalIndex);
    });
  }

  Future<void> _saveState() async {
    await StorageService.saveCurrentState(
      productList: productList,
      hoursWorked: hoursController.text,
      rotulosVal: rotulosController.text,
      selectedDate: selectedDate,
    );
  }

  void _autoUpdateRotulos() {
    int autoRotulos = 0;
    for (var p in productList) {
      if (p.addToRotulos && p.quantity > 0) {
        autoRotulos += p.quantity;
      }
    }
    if (autoRotulos > 0) {
      rotulosController.text = autoRotulos.toString();
    } else {
      rotulosController.text = "";
    }
  }

  double _calculateEstimatedHours() {
    double hours = 0.0;
    int autoRotulos = 0;

    for (var item in productList) {
      if (item.quantity > 0) {
        if (item.ratePerHour > 0) {
          hours += (item.quantity / item.ratePerHour);
        }
        if (item.addToRotulos) {
          autoRotulos += item.quantity;
        }
      }
    }

    final rotulosVal = int.tryParse(rotulosController.text.trim()) ?? 0;
    final extraRotulos = rotulosVal - autoRotulos;
    if (extraRotulos > 0) {
      hours += (extraRotulos / 280.0);
    }

    return hours;
  }

  int _calculateTotalUnits() {
    int total = 0;
    for (var p in productList) {
      total += p.quantity;
    }
    return total;
  }

  Future<void> _showEmployeeDialog({required bool isChanging}) async {
    final newName = await showDialog<String>(
      context: context,
      barrierDismissible: isChanging,
      builder: (ctx) => EmployeeDialog(currentName: employeeName, isChanging: isChanging),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        employeeName = newName;
      });
      await StorageService.saveEmployeeName(employeeName);
      await StorageService.loadEmployeeFrequencies(employeeName, productList);
      _sortProducts();
      _updateControllers();
      setState(() {});
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          selectedDate.hour,
          selectedDate.minute,
        );
      });
      _saveState();
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar borrado"),
        content: const Text("¿Está seguro de que desea borrar todos los datos e importes ingresados?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Borrar todo", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAllData(productList);
      hoursController.clear();
      rotulosController.clear();
      selectedDate = DateTime.now();
      _sortProducts();
      _updateControllers();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Se han borrado todos los datos ingresados")),
      );
    }
  }

  Future<void> _onProductLongClick(ProductItem item, int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ManagerPinDialog(),
    );

    if (ok == true) {
      final modified = await showDialog<bool>(
        context: context,
        builder: (ctx) => ModifyProductDialog(product: item),
      );

      if (modified == true) {
        await StorageService.saveProductCustomization(item, item.originalIndex);
        _autoUpdateRotulos();
        _saveState();
        setState(() {});
      }
    }
  }

  Future<void> _sendWhatsAppReport() async {
    if (employeeName.isEmpty) {
      _showEmployeeDialog(isChanging: false);
      return;
    }

    final totalUnits = _calculateTotalUnits();
    if (totalUnits == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay unidades de producción cargadas")),
      );
      return;
    }

    await StorageService.recordEmployeeProductUsage(employeeName, productList);

    final hoursWorked = double.tryParse(hoursController.text.trim()) ?? 0.0;
    final rotulosVal = int.tryParse(rotulosController.text.trim()) ?? 0;
    final estHours = _calculateEstimatedHours();

    final imageFile = await ReportGeneratorService.generateReportImage(
      operatorName: employeeName,
      reportDate: selectedDate,
      hoursWorked: hoursWorked,
      rotulos: rotulosVal,
      productList: productList,
      totalUnits: totalUnits,
      estimatedHours: estHours,
    );

    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al generar la imagen del reporte")),
      );
      return;
    }

    try {
      await Share.shareXFiles([XFile(imageFile.path)], text: 'Boleta de Producción - Casa Tadiello');
    } catch (e) {
      final textReport = _buildTextReport(hoursWorked, rotulosVal, totalUnits, estHours);
      final waUrl = Uri.parse("https://wa.me/$targetWhatsAppPhone?text=${Uri.encodeComponent(textReport)}");
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _buildTextReport(double hoursWorked, int rotulosVal, int totalUnits, double estHours) {
    final dateStr = DateFormat("dd/MM/yyyy HH:mm").format(selectedDate);
    final sb = StringBuffer()
      ..writeln("CASA TADIELLO")
      ..writeln("BOLETA DE PRODUCCIÓN")
      ..writeln("OPERADOR: ${employeeName.toUpperCase()}")
      ..writeln("FECHA: $dateStr")
      ..writeln("HORAS TRABAJADAS: ${hoursWorked.toStringAsFixed(2)}")
      ..writeln("ROTULOS: $rotulosVal")
      ..writeln("PRODUCTOS:");

    for (var p in productList) {
      if (p.quantity > 0) {
        sb.writeln("PRODUCTO: ${p.name} | CANTIDAD: ${p.quantity}");
      }
    }

    sb.writeln("TOTAL UNIDADES: $totalUnits");
    sb.writeln("HORAS RENDIMIENTO: ${estHours.toStringAsFixed(2)}");

    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    final totalUnits = _calculateTotalUnits();
    final estHours = _calculateEstimatedHours();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Container(
              color: const Color(0xFF3F51B5),
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showEmployeeDialog(isChanging: true),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAlignment.start,
                        children: [
                          const Text(
                            "Operador:",
                            style: TextStyle(color: Color(0xFFC5CAE9), fontSize: 14),
                          ),
                          Text(
                            employeeName.isEmpty ? "Cargando..." : employeeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6BC0),
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () => _showEmployeeDialog(isChanging: true),
                    child: const Text("Cambiar", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: _clearAllData,
                    child: const Text("Borrar Todo", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ],
              ),
            ),

            // 3-Column Inputs Row (Fecha, Horas Trab., Rótulos)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 1. FECHA
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        const Text(
                          "Fecha:",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _selectDate,
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white,
                            ),
                            child: Text(
                              DateFormat("dd/MM").format(selectedDate),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. HORAS TRABAJADAS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        const Text(
                          "Horas Trab.:",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 42,
                          child: TextField(
                            controller: hoursController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              hintText: "Ej. 8",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4),
                            ),
                            onChanged: (_) => _saveState(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. RÓTULOS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        const Text(
                          "Rótulos:",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 42,
                          child: TextField(
                            controller: rotulosController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              hintText: "0",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4),
                            ),
                            onChanged: (_) {
                              _saveState();
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Table Header
            Container(
              height: 40,
              margin: const EdgeInsets.only(top: 4),
              color: const Color(0xFFE8EAF6),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Expanded(
                    child: Text(
                      "PRODUCTO",
                      style: TextStyle(color: Color(0xFF3F51B5), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    "CANTIDAD",
                    style: TextStyle(color: Color(0xFF3F51B5), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Product List
            Expanded(
              child: ListView.builder(
                itemCount: productList.length,
                itemBuilder: (context, index) {
                  final p = productList[index];
                  final isActive = p.quantity > 0 || p.isZeroMarked;

                  return InkWell(
                    onLongPress: () => _onProductLongClick(p, index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFE8F5E9) : Colors.white,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 16,
                                color: isActive ? const Color(0xFF1B5E20) : const Color(0xFF222222),
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            height: 42,
                            child: TextField(
                              controller: qtyControllers[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isActive ? const Color(0xFF1B5E20) : Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: "0",
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                filled: true,
                                fillColor: isActive ? const Color(0xFFC8E6C9) : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: isActive ? const Color(0xFF81C784) : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              onTap: () {
                                qtyControllers[index]?.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: qtyControllers[index]!.text.length,
                                );
                              },
                              onChanged: (val) {
                                final input = val.trim();
                                if (input == "0") {
                                  p.quantity = 0;
                                  p.isZeroMarked = true;
                                } else if (input.isEmpty) {
                                  p.quantity = 0;
                                  p.isZeroMarked = false;
                                } else {
                                  final qty = int.tryParse(input) ?? 0;
                                  p.quantity = qty;
                                  p.isZeroMarked = false;
                                }
                                _autoUpdateRotulos();
                                _saveState();
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Totals & Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Text(
                          "Total General: $totalUnits",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                        Text(
                          "Rendimiento: ${estHours.toStringAsFixed(2)} hs",
                          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _sendWhatsAppReport,
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text(
                      "Enviar WhatsApp",
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
