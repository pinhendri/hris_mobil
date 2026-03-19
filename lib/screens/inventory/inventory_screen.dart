import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory & Assets',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
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
                      _showRequestDialog(context, preselectedItem: item),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRequestDialog(context),
        backgroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Request Asset',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _showRequestDialog(
    BuildContext context, {
    InventoryModel? preselectedItem,
  }) async {
    final provider = context.read<InventoryProvider>();
    final auth = context.read<AuthProvider>();

    if (provider.inventories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data inventory belum tersedia.')),
      );
      return;
    }

    await provider.fetchNextRequestNumber();
    if (!context.mounted) {
      return;
    }

    var selectedInventory = preselectedItem ?? provider.inventories.first;
    var selectedPriority = 'medium';

    final requestedBy = auth.user?.name ?? '';
    final departmentController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final purposeController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer<InventoryProvider>(
          builder: (dialogContext, inventoryProvider, child) {
            return StatefulBuilder(
              builder: (dialogContext, setState) {
                return AlertDialog(
                  title: Text(
                    'Request Asset',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RequestInfoRow(
                          label: 'Request No.',
                          value:
                              inventoryProvider.nextRequestNumber ??
                              'Memuat...',
                        ),
                        const SizedBox(height: 8),
                        _RequestInfoRow(
                          label: 'Requested By',
                          value: requestedBy.isEmpty ? '-' : requestedBy,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedInventory.id,
                          decoration: const InputDecoration(
                            labelText: 'Asset',
                            border: OutlineInputBorder(),
                          ),
                          items: provider.inventories
                              .map((item) {
                                return DropdownMenuItem<String>(
                                  value: item.id,
                                  child: Text(
                                    '${item.name} (${item.stock} ${item.unit})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              })
                              .toList(growable: false),
                          onChanged: inventoryProvider.isSubmitting
                              ? null
                              : (value) {
                                  final selected = provider.inventories
                                      .firstWhere(
                                        (item) => item.id == value,
                                        orElse: () => selectedInventory,
                                      );
                                  setState(() {
                                    selectedInventory = selected;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: departmentController,
                          enabled: !inventoryProvider.isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: quantityController,
                                enabled: !inventoryProvider.isSubmitting,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Qty',
                                  helperText:
                                      'Stok tersedia: ${selectedInventory.stock}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedPriority,
                                decoration: const InputDecoration(
                                  labelText: 'Priority',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'low',
                                    child: Text('Low'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'medium',
                                    child: Text('Medium'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'high',
                                    child: Text('High'),
                                  ),
                                ],
                                onChanged: inventoryProvider.isSubmitting
                                    ? null
                                    : (value) {
                                        if (value == null) {
                                          return;
                                        }
                                        setState(() {
                                          selectedPriority = value;
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: purposeController,
                          enabled: !inventoryProvider.isSubmitting,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Purpose',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: notesController,
                          enabled: !inventoryProvider.isSubmitting,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (inventoryProvider.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            inventoryProvider.error!,
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: inventoryProvider.isSubmitting
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: inventoryProvider.isSubmitting
                          ? null
                          : () async {
                              final quantity =
                                  int.tryParse(
                                    quantityController.text.trim(),
                                  ) ??
                                  0;
                              if (requestedBy.isEmpty) {
                                _showDialogSnackBar(
                                  dialogContext,
                                  'Data user tidak tersedia. Login ulang lalu coba lagi.',
                                );
                                return;
                              }
                              if (departmentController.text.trim().isEmpty) {
                                _showDialogSnackBar(
                                  dialogContext,
                                  'Department wajib diisi.',
                                );
                                return;
                              }
                              if (purposeController.text.trim().isEmpty) {
                                _showDialogSnackBar(
                                  dialogContext,
                                  'Purpose wajib diisi.',
                                );
                                return;
                              }
                              if (quantity <= 0) {
                                _showDialogSnackBar(
                                  dialogContext,
                                  'Quantity harus lebih dari 0.',
                                );
                                return;
                              }
                              if (quantity > selectedInventory.stock) {
                                _showDialogSnackBar(
                                  dialogContext,
                                  'Quantity melebihi stok yang tersedia.',
                                );
                                return;
                              }

                              final success = await inventoryProvider
                                  .submitRequest(
                                    requestedBy: requestedBy,
                                    department: departmentController.text
                                        .trim(),
                                    inventory: selectedInventory,
                                    quantity: quantity,
                                    purpose: purposeController.text.trim(),
                                    priority: selectedPriority,
                                    notes: notesController.text.trim(),
                                  );

                              if (!dialogContext.mounted) {
                                return;
                              }

                              if (success) {
                                Navigator.of(dialogContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Request asset berhasil dikirim.',
                                    ),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                      ),
                      child: inventoryProvider.isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Kirim',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showDialogSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.onRequest});

  final InventoryModel item;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.stock <= item.minStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.code} • ${item.category}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
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
                        ? const Color(0xFFFDE8E8)
                        : const Color(0xFFDEF7EC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLowStock ? 'Low Stock' : 'Ready',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isLowStock
                          ? const Color(0xFF9B1C1C)
                          : const Color(0xFF03543F),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onAction(),
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
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade900,
            ),
          ),
        ),
      ],
    );
  }
}
