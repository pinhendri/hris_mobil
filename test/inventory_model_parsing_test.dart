import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/inventory_model.dart';

void main() {
  test('inventory model parses decimal strings from API safely', () {
    final inventory = InventoryModel.fromJson({
      'id': 1,
      'code': 'INV-001',
      'name': 'Laptop',
      'category': 'Assets',
      'unit': 'pcs',
      'stock': '12',
      'min_stock': '2',
      'max_stock': '20',
      'purchase_price': '5000000.00',
      'selling_price': '5500000.00',
      'status': 'active',
    });

    expect(inventory.stock, 12);
    expect(inventory.minStock, 2);
    expect(inventory.maxStock, 20);
    expect(inventory.purchasePrice, 5000000);
    expect(inventory.sellingPrice, 5500000);
  });
}
