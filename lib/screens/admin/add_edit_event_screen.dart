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

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _pageColor =>
      _isDarkMode ? const Color(0xFF020817) : const Color(0xFFF8FAFC);

  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF111827) : Colors.white;

  Color get _fieldColor => _isDarkMode ? const Color(0xFF0F172A) : Colors.white;

  Color get _borderColor =>
      _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  Color get _primaryTextColor =>
      _isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: _secondaryTextColor),
      labelStyle: TextStyle(color: _secondaryTextColor),
      hintStyle: TextStyle(color: _secondaryTextColor),
      filled: true,
      fillColor: _fieldColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
      ),
    );
  }

  ThemeData _pickerTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        surface: _surfaceColor,
        onSurface: _primaryTextColor,
        primary: const Color(0xFF2563EB),
        onPrimary: Colors.white,
      ),
      dialogTheme: DialogThemeData(backgroundColor: _surfaceColor),
    );
  }

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
      builder: (context, child) =>
          Theme(data: _pickerTheme(context), child: child!),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) =>
          Theme(data: _pickerTheme(context), child: child!),
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
      backgroundColor: _pageColor,
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
        backgroundColor: _surfaceColor,
        surfaceTintColor: _surfaceColor,
        foregroundColor: _primaryTextColor,
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
                style: TextStyle(color: _primaryTextColor),
                decoration: _inputDecoration('Event Title'),
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
                style: TextStyle(color: _primaryTextColor),
                decoration: _inputDecoration('Location'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                style: TextStyle(color: _primaryTextColor),
                decoration: _inputDecoration('Description'),
              ),
              const SizedBox(height: 16),
              _DateTimeTile(
                label: 'Start',
                value: _formatDateTime(_startsAt),
                surfaceColor: _surfaceColor,
                borderColor: _borderColor,
                primaryTextColor: _primaryTextColor,
                secondaryTextColor: _secondaryTextColor,
                onTap: () => _pickDateTime(isStart: true),
              ),
              const SizedBox(height: 12),
              _DateTimeTile(
                label: 'End',
                value: _endsAt == null ? 'Optional' : _formatDateTime(_endsAt!),
                surfaceColor: _surfaceColor,
                borderColor: _borderColor,
                primaryTextColor: _primaryTextColor,
                secondaryTextColor: _secondaryTextColor,
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
                title: Text(
                  'Company-wide event',
                  style: TextStyle(color: _primaryTextColor),
                ),
                subtitle: Text(
                  'Jika aktif, semua karyawan di company ini bisa melihat event.',
                  style: TextStyle(color: _secondaryTextColor),
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
                  style: TextStyle(color: _primaryTextColor),
                  decoration: _inputDecoration(
                    'Cari karyawan untuk diundang',
                    icon: Icons.search,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Invitees (${_selectedInvitees.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _primaryTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    border: Border.all(color: _borderColor),
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
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Tidak ada karyawan yang bisa dipilih.',
                            style: TextStyle(color: _secondaryTextColor),
                          ),
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
                              activeColor: const Color(0xFF2563EB),
                              checkColor: Colors.white,
                              title: Text(
                                employee.name,
                                style: TextStyle(color: _primaryTextColor),
                              ),
                              subtitle: Text(
                                employee.position.isEmpty
                                    ? employee.department
                                    : '${employee.position} • ${employee.department}',
                                style: TextStyle(color: _secondaryTextColor),
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
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.surfaceColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      tileColor: surfaceColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(label, style: TextStyle(color: primaryTextColor)),
      subtitle: Text(value, style: TextStyle(color: secondaryTextColor)),
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
