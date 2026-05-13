import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../data/models/client_model.dart';
import '../../providers/client_provider.dart';
import '../../widgets/client_card.dart';
import 'assign_employee_screen.dart';
import 'vendor_palette.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().fetchClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorPalette.page(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: VendorPalette.surface(context),
        foregroundColor: VendorPalette.text(context),
        title: Text(
          context.tr('feature_label_clients'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => context.read<ClientProvider>().refreshClients(),
          ),
          IconButton(
            tooltip: 'Create vendor',
            icon: const Icon(Icons.add_circle_outline),
            color: VendorPalette.accent(context),
            onPressed: () => _showClientFormDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearch(),
          Expanded(
            child: Consumer<ClientProvider>(
              builder: (context, clientProvider, child) {
                if (clientProvider.isLoading &&
                    clientProvider.clients.isEmpty) {
                  return _buildLoadingState();
                }

                if (clientProvider.error != null) {
                  return _buildErrorState(clientProvider);
                }

                final filteredClients = clientProvider.clients.where((client) {
                  return client.name.toLowerCase().contains(_searchQuery) ||
                      (client.contactPerson?.toLowerCase().contains(
                            _searchQuery,
                          ) ??
                          false) ||
                      (client.pksNumber?.toLowerCase().contains(_searchQuery) ??
                          false);
                }).toList();

                if (filteredClients.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                  itemCount: filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    return ClientCard(
                      client: client,
                      onTap: () => _showClientDetailDialog(context, client),
                      onAssign: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AssignEmployeeScreen(client: client),
                          ),
                        );
                      },
                      onExtend: () =>
                          _showExtendContractDialog(context, client),
                      onDelete: () =>
                          _showDeleteConfirmationDialog(context, client),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPagination(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: VendorPalette.headerGradient(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VendorPalette.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: VendorPalette.featureGradient(context),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.business_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('feature_label_clients'),
                  style: TextStyle(
                    color: VendorPalette.text(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola vendor, kontak, kontrak, dan penugasan karyawan.',
                  style: TextStyle(
                    color: VendorPalette.mutedText(context),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: VendorPalette.text(context)),
        decoration:
            VendorPalette.inputDecoration(
              context,
              label: 'Search vendors',
              hint: 'Name, contact, or PKS number',
              icon: Icons.search_outlined,
            ).copyWith(
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      color: VendorPalette.mutedText(context),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: VendorPalette.accent(context)),
          const SizedBox(height: 16),
          Text(
            'Loading vendors...',
            style: TextStyle(color: VendorPalette.mutedText(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ClientProvider clientProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 52,
              color: VendorPalette.danger(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${clientProvider.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: VendorPalette.danger(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: VendorPalette.primaryButton(context),
              onPressed: () => clientProvider.refreshClients(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: VendorPalette.mutedText(context),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No vendors found'
                  : 'No vendors matching "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: VendorPalette.mutedText(context),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Consumer<ClientProvider>(
      builder: (context, clientProvider, child) {
        if (clientProvider.lastPage <= 1) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          top: false,
          child: Container(
            color: VendorPalette.surface(context),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: VendorPalette.text(context),
                  disabledColor: VendorPalette.mutedText(context),
                  onPressed: clientProvider.currentPage > 1
                      ? () => clientProvider.goToPage(
                          clientProvider.currentPage - 1,
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: VendorPalette.accentSoft(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Page ${clientProvider.currentPage} of ${clientProvider.lastPage}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: VendorPalette.accent(context),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: VendorPalette.text(context),
                  disabledColor: VendorPalette.mutedText(context),
                  onPressed:
                      clientProvider.currentPage < clientProvider.lastPage
                      ? () => clientProvider.goToPage(
                          clientProvider.currentPage + 1,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showClientFormDialog(
    BuildContext context, {
    Client? client,
  }) async {
    final isEdit = client != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: client?.name);
    final addressController = TextEditingController(text: client?.address);
    final contactPersonController = TextEditingController(
      text: client?.contactPerson,
    );
    final phoneController = TextEditingController(text: client?.phone);
    final pksNumberController = TextEditingController(text: client?.pksNumber);
    final notesController = TextEditingController(text: client?.notes);
    final locationMapController = TextEditingController(
      text: client?.locationMap,
    );

    DateTime? contractStart = client?.contractStart;
    DateTime? contractEnd = client?.contractEnd;
    String selectedStatus = client?.status ?? 'active';
    bool autoRenew = client?.autoRenew ?? false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: VendorPalette.surface(dialogContext),
              title: Text(
                isEdit ? 'Edit Vendor - ${client.name}' : 'Add New Vendor',
                style: TextStyle(color: VendorPalette.text(dialogContext)),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(
                          color: VendorPalette.text(dialogContext),
                        ),
                        decoration: VendorPalette.inputDecoration(
                          dialogContext,
                          label: 'Vendor Name *',
                          icon: Icons.business_outlined,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Vendor name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _dialogTextField(
                        dialogContext,
                        controller: contactPersonController,
                        label: 'Contact Person',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      _dialogTextField(
                        dialogContext,
                        controller: phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _dialogTextField(
                        dialogContext,
                        controller: pksNumberController,
                        label: 'PKS Number',
                        icon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 12),
                      _dialogTextField(
                        dialogContext,
                        controller: addressController,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _dialogTextField(
                        dialogContext,
                        controller: locationMapController,
                        label: 'Location Map (lat,lng)',
                        icon: Icons.map_outlined,
                        hint: '-6.2088,106.8456',
                      ),
                      const SizedBox(height: 12),
                      _dateField(
                        dialogContext,
                        label: 'Contract Start Date',
                        value: contractStart,
                        onPicked: (date) {
                          setDialogState(() => contractStart = date);
                        },
                      ),
                      const SizedBox(height: 12),
                      _dateField(
                        dialogContext,
                        label: 'Contract End Date',
                        value: contractEnd,
                        onPicked: (date) {
                          setDialogState(() => contractEnd = date);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        dropdownColor: VendorPalette.surface(dialogContext),
                        style: TextStyle(
                          color: VendorPalette.text(dialogContext),
                        ),
                        decoration: VendorPalette.inputDecoration(
                          dialogContext,
                          label: 'Status',
                          icon: Icons.info_outline,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'expired',
                            child: Text('Expired'),
                          ),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Auto Renew',
                          style: TextStyle(
                            color: VendorPalette.text(dialogContext),
                          ),
                        ),
                        value: autoRenew,
                        activeColor: VendorPalette.accent(dialogContext),
                        onChanged: (value) {
                          setDialogState(() => autoRenew = value ?? false);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 12),
                      _dialogTextField(
                        dialogContext,
                        controller: notesController,
                        label: 'Notes',
                        icon: Icons.note_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  style: VendorPalette.textButton(dialogContext),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: VendorPalette.primaryButton(dialogContext),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final clientData = {
                      'name': nameController.text,
                      'address': _nullableText(addressController),
                      'contact_person': _nullableText(contactPersonController),
                      'phone': _nullableText(phoneController),
                      'pks_number': _nullableText(pksNumberController),
                      'contract_start': _formatNullableDate(contractStart),
                      'contract_end': _formatNullableDate(contractEnd),
                      'auto_renew': autoRenew,
                      'status': selectedStatus,
                      'notes': _nullableText(notesController),
                      'location_map': _nullableText(locationMapController),
                    };

                    Navigator.pop(dialogContext);
                    await _saveClient(clientData, client: client);
                  },
                  child: Text(isEdit ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  TextFormField _dialogTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: VendorPalette.text(context)),
      decoration: VendorPalette.inputDecoration(
        context,
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }

  Widget _dateField(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPicked,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: VendorPalette.accent(context),
                surface: VendorPalette.surface(context),
                onSurface: VendorPalette.text(context),
              ),
            ),
            child: child!,
          ),
        );

        if (picked != null) {
          onPicked(picked);
        }
      },
      child: InputDecorator(
        decoration: VendorPalette.inputDecoration(
          context,
          label: label,
          icon: Icons.calendar_today_outlined,
        ),
        child: Text(
          value != null
              ? DateFormat('yyyy-MM-dd').format(value)
              : 'Select date',
          style: TextStyle(color: VendorPalette.text(context)),
        ),
      ),
    );
  }

  Future<void> _saveClient(
    Map<String, dynamic> clientData, {
    Client? client,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: VendorPalette.accent(context)),
      ),
    );

    final provider = context.read<ClientProvider>();
    final success = client == null
        ? await provider.createClient(clientData)
        : await provider.updateClient(client.id, clientData);

    if (mounted) Navigator.pop(context);

    if (success && mounted) {
      _showSnack(
        client == null
            ? 'Vendor added successfully'
            : 'Vendor updated successfully',
        success: true,
      );
    } else if (mounted) {
      _showSnack(provider.error ?? 'Failed to save vendor');
    }
  }

  void _showClientDetailDialog(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VendorPalette.surface(dialogContext),
        title: Text(
          client.name,
          style: TextStyle(color: VendorPalette.text(dialogContext)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem(
                dialogContext,
                'Contact Person',
                client.contactPerson ?? '-',
              ),
              _buildDetailItem(dialogContext, 'Phone', client.phone ?? '-'),
              _buildDetailItem(
                dialogContext,
                'PKS Number',
                client.pksNumber ?? '-',
              ),
              _buildDetailItem(dialogContext, 'Address', client.address ?? '-'),
              _buildDetailItem(
                dialogContext,
                'Contract Period',
                client.getFormattedContractPeriod(),
              ),
              _buildDetailItem(
                dialogContext,
                'Status',
                client.status ?? '-',
                color: _statusColor(dialogContext, client.status),
              ),
              if (client.notes != null && client.notes!.isNotEmpty)
                _buildDetailItem(dialogContext, 'Notes', client.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: VendorPalette.textButton(dialogContext),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: VendorPalette.primaryButton(dialogContext),
            onPressed: () {
              Navigator.pop(dialogContext);
              _showClientFormDialog(context, client: client);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              '$label:',
              style: TextStyle(
                color: VendorPalette.mutedText(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? VendorPalette.text(context),
                fontWeight: color != null ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExtendContractDialog(BuildContext context, Client client) {
    final dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VendorPalette.surface(dialogContext),
        title: Text(
          'Extend Contract - ${client.name}',
          style: TextStyle(color: VendorPalette.text(dialogContext)),
        ),
        content: TextField(
          controller: dateController,
          style: TextStyle(color: VendorPalette.text(dialogContext)),
          decoration: VendorPalette.inputDecoration(
            dialogContext,
            label: 'New End Date (YYYY-MM-DD)',
            hint: '2026-12-31',
            icon: Icons.event_available_outlined,
          ),
        ),
        actions: [
          TextButton(
            style: VendorPalette.textButton(dialogContext),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: VendorPalette.primaryButton(dialogContext),
            onPressed: () async {
              if (dateController.text.isEmpty) return;

              Navigator.pop(dialogContext);
              final success = await context
                  .read<ClientProvider>()
                  .extendContract(client.id, dateController.text);

              if (success && mounted) {
                _showSnack('Contract extended successfully', success: true);
              } else if (mounted) {
                _showSnack('Failed to extend contract');
              }
            },
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VendorPalette.surface(dialogContext),
        title: Text(
          'Delete Vendor',
          style: TextStyle(color: VendorPalette.text(dialogContext)),
        ),
        content: Text(
          'Are you sure you want to delete "${client.name}"?',
          style: TextStyle(color: VendorPalette.mutedText(dialogContext)),
        ),
        actions: [
          TextButton(
            style: VendorPalette.textButton(dialogContext),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: VendorPalette.dangerButton(dialogContext),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await context.read<ClientProvider>().deleteClient(
                client.id,
              );

              if (success && mounted) {
                _showSnack('Vendor deleted successfully', success: true);
              } else if (mounted) {
                _showSnack('Failed to delete vendor');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String? _formatNullableDate(DateTime? date) {
    return date == null ? null : DateFormat('yyyy-MM-dd').format(date);
  }

  Color _statusColor(BuildContext context, String? status) {
    switch (status) {
      case 'active':
        return VendorPalette.success(context);
      case 'expired':
        return VendorPalette.danger(context);
      case 'pending':
        return VendorPalette.warmAccent(context);
      default:
        return VendorPalette.mutedText(context);
    }
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? VendorPalette.success(context)
            : VendorPalette.danger(context),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
