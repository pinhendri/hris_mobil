import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../models/discovery_model.dart';
import '../../providers/discovery_provider.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController(
    text: 'Discovery',
  );
  final ScrollController _messageScrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<DiscoveryProvider>();
      if (!provider.isLoading &&
          provider.documents.isEmpty &&
          provider.conversations.isEmpty &&
          provider.messages.isEmpty) {
        await provider.bootstrap();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _categoryController.dispose();
    _messageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            context.tr('feature_label_discovery'),
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          actions: [
            Consumer<DiscoveryProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  onPressed: provider.isLoading
                      ? null
                      : () => _refresh(provider),
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Chat'),
              Tab(text: 'Documents'),
            ],
          ),
        ),
        body: Consumer<DiscoveryProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading &&
                provider.documents.isEmpty &&
                provider.conversations.isEmpty &&
                provider.messages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [_buildChatTab(provider), _buildDocumentsTab(provider)],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatTab(DiscoveryProvider provider) {
    return Column(
      children: [
        if (!provider.aiConfigured) _buildAiNotConfiguredBanner(),
        _buildConversationSection(provider),
        _buildSelectedDocumentSection(provider),
        Expanded(
          child: provider.isLoadingConversation
              ? const Center(child: CircularProgressIndicator())
              : provider.messages.isEmpty
              ? _buildEmptyChatState(provider)
              : ListView.builder(
                  controller: _messageScrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    return _MessageBubble(message: message);
                  },
                ),
        ),
        _buildComposer(provider),
      ],
    );
  }

  Widget _buildDocumentsTab(DiscoveryProvider provider) {
    final filteredDocuments = provider.documents
        .where((document) {
          final query = _searchQuery.trim().toLowerCase();
          if (query.isEmpty) {
            return true;
          }

          return document.name.toLowerCase().contains(query) ||
              document.category.toLowerCase().contains(query) ||
              document.format.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Upload Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: provider.isUploading
                        ? null
                        : () => _handleUpload(provider),
                    icon: provider.isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(
                      provider.isUploading ? 'Uploading...' : 'Upload',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search document, category, or format',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refresh(provider),
            child: filteredDocuments.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 56,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            provider.documents.isEmpty
                                ? 'Belum ada dokumen Discovery. Upload dokumen pertama Anda untuk mulai chat dengan AI.'
                                : 'Tidak ada dokumen yang cocok dengan pencarian saat ini.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredDocuments.length,
                    itemBuilder: (context, index) {
                      final document = filteredDocuments[index];
                      final isSelected = provider.selectedDocumentIds.contains(
                        document.id,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () =>
                              provider.toggleDocumentSelection(document.id),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                width: isSelected ? 1.4 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _documentColor(
                                          document,
                                        ).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _documentIcon(document),
                                        color: _documentColor(document),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            document.name,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _MetaChip(
                                                label: document.category,
                                                color: Colors.indigo,
                                              ),
                                              _MetaChip(
                                                label: document.format
                                                    .toUpperCase(),
                                                color: Colors.teal,
                                              ),
                                              _StatusChip(
                                                status: document
                                                    .discoverySyncStatus,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (_) => provider
                                          .toggleDocumentSelection(document.id),
                                      activeColor: AppColors.primary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Size: ${document.sizeLabel} • Uploaded ${_formatDate(document.uploadDate)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (document.discoveryLastError.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withValues(
                                          alpha: 0.16,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      document.discoveryLastError,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiNotConfiguredBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'OPENAI_API_KEY belum diisi di backend. Dokumen tetap bisa diupload dan dipilih, tapi AI belum bisa menjawab sampai konfigurasi OpenAI aktif.',
              style: GoogleFonts.poppins(
                color: Colors.orange.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationSection(DiscoveryProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Percakapan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  provider.startNewConversation();
                  _scrollToBottom();
                },
                icon: const Icon(Icons.add_comment_outlined, size: 18),
                label: const Text('Baru'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.conversations.isEmpty)
            Text(
              'Belum ada riwayat chat. Pilih dokumen lalu kirim pertanyaan pertama Anda.',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: provider.conversations
                    .map((conversation) {
                      final isSelected =
                          provider.activeConversation?.uuid ==
                          conversation.uuid;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: isSelected,
                          label: SizedBox(
                            width: 160,
                            child: Text(
                              conversation.title,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ),
                          onSelected: (_) async {
                            final success = await provider.loadConversation(
                              conversation.uuid,
                            );
                            if (!mounted) {
                              return;
                            }

                            if (!success && provider.error != null) {
                              _showSnackBar(provider.error!, isError: true);
                              return;
                            }

                            _scrollToBottom();
                          },
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedDocumentSection(DiscoveryProvider provider) {
    final selectedDocuments = provider.selectedDocuments;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Knowledge Base',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => DefaultTabController.of(context).animateTo(1),
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Kelola'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            selectedDocuments.isEmpty
                ? 'Belum ada dokumen terpilih. Buka tab Documents untuk memilih dokumen yang akan dipakai AI.'
                : '${selectedDocuments.length} dokumen aktif untuk percakapan ini.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (selectedDocuments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedDocuments
                  .map((document) {
                    return _MetaChip(
                      label: document.name,
                      color: document.isReady ? Colors.green : Colors.orange,
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyChatState(DiscoveryProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.auto_awesome, size: 56, color: Colors.blueGrey[300]),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Discovery siap membantu membaca dokumen Anda.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            provider.selectedDocumentIds.isEmpty
                ? 'Pilih minimal satu dokumen di tab Documents, lalu ajukan pertanyaan di bawah.'
                : 'Coba pertanyaan seperti "Ringkas isi dokumen ini" atau "Apa kebijakan cuti tahunan?".',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildComposer(DiscoveryProvider provider) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            if (provider.warningMessage != null &&
                provider.warningMessage!.trim().isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  provider.warningMessage!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(provider),
                    decoration: const InputDecoration(
                      hintText: 'Tanya berdasarkan dokumen yang dipilih',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: provider.isSending
                        ? null
                        : () => _handleSend(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: provider.isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(DiscoveryProvider provider) async {
    final success = await provider.refresh();
    if (!mounted) {
      return;
    }

    if (!success && provider.error != null) {
      _showSnackBar(provider.error!, isError: true);
      return;
    }

    _scrollToBottom();
  }

  Future<void> _handleUpload(DiscoveryProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      withData: true,
      allowedExtensions: provider.supportedFormats,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final success = await provider.uploadDocuments(
      result.files,
      category: _categoryController.text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showSnackBar(
        provider.error ?? 'Upload dokumen Discovery gagal.',
        isError: true,
      );
      return;
    }

    if (provider.warningMessage != null &&
        provider.warningMessage!.trim().isNotEmpty) {
      _showSnackBar(provider.warningMessage!, isError: false);
      return;
    }

    _showSnackBar('Dokumen Discovery berhasil diupload.', isError: false);
  }

  Future<void> _handleSend(DiscoveryProvider provider) async {
    final prompt = _messageController.text.trim();
    if (prompt.isEmpty) {
      return;
    }

    _messageController.clear();

    final success = await provider.sendMessage(prompt);

    if (!mounted) {
      return;
    }

    if (!success) {
      _messageController.text = prompt;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
      _showSnackBar(
        provider.error ?? 'Discovery belum bisa menjawab.',
        isError: true,
      );
      return;
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messageScrollController.hasClients) {
        return;
      }

      _messageScrollController.animateTo(
        _messageScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    return DateFormat('dd MMM yyyy', 'id_ID').format(value.toLocal());
  }

  IconData _documentIcon(DiscoveryDocument document) {
    final format = document.format.toLowerCase();
    if (format.contains('pdf')) {
      return Icons.picture_as_pdf_outlined;
    }

    if (format.contains('doc')) {
      return Icons.description_outlined;
    }

    if (format.contains('ppt')) {
      return Icons.slideshow_outlined;
    }

    if (format.contains('txt') ||
        format.contains('md') ||
        format.contains('json')) {
      return Icons.text_snippet_outlined;
    }

    return Icons.insert_drive_file_outlined;
  }

  Color _documentColor(DiscoveryDocument document) {
    final format = document.format.toLowerCase();
    if (format.contains('pdf')) {
      return Colors.red;
    }

    if (format.contains('doc')) {
      return Colors.blue;
    }

    if (format.contains('ppt')) {
      return Colors.orange;
    }

    if (format.contains('txt') ||
        format.contains('md') ||
        format.contains('json')) {
      return Colors.teal;
    }

    return Colors.grey.shade700;
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final DiscoveryMessage message;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.isAssistant;

    return Align(
      alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isAssistant ? Colors.white : AppColors.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: GoogleFonts.poppins(
                color: isAssistant ? AppColors.textPrimary : Colors.white,
                height: 1.5,
              ),
            ),
            if (message.citations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.citations
                    .map((citation) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          citation.label,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ],
            if (message.createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                DateFormat(
                  'dd MMM HH:mm',
                  'id_ID',
                ).format(message.createdAt!.toLocal()),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isAssistant
                      ? AppColors.textSecondary
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();

    Color color;
    String label;

    switch (normalizedStatus) {
      case 'ready':
        color = Colors.green;
        label = 'Ready';
        break;
      case 'syncing':
        color = Colors.orange;
        label = 'Syncing';
        break;
      case 'failed':
        color = Colors.red;
        label = 'Failed';
        break;
      default:
        color = Colors.grey;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
