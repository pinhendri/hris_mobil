import 'package:flutter/material.dart';
import '../models/claim_model.dart';

class ClaimProvider with ChangeNotifier {
  List<ClaimModel> _claims = [];
  bool _isLoading = false;

  List<ClaimModel> get claims => _claims;
  bool get isLoading => _isLoading;

  ClaimProvider() {
    _loadMockData();
  }

  Future<void> _loadMockData() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _claims = [
      ClaimModel(
        id: '1',
        title: 'Grab to Client Meeting',
        amount: 45.00,
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: 'approved',
        type: 'transport',
        description: 'Taxi fare to visit Client X at CBD.',
      ),
      ClaimModel(
        id: '2',
        title: 'Team Lunch',
        amount: 120.50,
        date: DateTime.now().subtract(const Duration(days: 5)),
        status: 'pending',
        type: 'meals',
        description: 'Quarterly team lunch with 5 members.',
      ),
      ClaimModel(
        id: '3',
        title: 'Dental Checkup',
        amount: 80.00,
        date: DateTime.now().subtract(const Duration(days: 15)),
        status: 'rejected',
        type: 'medical',
        description: 'Annual dental checkup.',
      ),
      ClaimModel(
        id: '4',
        title: 'Office Supplies',
        amount: 25.00,
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: 'manager_approved',
        type: 'other',
        description: 'Purchased notebooks and pens for the team.',
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitClaim(ClaimModel claim) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2));
    _claims.insert(0, claim);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateClaim(ClaimModel updated) async {
    final index = _claims.indexWhere((c) => c.id == updated.id);
    if (index == -1) return;
    _claims[index] = updated;
    notifyListeners();
  }

  Future<void> updateStatus(String id, String status) async {
    final index = _claims.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final current = _claims[index];
    _claims[index] = ClaimModel(
      id: current.id,
      title: current.title,
      amount: current.amount,
      date: current.date,
      status: status,
      type: current.type,
      description: current.description,
      attachmentUrl: current.attachmentUrl,
    );
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadMockData();
  }
}
