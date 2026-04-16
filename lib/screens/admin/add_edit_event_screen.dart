import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/calendar_event_model.dart';
import '../../models/employee_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/event_provider.dart';

class AddEditEventScreen extends StatefulWidget {
  final CalendarEvent? event;

  const AddEditEventScreen({super.key, this.event});

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  late DateTime _startsAt;
  DateTime? _endsAt;
  bool _isCompanyWide = false;
  final Set<String> _selectedInvitees = <String>{};
  String _loadedCompanyCode = '';

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController.text = event?.title ?? '';
    _locationController.text = event?.location ?? '';
    _descriptionController.text = event?.description ?? '';
    _startsAt = event?.startsAt ?? DateTime.now().add(const Duration(hours: 1));
    _endsAt = event?.endsAt;
    _isCompanyWide = event?.isCompanyWide ?? false;
    _selectedInvitees.addAll(event?.invitedEmployeeUuids ?? const []);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final companyCode = context.read<AuthProvider>().getCompanyCode().trim();
    if (_loadedCompanyCode == companyCode) {
      return;
    }

    _loadedCompanyCode = companyCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<EmployeeProvider>().fetchAllEmployees(
        companyCode: companyCode,
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart
        ? _startsAt
        : (_endsAt ?? _startsAt.add(const Duration(hours: 1)));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    final pickedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startsAt = pickedDateTime;
        if (_endsAt != null && _endsAt!.isBefore(_startsAt)) {
          _endsAt = _startsAt.add(const Duration(hours: 1));
        }
      } else {
        _endsAt = pickedDateTime;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isCompanyWide && _selectedInvitees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu karyawan untuk diundang.'),
        ),
      );
      return;
    }

    final provider = context.read<EventProvider>();
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final description = _descriptionController.text.trim();
    final invitees = _isCompanyWide
        ? const <String>[]
        : _selectedInvitees.toList(growable: false);

    final success = widget.event == null
        ? await provider.createEvent(
            title: title,
            description: description,
            location: location,
            startsAt: _startsAt,
            endsAt: _endsAt,
            isCompanyWide: _isCompanyWide,
            inviteEmployeeUuids: invitees,
          )
        : await provider.updateEvent(
            eventId: widget.event!.id,
            title: title,
            description: description,
            location: location,
            startsAt: _startsAt,
            endsAt: _endsAt,
            isCompanyWide: _isCompanyWide,
            inviteEmployeeUuids: invitees,
          );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'Gagal menyimpan event.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final eventProvider = context.watch<EventProvider>();
    final companyCode = context.watch<AuthProvider>().getCompanyCode();
    final employees = _filterEmployees(employeeProvider.employees, companyCode);
    final query = _searchController.text.trim().toLowerCase();
    final filteredEmployees = employees
        .where(
          (employee) =>
              employee.name.toLowerCase().contains(query) ||
              employee.position.toLowerCase().contains(query),
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
        actions: [
          TextButton(
            onPressed: eventProvider.isSubmitting ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul event wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _DateTimeTile(
                label: 'Start',
                value: _formatDateTime(_startsAt),
                onTap: () => _pickDateTime(isStart: true),
              ),
              const SizedBox(height: 12),
              _DateTimeTile(
                label: 'End',
                value: _endsAt == null ? 'Optional' : _formatDateTime(_endsAt!),
                onTap: () => _pickDateTime(isStart: false),
                onClear: _endsAt == null
                    ? null
                    : () {
                        setState(() {
                          _endsAt = null;
                        });
                      },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isCompanyWide,
                contentPadding: EdgeInsets.zero,
                title: const Text('Company-wide event'),
                subtitle: const Text(
                  'Jika aktif, semua karyawan di company ini bisa melihat event.',
                ),
                onChanged: (value) {
                  setState(() {
                    _isCompanyWide = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (!_isCompanyWide) ...[
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Cari karyawan untuk diundang',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Invitees (${_selectedInvitees.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: employeeProvider.isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : filteredEmployees.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Tidak ada karyawan yang bisa dipilih.'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = filteredEmployees[index];
                            final isSelected = _selectedInvitees.contains(
                              employee.uuid,
                            );

                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(employee.name),
                              subtitle: Text(
                                employee.position.isEmpty
                                    ? employee.department
                                    : '${employee.position} • ${employee.department}',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedInvitees.add(employee.uuid);
                                  } else {
                                    _selectedInvitees.remove(employee.uuid);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: eventProvider.isSubmitting ? null : _save,
                  child: eventProvider.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.event == null
                              ? 'Create Event'
                              : 'Update Event',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Employee> _filterEmployees(
    List<Employee> employees,
    String companyCode,
  ) {
    if (companyCode.isEmpty) {
      return employees;
    }

    final filtered = employees
        .where((employee) {
          final eventCompanyCode =
              (employee.cCode ?? employee.companyCode ?? '').trim();

          if (eventCompanyCode.isEmpty) {
            return true;
          }

          return eventCompanyCode == companyCode;
        })
        .toList(growable: false);

    return filtered;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }
}

class _DateTimeTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(label),
      subtitle: Text(value),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
          IconButton(onPressed: onTap, icon: const Icon(Icons.edit_calendar)),
        ],
      ),
      onTap: onTap,
    );
  }
}
