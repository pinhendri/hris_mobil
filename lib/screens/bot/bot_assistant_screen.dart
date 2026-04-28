import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../models/bot_assistant_model.dart';
import '../../models/discovery_model.dart';
import '../../providers/bot_assistant_provider.dart';

const String botAssistantAvatarAsset = 'assets/images/bot-assistant-avatar.png';

class BotAssistantScreen extends StatefulWidget {
  const BotAssistantScreen({super.key});

  @override
  State<BotAssistantScreen> createState() => _BotAssistantScreenState();
}

class _BotAssistantScreenState extends State<BotAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _documentSearchController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _documentSearchQuery = '';

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _screenBackgroundColor =>
      _isDarkMode ? const Color(0xFF020817) : AppColors.background;

  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF111827) : Colors.white;

  Color get _surfaceMutedColor =>
      _isDarkMode ? const Color(0xFF0F172A) : Colors.grey.shade50;

  Color get _surfaceBorderColor =>
      _isDarkMode ? const Color(0xFF253041) : AppColors.border;

  Color get _primaryTextColor =>
      _isDarkMode ? const Color(0xFFF8FAFC) : AppColors.textPrimary;

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFFCBD5E1) : AppColors.textSecondary;

  Color get _hintTextColor =>
      _isDarkMode ? const Color(0xFF94A3B8) : AppColors.textMuted;

  List<BoxShadow> get _cardShadow => _isDarkMode
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ];

  TextStyle get _inputTextStyle =>
      GoogleFonts.poppins(fontSize: 13, color: _primaryTextColor);

  Color _tintedSurface(Color color, {double darkAlpha = 0.18}) {
    return color.withValues(alpha: _isDarkMode ? darkAlpha : 0.10);
  }

  Color _bannerSurface(Color color) {
    return color.withValues(alpha: _isDarkMode ? 0.16 : 0.08);
  }

  Color _bannerBorder(Color color) {
    return color.withValues(alpha: _isDarkMode ? 0.28 : 0.16);
  }

  Color _bannerTextColor(Color color) {
    return Color.lerp(
          color,
          _isDarkMode ? Colors.white : Colors.black,
          _isDarkMode ? 0.22 : 0.24,
        ) ??
        color;
  }

  ButtonStyle get _outlinedButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: _primaryTextColor,
    side: BorderSide(color: _surfaceBorderColor),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<BotAssistantProvider>();
      if (!provider.isLoading &&
          provider.capabilities == null &&
          provider.sessions.isEmpty &&
          provider.messages.isEmpty) {
        final success = await provider.bootstrap();
        if (!mounted) {
          return;
        }

        if (!success && provider.error != null) {
          _showSnackBar(provider.error!, isError: true);
          return;
        }

        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _documentSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackgroundColor,
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        surfaceTintColor: _surfaceColor,
        iconTheme: IconThemeData(color: _primaryTextColor),
        titleSpacing: 0,
        title: Row(
          children: [
            _buildAvatar(size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('feature_label_bot_assistant'),
                    style: GoogleFonts.poppins(
                      color: _primaryTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Assistant untuk HR workflow Anda',
                    style: GoogleFonts.poppins(
                      color: _secondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer<BotAssistantProvider>(
            builder: (context, provider, child) {
              return IconButton(
                tooltip: 'Session baru',
                onPressed: () {
                  _messageController.clear();
                  provider.resetComposer();
                  _scrollToBottom();
                },
                icon: const Icon(Icons.add_comment_outlined),
              );
            },
          ),
          Consumer<BotAssistantProvider>(
            builder: (context, provider, child) {
              final loading = provider.isRefreshing || provider.isLoading;

              return IconButton(
                tooltip: 'Refresh',
                onPressed: loading ? null : () => _handleRefresh(provider),
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              );
            },
          ),
        ],
      ),
      body: Consumer<BotAssistantProvider>(
        builder: (context, provider, child) {
          final showInitialLoader =
              provider.isLoading &&
              provider.capabilities == null &&
              provider.sessions.isEmpty &&
              provider.messages.isEmpty;

          if (showInitialLoader) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _handleRefresh(provider),
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      if (provider.error != null &&
                          provider.messages.isEmpty &&
                          provider.sessions.isEmpty)
                        _buildErrorCard(provider.error!),
                      if (provider.canAskDocs && !provider.docsConfigured)
                        _buildDocsConfigBanner(),
                      _buildHeroCard(provider),
                      const SizedBox(height: 12),
                      _buildModeCard(provider),
                      const SizedBox(height: 12),
                      _buildQuickActionsCard(provider),
                      const SizedBox(height: 12),
                      _buildSessionsCard(provider),
                      if (provider.canAskDocs) ...[
                        const SizedBox(height: 12),
                        _buildKnowledgeBaseCard(provider),
                      ],
                      if (provider.pendingActionTool != null) ...[
                        const SizedBox(height: 12),
                        _buildActionCard(provider),
                      ],
                      const SizedBox(height: 12),
                      provider.isLoadingSession
                          ? _buildLoadingState()
                          : provider.messages.isEmpty
                          ? _buildEmptyState(provider)
                          : _buildMessagesCard(provider),
                    ],
                  ),
                ),
              ),
              _buildComposer(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(BotAssistantProvider provider) {
    final activeTitle = provider.activeSession?.title ?? 'Session BOT Baru';
    final lastAssistant = provider.lastAssistantMessage;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeTitle,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: _primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tanya data HR pribadi, cari isi dokumen, atau minta BOT menyiapkan draft action.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.45,
                        color: _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip(
                label: provider.botMode.label,
                color: AppColors.primary,
              ),
              if (provider.botMode == BotMode.askDocs)
                _buildMetaChip(
                  label: '${provider.selectedDocumentIds.length} dokumen aktif',
                  color: Colors.teal,
                ),
              ...lastAssistant?.capabilitiesUsed.map((capability) {
                    return _buildMetaChip(
                      label: capability,
                      color: Colors.blueGrey,
                    );
                  }) ??
                  const [],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(BotAssistantProvider provider) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode BOT',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih cara BOT membantu Anda di sesi ini.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: _secondaryTextColor,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: provider.modeOptions
                .map((mode) {
                  final selected = provider.botMode == mode;

                  return GestureDetector(
                    onTap: () => provider.setBotMode(mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 164,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected
                            ? _tintedSurface(AppColors.primary)
                            : _surfaceMutedColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : _surfaceBorderColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.label,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.primary
                                  : _primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mode.description,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              height: 1.4,
                              color: _secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BotAssistantProvider provider) {
    final actions = provider.capabilities?.quickActions ?? const [];

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Shortcut paling cepat untuk workflow BOT yang sudah tersedia.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: _secondaryTextColor,
            ),
          ),
          const SizedBox(height: 14),
          if (actions.isEmpty)
            Text(
              'Quick action akan muncul setelah capability BOT berhasil dimuat.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: _secondaryTextColor,
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: actions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final action = actions[index];

                  return SizedBox(
                    width: 200,
                    child: InkWell(
                      onTap: () => _handleQuickAction(provider, action),
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _surfaceMutedColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _surfaceBorderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: _secondaryTextColor,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              action.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: _primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              action.mode.label,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: _secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionsCard(BotAssistantProvider provider) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Riwayat BOT',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _primaryTextColor,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _messageController.clear();
                  provider.resetComposer();
                  _scrollToBottom();
                },
                style: _outlinedButtonStyle,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Baru'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            provider.sessions.isEmpty
                ? 'Belum ada session BOT. Mulai dari quick action atau kirim pertanyaan pertama Anda.'
                : 'Pilih session untuk membuka kembali riwayat percakapan.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: _secondaryTextColor,
            ),
          ),
          if (provider.sessions.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.sessions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final session = provider.sessions[index];
                  final selected = provider.activeSession?.uuid == session.uuid;

                  return SizedBox(
                    width: 230,
                    child: InkWell(
                      onTap: () => _handleLoadSession(provider, session.uuid),
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected
                              ? _tintedSurface(AppColors.primary)
                              : _surfaceMutedColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : _surfaceBorderColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    session.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _primaryTextColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildMetaChip(
                                  label: session.status,
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.blueGrey,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              session.mode.label,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: _secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(session.lastMessageAt),
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: _secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKnowledgeBaseCard(BotAssistantProvider provider) {
    final filteredDocuments = provider.documents
        .where((document) {
          final query = _documentSearchQuery.trim().toLowerCase();
          if (query.isEmpty) {
            return true;
          }

          return document.name.toLowerCase().contains(query) ||
              document.category.toLowerCase().contains(query) ||
              document.format.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Knowledge Base',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih dokumen Discovery yang akan dipakai BOT saat mode Tanya Dokumen.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: _secondaryTextColor,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _documentSearchController,
            onChanged: (value) {
              setState(() {
                _documentSearchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari dokumen atau kategori...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 12.5,
                color: _hintTextColor,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _secondaryTextColor,
              ),
              isDense: true,
              filled: true,
              fillColor: _surfaceMutedColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _surfaceBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _surfaceBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            style: _inputTextStyle,
          ),
          const SizedBox(height: 14),
          if (filteredDocuments.isEmpty)
            Text(
              'Belum ada dokumen Discovery aktif untuk dipilih.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: _secondaryTextColor,
              ),
            )
          else
            SizedBox(
              height: 280,
              child: ListView.separated(
                itemCount: filteredDocuments.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final document = filteredDocuments[index];
                  final selected = provider.selectedDocumentIds.contains(
                    document.id,
                  );

                  return InkWell(
                    onTap: () => provider.toggleDocumentSelection(document.id),
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected
                            ? _tintedSurface(AppColors.primary)
                            : _surfaceMutedColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : _surfaceBorderColor,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  document.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildMetaChip(
                                      label: document.category,
                                      color: Colors.indigo,
                                    ),
                                    _buildMetaChip(
                                      label: document.format.toUpperCase(),
                                      color: Colors.teal,
                                    ),
                                    _buildMetaChip(
                                      label: document.discoverySyncStatus,
                                      color: document.isReady
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ],
                                ),
                                if (document.discoveryLastError.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    document.discoveryLastError,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: _bannerTextColor(Colors.red),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Checkbox(
                            value: selected,
                            activeColor: AppColors.primary,
                            side: BorderSide(color: _surfaceBorderColor),
                            onChanged: (_) =>
                                provider.toggleDocumentSelection(document.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BotAssistantProvider provider) {
    final toolName = provider.pendingActionTool!;
    final fields = provider.currentActionFields;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Form aksi BOT',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _primaryTextColor,
                  ),
                ),
              ),
              _buildMetaChip(label: toolName, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lengkapi field berikut untuk membuat preview sebelum dieksekusi.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: _secondaryTextColor,
            ),
          ),
          const SizedBox(height: 14),
          if (provider.actionPreview == null) ...[
            if (fields.isEmpty)
              Text(
                'Action ini membutuhkan input tambahan yang belum dikonfigurasi di mobile.',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: _secondaryTextColor,
                ),
              )
            else
              ...fields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildActionField(provider, field),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'BOT tidak langsung mengeksekusi. Langkah ini hanya membuat preview action.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: _secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed:
                      provider.isPreviewLoading || !provider.actionFormReady
                      ? null
                      : () => _handlePreviewAction(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  icon: provider.isPreviewLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Preview'),
                ),
              ],
            ),
          ] else ...[
            _buildPreviewState(provider),
          ],
        ],
      ),
    );
  }

  Widget _buildActionField(
    BotAssistantProvider provider,
    BotActionFieldConfig field,
  ) {
    final value = provider.actionValues[field.name] ?? '';

    Widget child;

    switch (field.type) {
      case BotActionFieldType.textarea:
        child = TextFormField(
          key: ValueKey('${field.name}-$value'),
          initialValue: value,
          minLines: 3,
          maxLines: 5,
          style: _inputTextStyle,
          onChanged: (nextValue) =>
              provider.updateActionValue(field.name, nextValue),
          decoration: _fieldDecoration(
            label: field.label,
            placeholder: field.placeholder,
            required: field.required,
          ),
        );
        break;
      case BotActionFieldType.select:
        final options = field.options ?? const [];
        final currentValue = options.any((option) => option.value == value)
            ? value
            : field.defaultValue;

        child = DropdownButtonFormField<String>(
          initialValue: currentValue,
          style: _inputTextStyle,
          dropdownColor: _surfaceColor,
          iconEnabledColor: _secondaryTextColor,
          decoration: _fieldDecoration(
            label: field.label,
            required: field.required,
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(
                    option.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _primaryTextColor,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (nextValue) {
            provider.updateActionValue(field.name, nextValue ?? '');
          },
        );
        break;
      case BotActionFieldType.date:
      case BotActionFieldType.time:
        child = TextFormField(
          key: ValueKey('${field.name}-$value'),
          initialValue: value,
          readOnly: true,
          style: _inputTextStyle,
          onTap: () => _pickActionValue(field, provider),
          decoration: _fieldDecoration(
            label: field.label,
            placeholder: field.placeholder,
            required: field.required,
            suffixIcon: Icon(
              field.type == BotActionFieldType.date
                  ? Icons.calendar_today_outlined
                  : Icons.access_time_outlined,
            ),
          ),
        );
        break;
      case BotActionFieldType.number:
      case BotActionFieldType.text:
        child = TextFormField(
          key: ValueKey('${field.name}-$value'),
          initialValue: value,
          keyboardType: field.type == BotActionFieldType.number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: _inputTextStyle,
          onChanged: (nextValue) =>
              provider.updateActionValue(field.name, nextValue),
          decoration: _fieldDecoration(
            label: field.label,
            placeholder: field.placeholder,
            required: field.required,
          ),
        );
        break;
    }

    return child;
  }

  Widget _buildPreviewState(BotAssistantProvider provider) {
    final preview = provider.actionPreview!;
    final entries = preview.normalizedPayload.entries.toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _bannerSurface(Colors.green),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _bannerBorder(Colors.green)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  preview.summary ?? 'Preview action berhasil dibuat.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: _bannerTextColor(Colors.green),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (entries.isNotEmpty)
          ...entries.map(
            (entry) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surfaceMutedColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _surfaceBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    humanizeBotFieldName(entry.key),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.value?.toString() ?? '-',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (preview.warnings.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _bannerSurface(Colors.orange),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _bannerBorder(Colors.orange)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: preview.warnings
                  .map(
                    (warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        formatBotWarning(warning),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _bannerTextColor(Colors.orange),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: provider.isConfirming
                    ? null
                    : () => provider.clearActionPreview(),
                style: _outlinedButtonStyle,
                child: const Text('Ubah Data'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: provider.isConfirming
                    ? null
                    : () => _handleConfirmAction(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
                icon: provider.isConfirming
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Konfirmasi'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return _buildSectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Memuat session BOT...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BotAssistantProvider provider) {
    return _buildSectionCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildAvatar(size: 72),
          const SizedBox(height: 14),
          Text(
            'Mulai ngobrol dengan BOT Anda',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.botMode == BotMode.askDocs
                ? 'Pilih minimal satu dokumen lalu ajukan pertanyaan tentang knowledge base Anda.'
                : 'Gunakan mode tanya sistem untuk data HR, atau mode buat aksi untuk draft workflow.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.45,
              color: _secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMessagesCard(BotAssistantProvider provider) {
    return Column(
      children: provider.messages
          .map(
            (message) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MessageBubble(message: message),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildComposer(BotAssistantProvider provider) {
    final placeholder = {
      BotMode.askSystem:
          'Contoh: status claim saya, sisa cuti saya, atau tampilkan profil saya...',
      BotMode.askDocs:
          'Contoh: jelaskan SOP onboarding, atau kebijakan reimbursement apa yang berlaku...',
      BotMode.takeAction:
          'Contoh: bantu saya buat draft claim, draft lembur, atau draft cuti...',
    }[provider.botMode];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          border: Border(top: BorderSide(color: _surfaceBorderColor)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetaChip(
                  label: provider.botMode.label,
                  color: AppColors.primary,
                ),
                if (provider.botMode == BotMode.askDocs)
                  _buildMetaChip(
                    label: '${provider.selectedDocumentIds.length} dokumen',
                    color: Colors.teal,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: _hintTextColor,
                      ),
                      filled: true,
                      fillColor: _surfaceMutedColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _surfaceBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: _surfaceBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    style: _inputTextStyle,
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
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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

  Widget _buildDocsConfigBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bannerSurface(Colors.orange),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bannerBorder(Colors.orange)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mode tanya dokumen belum aktif penuh. Backend BOT tersedia, tetapi Discovery masih menunggu konfigurasi AI di server.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: _bannerTextColor(Colors.orange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bannerSurface(Colors.red),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bannerBorder(Colors.red)),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          color: _bannerTextColor(Colors.red),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorderColor),
        boxShadow: _cardShadow,
      ),
      child: child,
    );
  }

  Widget _buildMetaChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _tintedSurface(color, darkAlpha: 0.20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: _surfaceBorderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        botAssistantAvatarAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: _tintedSurface(AppColors.primary, darkAlpha: 0.22),
            child: Icon(
              Icons.smart_toy_outlined,
              color: AppColors.primary,
              size: size * 0.54,
            ),
          );
        },
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? placeholder,
    bool required = false,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: placeholder,
      suffixIcon: suffixIcon,
      labelStyle: GoogleFonts.poppins(
        fontSize: 12.5,
        color: _secondaryTextColor,
      ),
      hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: _hintTextColor),
      filled: true,
      fillColor: _surfaceMutedColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _surfaceBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _surfaceBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Future<void> _handleRefresh(BotAssistantProvider provider) async {
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

  Future<void> _handleLoadSession(
    BotAssistantProvider provider,
    String sessionUuid,
  ) async {
    final success = await provider.loadSession(sessionUuid);
    if (!mounted) {
      return;
    }

    if (!success && provider.error != null) {
      _showSnackBar(provider.error!, isError: true);
      return;
    }

    _scrollToBottom();
  }

  Future<void> _handleQuickAction(
    BotAssistantProvider provider,
    BotQuickAction action,
  ) async {
    final prompt = botQuickActionPrompts[action.id] ?? action.label;
    provider.setBotMode(action.mode);

    final success = await provider.sendMessage(
      prompt,
      overrideMode: action.mode,
      quickActionId: action.id,
    );

    if (!mounted) {
      return;
    }

    if (!success && provider.error != null) {
      _showSnackBar(provider.error!, isError: true);
      return;
    }

    _scrollToBottom();
  }

  Future<void> _handleSend(BotAssistantProvider provider) async {
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
        provider.error ?? 'BOT belum bisa memproses pesan saat ini.',
        isError: true,
      );
      return;
    }

    _scrollToBottom();
  }

  Future<void> _handlePreviewAction(BotAssistantProvider provider) async {
    final success = await provider.previewAction();
    if (!mounted) {
      return;
    }

    if (!success && provider.error != null) {
      _showSnackBar(provider.error!, isError: true);
    }
  }

  Future<void> _handleConfirmAction(BotAssistantProvider provider) async {
    final success = await provider.confirmAction();
    if (!mounted) {
      return;
    }

    if (!success && provider.error != null) {
      _showSnackBar(provider.error!, isError: true);
      return;
    }

    _showSnackBar('Aksi BOT berhasil dijalankan.', isError: false);
    _scrollToBottom();
  }

  Future<void> _pickActionValue(
    BotActionFieldConfig field,
    BotAssistantProvider provider,
  ) async {
    if (field.type == BotActionFieldType.date) {
      final initial = _parseDate(provider.actionValues[field.name]);
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );

      if (selectedDate != null) {
        provider.updateActionValue(
          field.name,
          DateFormat('yyyy-MM-dd').format(selectedDate),
        );
      }
      return;
    }

    if (field.type == BotActionFieldType.time) {
      final initial = _parseTime(provider.actionValues[field.name]);
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: initial ?? TimeOfDay.now(),
      );

      if (selectedTime != null) {
        final formattedHour = selectedTime.hour.toString().padLeft(2, '0');
        final formattedMinute = selectedTime.minute.toString().padLeft(2, '0');
        provider.updateActionValue(
          field.name,
          '$formattedHour:$formattedMinute',
        );
      }
    }
  }

  DateTime? _parseDate(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw);
  }

  TimeOfDay? _parseTime(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final parts = raw.split(':');
    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
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

  String _formatTimestamp(DateTime? value) {
    if (value == null) {
      return 'Belum ada aktivitas';
    }

    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(value.toLocal());
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

  final BotMessage message;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.isAssistant;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final assistantBubbleColor = isDarkMode
        ? const Color(0xFF111827)
        : Colors.white;
    final assistantBorderColor = isDarkMode
        ? const Color(0xFF253041)
        : AppColors.border;
    final assistantPrimaryText = isDarkMode
        ? const Color(0xFFF8FAFC)
        : AppColors.textPrimary;
    final assistantSecondaryText = isDarkMode
        ? const Color(0xFFCBD5E1)
        : AppColors.textSecondary;
    final warningTextColor =
        Color.lerp(
          Colors.orange,
          isDarkMode ? Colors.white : Colors.black,
          0.22,
        ) ??
        Colors.orange;

    return Align(
      alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isAssistant ? assistantBubbleColor : AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            border: isAssistant
                ? Border.all(color: assistantBorderColor)
                : null,
            boxShadow: isDarkMode
                ? const []
                : [
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
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (isAssistant)
                    Container(
                      width: 18,
                      height: 18,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: assistantBorderColor),
                      ),
                      child: Image.asset(
                        botAssistantAvatarAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.smart_toy_outlined,
                            size: 12,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  Text(
                    isAssistant ? 'TalentVis BOT' : 'Anda',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isAssistant
                          ? assistantSecondaryText
                          : Colors.white.withValues(alpha: 0.90),
                    ),
                  ),
                  Text(
                    '|',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isAssistant
                          ? assistantSecondaryText
                          : Colors.white.withValues(alpha: 0.76),
                    ),
                  ),
                  Text(
                    message.mode.label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isAssistant
                          ? assistantSecondaryText
                          : Colors.white.withValues(alpha: 0.90),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message.content,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.5,
                  color: isAssistant ? assistantPrimaryText : Colors.white,
                ),
              ),
              if (message.requiredFields.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: message.requiredFields
                      .map(
                        (field) => _BubbleChip(
                          label: humanizeBotFieldName(field),
                          color: Colors.orange,
                          isAssistant: isAssistant,
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (message.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isAssistant
                        ? Colors.orange.withValues(
                            alpha: isDarkMode ? 0.16 : 0.08,
                          )
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: message.warnings
                        .map(
                          (warning) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              formatBotWarning(warning),
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: isAssistant
                                    ? warningTextColor
                                    : Colors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
              if (message.sources.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: message.sources
                      .map(
                        (source) => _BubbleChip(
                          label: source.label,
                          color: Colors.teal,
                          isAssistant: isAssistant,
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleChip extends StatelessWidget {
  const _BubbleChip({
    required this.label,
    required this.color,
    required this.isAssistant,
  });

  final String label;
  final Color color;
  final bool isAssistant;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final assistantChipColor = Color.lerp(
      color,
      Colors.white,
      isDarkMode ? 0.16 : 0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAssistant
            ? color.withValues(alpha: isDarkMode ? 0.18 : 0.10)
            : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: isAssistant ? (assistantChipColor ?? color) : Colors.white,
        ),
      ),
    );
  }
}
