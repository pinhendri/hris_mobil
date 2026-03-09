// lib/providers/document_provider.dart
import '../data/models/document_model.dart';
import 'package:flutter/material.dart';

class DocumentProvider extends ChangeNotifier {
  bool isLoading = false;
  List<DocumentItem> documents = [];

  Future<void> fetchDocuments() async {
    try {
      isLoading = true;
      notifyListeners();

      // Dummy data
      await Future.delayed(const Duration(seconds: 1));
      documents = [
        DocumentItem(
          id: '1',
          title: 'Company Policy',
          type: 'pdf',
          category: 'Policy',
          url: 'https://example.com/policy.pdf',
          size: '1.2 MB',
          updatedAt: DateTime.now(),
        ),
        DocumentItem(
          id: '2',
          title: 'Employee Handbook',
          type: 'doc',
          category: 'Handbook',
          url: 'https://example.com/handbook.doc',
          size: '800 KB',
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}