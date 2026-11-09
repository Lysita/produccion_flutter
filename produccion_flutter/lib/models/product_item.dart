class ProductItem {
  String name;
  int quantity;
  double ratePerHour;
  bool addToRotulos;
  int originalIndex;
  bool isZeroMarked;
  int frequency;

  ProductItem({
    required this.name,
    this.quantity = 0,
    required this.originalIndex,
    double? ratePerHour,
    bool? addToRotulos,
    this.isZeroMarked = false,
    this.frequency = 0,
  })  : ratePerHour = ratePerHour ?? calculateDefaultRate(name),
        addToRotulos = addToRotulos ?? calculateDefaultAddToRotulos(name);

  static bool calculateDefaultAddToRotulos(String productName) {
    final lower = productName.toLowerCase().trim();
    if (lower.contains("triples jamon")) {
      return false;
    }
    if (lower.contains("bandejas medianas")) {
      return false;
    }
    return !lower.contains("torpedo");
  }

  static double calculateDefaultRate(String productName) {
    final lower = productName.toLowerCase().trim();
    if (lower.contains("doble vegetariano")) {
      return 45.0;
    } else if (lower.contains("doble") || lower.contains("pizza")) {
      return 48.0;
    } else if (lower.contains("triple") && !lower.contains("bandeja")) {
      return 38.0;
    } else if (lower.contains("torpedo")) {
      return 38.0;
    } else if (lower.contains("bandeja") && lower.contains("chica")) {
      return 22.0;
    } else if (lower.contains("bandeja") && (lower.contains("primavera") || lower.contains("mediana"))) {
      return 18.0;
    } else if (lower.contains("bandeja triple x4 surtida") || lower.contains("bandeja triple x4 surtido")) {
      return 16.0;
    } else if (lower.contains("bandeja triple x4")) {
      return 18.0;
    } else if (lower.contains("bandeja triple x8")) {
      return 14.0;
    } else if (lower.contains("carlitos")) {
      return 18.0;
    } else if (lower.contains("pebete")) {
      return 42.0;
    } else if (lower.contains("suprema")) {
      return 35.0;
    } else if (lower.contains("armado de empanadas") || lower.contains("empanadas x3")) {
      return 60.0;
    } else if (lower.contains("alfajores de maicena") || lower.contains("alfajor")) {
      return 18.0;
    } else if (lower.contains("postres") || lower.contains("postre")) {
      return 18.0;
    } else if (lower.contains("cortes fiambre") || lower.contains("corte fiambre") || lower.contains("fiambre")) {
      return 6.0;
    } else {
      return 50.0;
    }
  }

  static List<String> get defaultNames => [
        "Triples jamon",
        "Triples salame",
        "Doble salvado",
        "Doble vegetariano",
        "Pebetes largos",
        "Pebetes chatos",
        "Bandejas chicas",
        "Bandejas chicas salvado",
        "Bandejas medianas",
        "Bandeja triple x4 surtidas",
        "Bandeja triple x4 salvado",
        "Bandeja triple x4",
        "Bandeja triple x8",
        "Bandeja primavera",
        "Carlitos",
        "Medialuna x2",
        "Empanadas - Armado de empanadas",
        "Empanadas x3",
        "Torpedo",
        "Alfajores de maicena",
        "Postres",
        "Fetas de queso (200gr)",
        "Fetas de jamón (200gr)",
        "Fetas de mortadela (200gr)",
        "Cortes fiambre",
        "Palmeritas",
        "Chato suprema JyQ",
        "Pizza Muzzarella",
        "Pizza Especial",
        "Ensalada rusa (500gr)",
        "Empanadas x3 CS",
        "Empanadas x3 CD",
        "Empanadas x3 JyQ",
        "Empanadas x3 P",
        "Empanadas x3 V"
      ];
}
