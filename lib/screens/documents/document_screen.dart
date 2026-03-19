import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/document_model.dart';
import '../../providers/document_provider.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DocumentProvider>();
      if (!provider.isLoading && provider.documents.isEmpty) {
        provider.fetchDocuments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Documents',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<DocumentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.documents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.documents.isEmpty) {
            return _buildStateView(
              icon: Icons.folder_off_outlined,
              message: provider.error!,
              actionLabel: 'Retry',
              onAction: provider.refresh,
            );
          }

          if (provider.documents.isEmpty) {
            return _buildStateView(
              icon: Icons.folder_off_outlined,
              message: 'No documents found',
              actionLabel: 'Refresh',
              onAction: provider.refresh,
            );
          }

          final categories = <String, List<DocumentItem>>{};
          for (final document in provider.documents) {
            categories.putIfAbsent(document.category, () => []);
            categories[document.category]!.add(document);
          }

          final sortedCategories = categories.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final category = sortedCategories[index];
                final documents = categories[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    ...documents.map(
                      (document) => _buildDocumentItem(document),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStateView({
    required IconData icon,
    required String message,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    return RefreshIndicator(
      onRefresh: onAction,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(DocumentItem document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getFileColor(document.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getFileIcon(document.type),
            color: _getFileColor(document.type),
            size: 24,
          ),
        ),
        title: Text(
          document.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  document.size,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '-',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, y').format(document.updatedAt),
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_rounded, color: AppColors.primary),
          onPressed: document.url.isEmpty
              ? null
              : () => _copyLinkToClipboard(document),
        ),
        onTap: document.url.isEmpty
            ? null
            : () => _copyLinkToClipboard(document),
      ),
    );
  }

  Future<void> _copyLinkToClipboard(DocumentItem document) async {
    await Clipboard.setData(ClipboardData(text: document.url));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link download ${document.title} copied.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
        return Icons.description_outlined;
      case 'xls':
        return Icons.table_chart_outlined;
      case 'ppt':
        return Icons.slideshow_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'txt':
        return Icons.notes_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
        return Colors.blue;
      case 'xls':
        return Colors.green;
      case 'ppt':
        return Colors.orange;
      case 'image':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
