import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/client_provider.dart';
import '../../widgets/client_card.dart';
import '../../data/models/client_model.dart';
import 'assign_employee_screen.dart'; // Tambahkan import ini
import 'package:intl/intl.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({Key? key}) : super(key: key);

  @override
  _ClientScreenState createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientProvider>(context, listen: false).fetchClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ClientProvider>(context, listen: false).refreshClients();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddClientDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<ClientProvider>(
              builder: (context, clientProvider, child) {
                if (clientProvider.isLoading && clientProvider.clients.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading clients...'),
                      ],
                    ),
                  );
                }

                if (clientProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${clientProvider.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => clientProvider.refreshClients(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredClients = clientProvider.clients.where((client) {
                  return client.name.toLowerCase().contains(_searchQuery) ||
                      (client.contactPerson?.toLowerCase().contains(_searchQuery) ?? false) ||
                      (client.pksNumber?.toLowerCase().contains(_searchQuery) ?? false);
                }).toList();

                if (filteredClients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.business, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No clients found'
                              : 'No clients matching "$_searchQuery"',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    return ClientCard(
                      client: client,
                      onTap: () {
                        _showClientDetailDialog(context, client);
                      },
                      onAssign: () {  // TAMBAHKAN PARAMETER onAssign DI SINI
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssignEmployeeScreen(client: client),
                          ),
                        );
                      },
                      onExtend: () {
                        _showExtendContractDialog(context, client);
                      },
                      onDelete: () {
                        _showDeleteConfirmationDialog(context, client);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<ClientProvider>(
        builder: (context, clientProvider, child) {
          if (clientProvider.lastPage > 1) {
            return Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: clientProvider.currentPage > 1
                        ? () => clientProvider.goToPage(clientProvider.currentPage - 1)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Page ${clientProvider.currentPage} of ${clientProvider.lastPage}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: clientProvider.currentPage < clientProvider.lastPage
                        ? () => clientProvider.goToPage(clientProvider.currentPage + 1)
                        : null,
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // Gunakan hanya satu versi _showAddClientDialog - yang sudah diperbaiki dengan dialogContext
  void _showAddClientDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final contactPersonController = TextEditingController();
    final phoneController = TextEditingController();
    final pksNumberController = TextEditingController();
    final notesController = TextEditingController();
    final locationMapController = TextEditingController();
    
    DateTime? contractStart;
    DateTime? contractEnd;
    String selectedStatus = 'active';
    bool autoRenew = false;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Client'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nama Client (required)
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Client Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Client name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Contact Person
                TextFormField(
                  controller: contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Phone
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                
                // PKS Number
                TextFormField(
                  controller: pksNumberController,
                  decoration: const InputDecoration(
                    labelText: 'PKS Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Address
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                
                // Location Map (lat,lng)
                TextFormField(
                  controller: locationMapController,
                  decoration: const InputDecoration(
                    labelText: 'Location Map (lat,lng)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                    hintText: '-6.2088,106.8456',
                  ),
                ),
                const SizedBox(height: 12),
                
                // Contract Start Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      contractStart = picked;
                      (dialogContext as Element).markNeedsBuild();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Contract Start Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      contractStart != null 
                          ? DateFormat('yyyy-MM-dd').format(contractStart!)
                          : 'Select date',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Contract End Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      contractEnd = picked;
                      (dialogContext as Element).markNeedsBuild();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Contract End Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      contractEnd != null 
                          ? DateFormat('yyyy-MM-dd').format(contractEnd!)
                          : 'Select date',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Status Dropdown
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'expired', child: Text('Expired')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                ),
                const SizedBox(height: 12),
                
                // Auto Renew
                CheckboxListTile(
                  title: const Text('Auto Renew'),
                  value: autoRenew,
                  onChanged: (value) {
                    autoRenew = value!;
                    (dialogContext as Element).markNeedsBuild();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                
                // Notes
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Prepare data for API
                final clientData = {
                  'name': nameController.text,
                  'address': addressController.text.isEmpty ? null : addressController.text,
                  'contact_person': contactPersonController.text.isEmpty ? null : contactPersonController.text,
                  'phone': phoneController.text.isEmpty ? null : phoneController.text,
                  'pks_number': pksNumberController.text.isEmpty ? null : pksNumberController.text,
                  'contract_start': contractStart != null 
                      ? DateFormat('yyyy-MM-dd').format(contractStart!)
                      : null,
                  'contract_end': contractEnd != null 
                      ? DateFormat('yyyy-MM-dd').format(contractEnd!)
                      : null,
                  'auto_renew': autoRenew,
                  'status': selectedStatus,
                  'notes': notesController.text.isEmpty ? null : notesController.text,
                  'location_map': locationMapController.text.isEmpty ? null : locationMapController.text,
                };

                // Tutup dialog add client
                Navigator.pop(dialogContext);
                
                // Tampilkan loading dialog
                if (mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (loadingContext) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // Call API
                final success = await Provider.of<ClientProvider>(
                  context,
                  listen: false,
                ).createClient(clientData);

                // Tutup loading dialog
                if (mounted) {
                  try {
                    Navigator.pop(context);
                  } catch (e) {
                    print('Error closing loading dialog: $e');
                  }
                }

                // Show result
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Client added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  final errorMsg = Provider.of<ClientProvider>(
                    context,
                    listen: false,
                  ).error ?? 'Unknown error';
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add client: $errorMsg'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClientDetailDialog(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Contact Person', client.contactPerson ?? '-'),
              _buildDetailItem('Phone', client.phone ?? '-'),
              _buildDetailItem('PKS Number', client.pksNumber ?? '-'),
              _buildDetailItem('Address', client.address ?? '-'),
              _buildDetailItem('Contract Period', client.getFormattedContractPeriod()),
              _buildDetailItem('Status', client.status ?? '-',
                  color: client.getStatusColor()),
              if (client.notes != null && client.notes!.isNotEmpty)
                _buildDetailItem('Notes', client.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditClientDialog(context, client);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showEditClientDialog(BuildContext context, Client client) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: client.name);
    final addressController = TextEditingController(text: client.address);
    final contactPersonController = TextEditingController(text: client.contactPerson);
    final phoneController = TextEditingController(text: client.phone);
    final pksNumberController = TextEditingController(text: client.pksNumber);
    final notesController = TextEditingController(text: client.notes);
    
    DateTime? contractStart = client.contractStart;
    DateTime? contractEnd = client.contractEnd;
    String selectedStatus = client.status ?? 'active';
    bool autoRenew = client.autoRenew ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Client - ${client.name}'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Client Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Client name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pksNumberController,
                  decoration: const InputDecoration(
                    labelText: 'PKS Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'expired', child: Text('Expired')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Auto Renew'),
                  value: autoRenew,
                  onChanged: (value) {
                    autoRenew = value!;
                    (context as Element).markNeedsBuild();
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final clientData = {
                  'name': nameController.text,
                  'address': addressController.text.isEmpty ? null : addressController.text,
                  'contact_person': contactPersonController.text.isEmpty ? null : contactPersonController.text,
                  'phone': phoneController.text.isEmpty ? null : phoneController.text,
                  'pks_number': pksNumberController.text.isEmpty ? null : pksNumberController.text,
                  'contract_start': contractStart != null 
                      ? DateFormat('yyyy-MM-dd').format(contractStart)
                      : null,
                  'contract_end': contractEnd != null 
                      ? DateFormat('yyyy-MM-dd').format(contractEnd)
                      : null,
                  'auto_renew': autoRenew,
                  'status': selectedStatus,
                  'notes': notesController.text.isEmpty ? null : notesController.text,
                };

                Navigator.pop(context);
                
                final success = await Provider.of<ClientProvider>(
                  context,
                  listen: false,
                ).updateClient(client.id, clientData);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Client updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update client'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: color != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExtendContractDialog(BuildContext context, Client client) {
    final TextEditingController dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Extend Contract - ${client.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'New End Date (YYYY-MM-DD)',
                hintText: '2026-12-31',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dateController.text.isNotEmpty) {
                Navigator.pop(context);
                final success = await Provider.of<ClientProvider>(
                  context,
                  listen: false,
                ).extendContract(client.id, dateController.text);
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contract extended successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to extend contract'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete "${client.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await Provider.of<ClientProvider>(
                context,
                listen: false,
              ).deleteClient(client.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Client deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete client'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}