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
      stock: json['stock'] ?? 0,
      minStock: json['min_stock'] ?? 0,
      maxStock: json['max_stock'] ?? 0,
      purchasePrice: (json['purchase_price'] ?? 0).toDouble(),
      sellingPrice: (json['selling_price'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
    );
  }
}
