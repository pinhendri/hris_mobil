import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureItem {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const FeatureItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class FavoriteProvider with ChangeNotifier {
  List<String> _favoriteIds = ['attendance', 'leave', 'payslip'];

  final List<FeatureItem> _allFeatures = [
    FeatureItem(
      id: 'payslip',
      label: 'Payslip',
      icon: Icons.receipt_long,
      color: Colors.blue,
    ),
    FeatureItem(
      id: 'leave',
      label: 'Leave',
      icon: Icons.calendar_today,
      color: Colors.orange,
    ),
    FeatureItem(
      id: 'attendance',
      label: 'Attendance',
      icon: Icons.access_time,
      color: Colors.green,
    ),
    FeatureItem(
      id: 'location',
      label: 'My Location',
      icon: Icons.pin_drop,
      color: Colors.red,
    ),
    FeatureItem(
      id: 'claims',
      label: 'Claims',
      icon: Icons.monetization_on,
      color: Colors.purple,
    ),
    FeatureItem(
      id: 'overtime',
      label: 'Overtime',
      icon: Icons.schedule_send_outlined,
      color: Colors.amber,
    ),
    FeatureItem(
      id: 'performance',
      label: 'Performance',
      icon: Icons.trending_up,
      color: Colors.redAccent,
    ),
    FeatureItem(
      id: 'recruitment',
      label: 'Recruitment',
      icon: Icons.work_outline,
      color: Colors.teal,
    ),
    FeatureItem(
      id: 'inventory',
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      color: Colors.indigo,
    ),
    FeatureItem(
      id: 'training',
      label: 'Training',
      icon: Icons.school_outlined,
      color: Colors.blueGrey,
    ),
    FeatureItem(
      id: 'tasks',
      label: 'Tasks',
      icon: Icons.check_circle_outline,
      color: Colors.deepOrange,
    ),
    FeatureItem(
      id: 'documents',
      label: 'Documents',
      icon: Icons.folder_open,
      color: Colors.brown,
    ),
    FeatureItem(
      id: 'discovery',
      label: 'Discovery',
      icon: Icons.auto_awesome,
      color: Colors.blueAccent,
    ),
    FeatureItem(
      id: 'clients',
      label: 'Clients',
      icon: Icons.business,
      color: Colors.indigo,
    ),
    FeatureItem(
      id: 'corrections',
      label: 'Corrections',
      icon: Icons.build_circle_outlined,
      color: Colors.redAccent,
    ),
  ];

  List<String> get favoriteIds => _favoriteIds;
  List<FeatureItem> get allFeatures => _allFeatures;

  List<FeatureItem> get favoriteFeatures {
    return _allFeatures.where((f) => _favoriteIds.contains(f.id)).toList();
  }

  FavoriteProvider() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favorite_features');
    if (saved != null && saved.isNotEmpty) {
      _favoriteIds = saved;
      notifyListeners();
    }
  }

  Future<String?> toggleFavorite(String id) async {
    String? error;
    if (_favoriteIds.contains(id)) {
      if (_favoriteIds.length > 1) {
        _favoriteIds.remove(id);
      } else {
        error = "At least 1 favorite is required";
      }
    } else {
      if (_favoriteIds.length < 5) {
        _favoriteIds.add(id);
      } else {
        error = "Maximum 5 favorites allowed";
      }
    }

    if (error == null) {
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_features', _favoriteIds);
    }

    return error;
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);
}
