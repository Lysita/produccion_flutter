import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_item.dart';

class StorageService {
  static const String keyEmployee = "employee_name";

  static Future<String> getEmployeeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyEmployee) ?? "";
  }

  static Future<void> saveEmployeeName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyEmployee, name);
  }

  static Future<void> loadProductCustomizations(List<ProductItem> productList) async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < productList.length; i++) {
      final item = productList[i];
      final savedName = prefs.getString("prod_name_$i");
      if (savedName != null) {
        item.name = savedName;
      }
      if (prefs.containsKey("prod_rate_$i")) {
        item.ratePerHour = prefs.getDouble("prod_rate_$i") ?? item.ratePerHour;
      }
      if (prefs.containsKey("prod_rotulos_$i")) {
        item.addToRotulos = prefs.getBool("prod_rotulos_$i") ?? item.addToRotulos;
      }
    }
  }

  static Future<void> saveProductCustomization(ProductItem item, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("prod_name_$index", item.name);
    await prefs.setDouble("prod_rate_$index", item.ratePerHour);
    await prefs.setBool("prod_rotulos_$index", item.addToRotulos);
  }

  static Future<void> saveCurrentState({
    required List<ProductItem> productList,
    required String hoursWorked,
    required String rotulosVal,
    required DateTime selectedDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < productList.length; i++) {
      final item = productList[i];
      await prefs.setInt("prod_qty_$i", item.quantity);
      await prefs.setBool("prod_zero_$i", item.isZeroMarked);
    }
    await prefs.setString("hours_worked", hoursWorked);
    await prefs.setString("rotulos_val", rotulosVal);
    await prefs.setInt("selected_date_millis", selectedDate.millisecondsSinceEpoch);
  }

  static Future<Map<String, dynamic>> loadSavedState(List<ProductItem> productList) async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < productList.length; i++) {
      final item = productList[i];
      item.quantity = prefs.getInt("prod_qty_$i") ?? 0;
      item.isZeroMarked = prefs.getBool("prod_zero_$i") ?? false;
    }

    final hoursWorked = prefs.getString("hours_worked") ?? "";
    final rotulosVal = prefs.getString("rotulos_val") ?? "";

    DateTime selectedDate = DateTime.now();
    if (prefs.containsKey("selected_date_millis")) {
      final millis = prefs.getInt("selected_date_millis") ?? DateTime.now().millisecondsSinceEpoch;
      final savedCal = DateTime.fromMillisecondsSinceEpoch(millis);
      final today = DateTime.now();
      if (today.year == savedCal.year && today.month == savedCal.month && today.day == savedCal.day) {
        selectedDate = savedCal;
      }
    }

    return {
      "hours_worked": hoursWorked,
      "rotulos_val": rotulosVal,
      "selected_date": selectedDate,
    };
  }

  static Future<void> clearAllData(List<ProductItem> productList) async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < productList.length; i++) {
      final item = productList[i];
      item.quantity = 0;
      item.isZeroMarked = false;
      await prefs.remove("prod_qty_$i");
      await prefs.remove("prod_zero_$i");
    }
    await prefs.remove("hours_worked");
    await prefs.remove("rotulos_val");
    await prefs.remove("selected_date_millis");
  }

  static String _getFreqKey(String empName, String prodName) {
    final cleanEmp = empName.trim().toLowerCase();
    final cleanProd = prodName.trim().toLowerCase();
    return "freq_${cleanEmp}_$cleanProd";
  }

  static Future<void> loadEmployeeFrequencies(String empName, List<ProductItem> productList) async {
    if (empName.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    for (var item in productList) {
      final key = _getFreqKey(empName, item.name);
      item.frequency = prefs.getInt(key) ?? 0;
    }
  }

  static Future<void> recordEmployeeProductUsage(String empName, List<ProductItem> productList) async {
    if (empName.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    for (var item in productList) {
      if (item.quantity > 0) {
        final key = _getFreqKey(empName, item.name);
        final currentFreq = prefs.getInt(key) ?? 0;
        final newFreq = currentFreq + item.quantity;
        await prefs.setInt(key, newFreq);
        item.frequency = newFreq;
      }
    }
  }
}
