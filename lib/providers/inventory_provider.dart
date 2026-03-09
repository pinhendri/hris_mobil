import 'package:flutter/material.dart';
import '../models/inventory_model.dart';

class InventoryProvider with ChangeNotifier {
  List<InventoryModel> _inventories = [];
  bool _isLoading = false;

  List<InventoryModel> get inventories => _inventories;
  bool get isLoading => _isLoading;

  InventoryProvider() {
    _loadMockData();
  }

  Future<void> _loadMockData() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _inventories = [
      InventoryModel(
        id: '1',
        code: 'LP-001',
        name: 'MacBook Pro M2',
        category: 'Electronics',
        unit: 'Unit',
        stock: 5,
        minStock: 2,
        maxStock: 10,
        purchasePrice: 2000.0,
        sellingPrice: 0.0,
        status: 'active',
      ),
      InventoryModel(
        id: '2',
        code: 'MN-001',
        name: 'Dell UltraSharp 27"',
        category: 'Electronics',
        unit: 'Unit',
        stock: 8,
        minStock: 3,
        maxStock: 15,
        purchasePrice: 400.0,
        sellingPrice: 0.0,
        status: 'active',
      ),
      InventoryModel(
        id: '3',
        code: 'KB-001',
        name: 'Keychron K2',
        category: 'Accessories',
        unit: 'Unit',
        stock: 12,
        minStock: 5,
        maxStock: 20,
        purchasePrice: 80.0,
        sellingPrice: 0.0,
        status: 'active',
      ),
      InventoryModel(
        id: '4',
        code: 'CH-001',
        name: 'ErgoChair Pro',
        category: 'Furniture',
        unit: 'Unit',
        stock: 3,
        minStock: 2,
        maxStock: 10,
        purchasePrice: 350.0,
        sellingPrice: 0.0,
        status: 'active',
      ),
      InventoryModel(
        id: '5',
        code: 'ST-001',
        name: 'Office Stationery Set',
        category: 'Supplies',
        unit: 'Set',
        stock: 50,
        minStock: 20,
        maxStock: 100,
        purchasePrice: 15.0,
        sellingPrice: 0.0,
        status: 'active',
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadMockData();
  }
}
