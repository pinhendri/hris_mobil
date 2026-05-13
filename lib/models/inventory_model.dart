class InventoryModel {
  final String id;
  final String code;
  final String name;
  final String category;
  final String unit;
  final int stock;
  final int minStock;
  final int maxStock;
  final double purchasePrice;
  final double sellingPrice;
  final String status;

  InventoryModel({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.unit,
    required this.stock,
    required this.minStock,
    required this.maxStock,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.status,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'].toString(),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      unit: json['unit'] ?? '',
      stock: _readInt(json['stock']),
      minStock: _readInt(json['min_stock']),
      maxStock: _readInt(json['max_stock']),
      purchasePrice: _readDouble(json['purchase_price']),
      sellingPrice: _readDouble(json['selling_price']),
      status: json['status'] ?? 'active',
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
