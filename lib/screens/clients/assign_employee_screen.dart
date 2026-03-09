import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/client_provider.dart';
import '../../data/models/client_model.dart';
import '../../data/models/assignment_model.dart';
import 'package:intl/intl.dart';

class AssignEmployeeScreen extends StatefulWidget {
  final Client client;

  const AssignEmployeeScreen({Key? key, required this.client}) : super(key: key);

  @override
  _AssignEmployeeScreenState createState() => _AssignEmployeeScreenState();
}

class _AssignEmployeeScreenState extends State<AssignEmployeeScreen> with SingleTickerProviderStateMixin {
  final List<String> _selectedEmployeeUuids = [];
  DateTime? _selectedDate;
  final TextEditingController _roleController = TextEditingController();
  String? _selectedRole;
  int _currentTab = 0;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTab = _tabController.index;
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    
    try {
      await clientProvider.fetchAssignedEmployees(widget.client.id);
      if (mounted) {
        await clientProvider.fetchAvailableEmployees(widget.client.id);
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Employees - ${widget.client.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Assign', icon: Icon(Icons.person_add)),
            Tab(text: 'Assigned', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: Consumer<ClientProvider>(
        builder: (context, clientProvider, child) {
          if (clientProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return IndexedStack(
            index: _currentTab,
            children: [
              _buildAssignTab(clientProvider),
              _buildAssignedListTab(clientProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAssignTab(ClientProvider clientProvider) {
    return Column(
      children: [
        // Card untuk Assignment Details
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assignment Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Shift Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Shift Date *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                            : 'Select date',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Role
                  TextFormField(
                    controller: _roleController,
                    decoration: const InputDecoration(
                      labelText: 'Role (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    onChanged: (value) {
                      _selectedRole = value.isEmpty ? null : value;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Available Employees List
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Employees',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedEmployeeUuids.length} selected',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: clientProvider.availableEmployees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No available employees',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: clientProvider.availableEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = clientProvider.availableEmployees[index];
                            final isSelected = _selectedEmployeeUuids.contains(employee.uuid);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: CheckboxListTile(
                                title: Text(
                                  employee.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(employee.position ?? 'No position'),
                                value: isSelected,
                                secondary: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: isSelected ? Colors.blue : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedEmployeeUuids.add(employee.uuid);
                                    } else {
                                      _selectedEmployeeUuids.remove(employee.uuid);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // Submit Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedDate == null || _selectedEmployeeUuids.isEmpty
                  ? null
                  : () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (loadingContext) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        final success = await clientProvider.assignEmployees(
                          widget.client.id,
                          _selectedEmployeeUuids,
                          DateFormat('yyyy-MM-dd').format(_selectedDate!),
                          role: _selectedRole,
                        );

                        if (mounted) {
                          Navigator.pop(context);
                        }

                        if (success && mounted) {
                          setState(() {
                            _selectedEmployeeUuids.clear();
                            _selectedDate = null;
                            _roleController.clear();
                          });
                          
                          await _loadData();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Employees assigned successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed: ${clientProvider.error ?? 'Unknown error'}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Assign Selected Employees'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedListTab(ClientProvider clientProvider) {
    if (clientProvider.assignedEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No employees assigned yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clientProvider.assignedEmployees.length,
      itemBuilder: (context, index) {
        final assignment = clientProvider.assignedEmployees[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            title: Text(assignment.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (assignment.role != null)
                  Text('Role: ${assignment.role}'),
                if (assignment.shiftDate != null)
                  Text('Shift Date: ${assignment.shiftDate}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showRemoveDialog(clientProvider, assignment),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRemoveDialog(ClientProvider clientProvider, EmployeeAssignment assignment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Assignment'),
        content: Text('Remove ${assignment.name} from this client?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final success = await clientProvider.removeAssignedEmployee(
          widget.client.id,
          assignment.uuid,
        );

        if (mounted) {
          Navigator.pop(context);
        }

        if (success && mounted) {
          await _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee removed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }
}