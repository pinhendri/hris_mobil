import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/inventory_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _pageColor(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF020817) : const Color(0xFFF8FAFC);

Color _surfaceColor(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF111827) : Colors.white;

Color _mutedSurfaceColor(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF0F172A) : Colors.white;

Color _primaryTextColor(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

Color _secondaryTextColor(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

Color _borderColor(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF253041) : const Color(0xFFE2E8F0);

List<BoxShadow> _surfaceShadow(BuildContext context) => _isDarkMode(context)
    ? [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.24),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ]
    : [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pageColor = _pageColor(context);
    final surfaceColor = _surfaceColor(context);
    final primaryTextColor = _primaryTextColor(context);

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        title: Text(
          'Inventory & Assets',
          style: GoogleFonts.poppins(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: surfaceColor,
        surfaceTintColor: surfaceColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _openRequestForm(context),
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.inventories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.inventories.isEmpty) {
            return _InventoryMessageView(
              icon: Icons.inventory_2_outlined,
              title: 'Gagal memuat inventory',
              description: provider.error!,
              actionLabel: 'Coba lagi',
              onAction: provider.refresh,
            );
          }

          if (provider.inventories.isEmpty) {
            return _InventoryMessageView(
              icon: Icons.inventory,
              title: 'Belum ada asset',
              description: 'Data inventory belum tersedia untuk company ini.',
              actionLabel: 'Refresh',
              onAction: provider.refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.inventories.length,
              itemBuilder: (context, index) {
                final item = provider.inventories[index];
                return _InventoryCard(
                  item: item,
                  onRequest: () =>
                      _openRequestForm(context, preselectedItem: item),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openRequestForm(
    BuildContext context, {
    InventoryModel? preselectedItem,
  }) {
    final provider = context.read<InventoryProvider>();

    if (provider.inventories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data inventory belum tersedia.')),
      );
      return;
    }

    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: _InventoryRequestFormScreen(preselectedItem: preselectedItem),
        ),
      ),
    );
  }
}

class _InventoryRequestFormScreen extends StatefulWidget {
  const _InventoryRequestFormScreen({this.preselectedItem});

  final InventoryModel? preselectedItem;

  @override
  State<_InventoryRequestFormScreen> createState() =>
      _InventoryRequestFormScreenState();
}

class _InventoryRequestFormScreenState
    extends State<_InventoryRequestFormScreen> {
  late InventoryModel _selectedInventory;
  String _selectedPriority = 'medium';
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isPreparing = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<InventoryProvider>();
    _selectedInventory = widget.preselectedItem ?? provider.inventories.first;
    Future.microtask(_prepareRequestNumber);
  }

  Future<void> _prepareRequestNumber() async {
    await context.read<InventoryProvider>().fetchNextRequestNumber();
    if (mounted) {
      setState(() => _isPreparing = false);
    }
  }

  @override
  void dispose() {
    _departmentController.dispose();
    _quantityController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<InventoryProvider>();
    final auth = context.read<AuthProvider>();
    final requestedBy = auth.user?.name ?? '';
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;

    if (requestedBy.isEmpty) {
      _showMessage('Data user tidak tersedia. Login ulang lalu coba lagi.');
      return;
    }
    if (_departmentController.text.trim().isEmpty) {
      _showMessage('Department wajib diisi.');
      return;
    }
    if (_purposeController.text.trim().isEmpty) {
      _showMessage('Purpose wajib diisi.');
      return;
    }
    if (quantity <= 0) {
      _showMessage('Quantity harus lebih dari 0.');
      return;
    }
    if (quantity > _selectedInventory.stock) {
      _showMessage('Quantity melebihi stok yang tersedia.');
      return;
    }

    final success = await provider.submitRequest(
      requestedBy: requestedBy,
      department: _departmentController.text.trim(),
      inventory: _selectedInventory,
      quantity: quantity,
      purpose: _purposeController.text.trim(),
      priority: _selectedPriority,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request asset berhasil dikirim.')),
      );
      Navigator.pop(context, true);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final auth = context.watch<AuthProvider>();
    final requestedBy = auth.user?.name ?? '-';
    final pageColor = _pageColor(context);
    final surfaceColor = _surfaceColor(context);
    final primaryTextColor = _primaryTextColor(context);

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        title: Text(
          'Request Asset',
          style: GoogleFonts.poppins(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: surfaceColor,
        surfaceTintColor: surfaceColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: provider.isSubmitting || _isPreparing ? null : _submit,
            child: provider.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Kirim',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: _isPreparing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Request Info'),
                  const SizedBox(height: 16),
                  _RequestInfoRow(
                    label: 'Request No.',
                    value: provider.nextRequestNumber ?? 'Memuat...',
                  ),
                  const SizedBox(height: 8),
                  _RequestInfoRow(label: 'Requested By', value: requestedBy),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Asset Detail'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedInventory.id,
                    decoration: _inputDecoration('Asset'),
                    items: provider.inventories
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(
                              '${item.name} (${item.stock} ${item.unit})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: provider.isSubmitting
                        ? null
                        : (value) {
                            final selected = provider.inventories.firstWhere(
                              (item) => item.id == value,
                              orElse: () => _selectedInventory,
                            );
                            setState(() => _selectedInventory = selected);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _departmentController,
                    enabled: !provider.isSubmitting,
                    decoration: _inputDecoration('Department'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          enabled: !provider.isSubmitting,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Qty',
                            helperText:
                                'Stok tersedia: ${_selectedInventory.stock}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPriority,
                          decoration: _inputDecoration('Priority'),
                          items: const [
                            DropdownMenuItem(value: 'low', child: Text('Low')),
                            DropdownMenuItem(
                              value: 'medium',
                              child: Text('Medium'),
                            ),
                            DropdownMenuItem(
                              value: 'high',
                              child: Text('High'),
                            ),
                          ],
                          onChanged: provider.isSubmitting
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _selectedPriority = value);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _purposeController,
                    enabled: !provider.isSubmitting,
                    maxLines: 2,
                    decoration: _inputDecoration('Purpose'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    enabled: !provider.isSubmitting,
                    maxLines: 3,
                    decoration: _inputDecoration('Notes'),
                  ),
                  if (provider.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      provider.error!,
                      style: GoogleFonts.poppins(
                        color: Colors.red.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: _primaryTextColor(context),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? helperText}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      filled: true,
      fillColor: _mutedSurfaceColor(context),
      labelStyle: GoogleFonts.poppins(color: _secondaryTextColor(context)),
      helperStyle: GoogleFonts.poppins(color: _secondaryTextColor(context)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.onRequest});

  final InventoryModel item;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.stock <= item.minStock;
    final isDark = _isDarkMode(context);
    final surfaceColor = _surfaceColor(context);
    final primaryTextColor = _primaryTextColor(context);
    final secondaryTextColor = _secondaryTextColor(context);
    final borderColor = _borderColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: _surfaceShadow(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.code} - ${item.category}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? (isDark
                              ? const Color(0xFF7F1D1D).withValues(alpha: 0.36)
                              : const Color(0xFFFDE8E8))
                        : (isDark
                              ? const Color(0xFF064E3B).withValues(alpha: 0.34)
                              : const Color(0xFFDEF7EC)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLowStock ? 'Low Stock' : 'Ready',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isLowStock
                          ? (isDark
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFF9B1C1C))
                          : (isDark
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFF03543F)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InventoryInfoItem(
                  icon: Icons.inventory_2_outlined,
                  text: '${item.stock} ${item.unit}',
                ),
                _InventoryInfoItem(
                  icon: Icons.attach_money,
                  text: item.purchasePrice.toStringAsFixed(0),
                ),
                _InventoryInfoItem(icon: Icons.info_outline, text: item.status),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.post_add),
                label: const Text('Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryInfoItem extends StatelessWidget {
  const _InventoryInfoItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textColor = _secondaryTextColor(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 2),
        Icon(icon, size: 16, color: textColor),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.poppins(fontSize: 12, color: textColor)),
      ],
    );
  }
}

class _InventoryMessageView extends StatelessWidget {
  const _InventoryMessageView({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);
    final primaryTextColor = _primaryTextColor(context);
    final secondaryTextColor = _secondaryTextColor(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onAction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestInfoRow extends StatelessWidget {
  const _RequestInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = _primaryTextColor(context);
    final secondaryTextColor = _secondaryTextColor(context);

    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 12, color: primaryTextColor),
          ),
        ),
      ],
    );
  }
}
