// lib/screens/admin/master_shift_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shift_provider.dart';
import '../../models/shift_model.dart';
import '../../models/shift_day_model.dart';

class MasterShiftScreen extends StatefulWidget {
  const MasterShiftScreen({Key? key}) : super(key: key);

  @override
  State<MasterShiftScreen> createState() => _MasterShiftScreenState();
}

class _MasterShiftScreenState extends State<MasterShiftScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Shift> _filteredShifts = [];

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _screenBackgroundColor =>
      _isDarkMode ? const Color(0xFF020817) : const Color(0xFFF8FAFC);

  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF111827) : Colors.white;

  Color get _surfaceBorderColor =>
      _isDarkMode ? const Color(0xFF253041) : const Color(0xFFE2E8F0);

  Color get _primaryTextColor =>
      _isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

  InputDecoration _dialogInputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: _secondaryTextColor),
      hintStyle: TextStyle(color: _secondaryTextColor),
      filled: true,
      fillColor: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _surfaceBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _surfaceBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShiftProvider>().fetchShifts();
    });
  }

  void _filterShifts(String query, List<Shift> allShifts) {
    if (query.isEmpty) {
      setState(() {
        _filteredShifts = allShifts;
      });
    } else {
      setState(() {
        _filteredShifts = allShifts
            .where(
              (shift) =>
                  shift.name.toLowerCase().contains(query.toLowerCase()) ||
                  (shift.description?.toLowerCase() ?? '').contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      });
    }
  }

  String _getDaysDisplay(Shift shift) {
    if (shift.shiftDays.isEmpty) {
      return 'No days set';
    }

    // Sort days by day number
    final sortedDays = List<ShiftDay>.from(shift.shiftDays)
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

    return sortedDays
        .map((day) {
          switch (day.dayOfWeek) {
            case 1:
              return 'Mon';
            case 2:
              return 'Tue';
            case 3:
              return 'Wed';
            case 4:
              return 'Thu';
            case 5:
              return 'Fri';
            case 6:
              return 'Sat';
            case 7:
              return 'Sun';
            default:
              return '';
          }
        })
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackgroundColor,
      appBar: AppBar(
        title: Text('Shift Master', style: TextStyle(color: _primaryTextColor)),
        backgroundColor: _surfaceColor,
        surfaceTintColor: _surfaceColor,
        foregroundColor: _primaryTextColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ShiftProvider>().fetchShifts();
            },
          ),
        ],
      ),
      body: Consumer<ShiftProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.shifts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchShifts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final shifts = provider.shifts;
          final displayShifts = _searchController.text.isEmpty
              ? shifts
              : _filteredShifts;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: _primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'Search shifts...',
                    hintStyle: TextStyle(color: _secondaryTextColor),
                    prefixIcon: Icon(Icons.search, color: _secondaryTextColor),
                    filled: true,
                    fillColor: _isDarkMode
                        ? const Color(0xFF0F172A)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _surfaceBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _surfaceBorderColor),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterShifts('', shifts);
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => _filterShifts(value, shifts),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: displayShifts.length,
                  itemBuilder: (context, index) {
                    final shift = displayShifts[index];
                    return Card(
                      color: _surfaceColor,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _surfaceBorderColor),
                      ),
                      child: ListTile(
                        title: Text(
                          shift.name,
                          style: TextStyle(color: _primaryTextColor),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (shift.description?.isNotEmpty ?? false)
                              Text(
                                shift.description!,
                                style: TextStyle(color: _secondaryTextColor),
                              ),
                            Text(
                              'Break: ${shift.breakMinutes} min',
                              style: TextStyle(color: _secondaryTextColor),
                            ),
                            Text(
                              'Days: ${_getDaysDisplay(shift)}',
                              style: TextStyle(color: _secondaryTextColor),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showShiftDialog(
                                context: context,
                                shift: shift,
                                provider: provider,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(
                                context: context,
                                shift: shift,
                                provider: provider,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showShiftDialog(
          context: context,
          provider: context.read<ShiftProvider>(),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showShiftDialog({
    required BuildContext context,
    Shift? shift,
    required ShiftProvider provider,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: shift?.name ?? '');
    final descController = TextEditingController(
      text: shift?.description ?? '',
    );
    final graceInController = TextEditingController(
      text: shift?.graceClockIn.toString() ?? '0',
    );
    final graceOutController = TextEditingController(
      text: shift?.graceClockOut.toString() ?? '0',
    );
    final breakController = TextEditingController(
      text: shift?.breakMinutes.toString() ?? '60',
    );

    bool isNightShift = shift?.isNightShift ?? false;
    bool isFlexible = shift?.isFlexible ?? false;
    bool isActive = shift?.isActive ?? true;

    // Untuk shift days
    List<ShiftDay> shiftDays = shift?.shiftDays ?? [];

    // Map untuk konversi day number ke nama
    final dayNames = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stateContext, setState) {
            return AlertDialog(
              backgroundColor: _surfaceColor,
              title: Text(
                shift == null ? 'Add Shift' : 'Edit Shift',
                style: TextStyle(color: _primaryTextColor),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(color: _primaryTextColor),
                        decoration: _dialogInputDecoration('Shift Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter shift name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        style: TextStyle(color: _primaryTextColor),
                        decoration: _dialogInputDecoration('Description'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: graceInController,
                              style: TextStyle(color: _primaryTextColor),
                              decoration: _dialogInputDecoration(
                                'Grace Clock In (min)',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: graceOutController,
                              style: TextStyle(color: _primaryTextColor),
                              decoration: _dialogInputDecoration(
                                'Grace Clock Out (min)',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: breakController,
                        style: TextStyle(color: _primaryTextColor),
                        decoration: _dialogInputDecoration('Break Minutes'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: Text(
                                'Night Shift',
                                style: TextStyle(color: _primaryTextColor),
                              ),
                              value: isNightShift,
                              onChanged: (val) {
                                setState(() => isNightShift = val ?? false);
                              },
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: Text(
                                'Flexible',
                                style: TextStyle(color: _primaryTextColor),
                              ),
                              value: isFlexible,
                              onChanged: (val) {
                                setState(() => isFlexible = val ?? false);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: Text(
                          'Active',
                          style: TextStyle(color: _primaryTextColor),
                        ),
                        value: isActive,
                        onChanged: (val) {
                          setState(() => isActive = val ?? true);
                        },
                      ),
                      const Divider(height: 24),
                      Text(
                        'Shift Days',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tampilkan shift days yang sudah ada
                      ...shiftDays.map((day) {
                        return ListTile(
                          title: Text(
                            dayNames[day.dayOfWeek] ?? 'Unknown',
                            style: TextStyle(color: _primaryTextColor),
                          ),
                          subtitle: Text(
                            '${day.clockIn.substring(0, 5)} - ${day.clockOut.substring(0, 5)}',
                            style: TextStyle(color: _secondaryTextColor),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                shiftDays.remove(day);
                              });
                            },
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final newDay = await _showAddShiftDayDialog(
                            context,
                            shiftDays,
                          );
                          if (newDay != null) {
                            setState(() {
                              shiftDays.add(newDay);
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Shift Day'),
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
                      Navigator.pop(dialogContext);

                      // Buat shift baru atau update shift yang ada
                      final newShift = Shift(
                        id: shift?.id ?? '',
                        name: nameController.text,
                        description: descController.text.isNotEmpty
                            ? descController.text
                            : null,
                        startTime: '', // Tidak digunakan di master shift
                        endTime: '', // Tidak digunakan di master shift
                        breakMinutes: int.parse(breakController.text),
                        graceClockIn: int.parse(graceInController.text),
                        graceClockOut: int.parse(graceOutController.text),
                        isNightShift: isNightShift,
                        isFlexible: isFlexible,
                        isActive: isActive,
                        shiftDays: shiftDays,
                      );

                      bool success;
                      if (shift == null) {
                        // Add shift - ini akan memanggil provider.addShift
                        // yang kemudian akan memanggil API /shifts
                        success = await provider.addShift(newShift);
                      } else {
                        // Update shift - ini akan memanggil provider.updateShift
                        success = await provider.updateShift(newShift);
                      }

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              shift == null
                                  ? 'Shift added successfully'
                                  : 'Shift updated successfully',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.error ?? 'Failed to save shift',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(shift == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<ShiftDay?> _showAddShiftDayDialog(
    BuildContext context,
    List<ShiftDay> existingDays,
  ) async {
    final formKey = GlobalKey<FormState>();
    int? selectedDay;
    final clockInController = TextEditingController();
    final clockOutController = TextEditingController();
    final breakController = TextEditingController(text: '60');

    // Map day number to string for API
    final dayToString = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    final result = await showDialog<ShiftDay?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          title: Text(
            'Add Shift Day',
            style: TextStyle(color: _primaryTextColor),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  dropdownColor: _surfaceColor,
                  style: TextStyle(color: _primaryTextColor),
                  decoration: _dialogInputDecoration('Day of Week'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Monday')),
                    DropdownMenuItem(value: 2, child: Text('Tuesday')),
                    DropdownMenuItem(value: 3, child: Text('Wednesday')),
                    DropdownMenuItem(value: 4, child: Text('Thursday')),
                    DropdownMenuItem(value: 5, child: Text('Friday')),
                    DropdownMenuItem(value: 6, child: Text('Saturday')),
                    DropdownMenuItem(value: 7, child: Text('Sunday')),
                  ],
                  onChanged: (value) => selectedDay = value,
                  validator: (value) {
                    if (value == null) return 'Please select day';

                    // Check if day already exists
                    if (existingDays.any((d) => d.dayOfWeek == value)) {
                      return 'Day already exists';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: clockInController,
                  style: TextStyle(color: _primaryTextColor),
                  decoration: _dialogInputDecoration(
                    'Clock In (HH:mm)',
                    hint: '08:00',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter clock in time';
                    }
                    if (!RegExp(
                      r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$',
                    ).hasMatch(value)) {
                      return 'Invalid time format (HH:mm)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: clockOutController,
                  style: TextStyle(color: _primaryTextColor),
                  decoration: _dialogInputDecoration(
                    'Clock Out (HH:mm)',
                    hint: '17:00',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter clock out time';
                    }
                    if (!RegExp(
                      r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$',
                    ).hasMatch(value)) {
                      return 'Invalid time format (HH:mm)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: breakController,
                  style: TextStyle(color: _primaryTextColor),
                  decoration: _dialogInputDecoration('Break Minutes'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter break minutes';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final shiftDay = ShiftDay(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    shiftId: '', // Will be set when saving to API
                    dayOfWeek: selectedDay!,
                    dayOfWeekString: dayToString[selectedDay!] ?? '',
                    clockIn: clockInController.text,
                    clockOut: clockOutController.text,
                    breakMinutes: int.parse(breakController.text),
                  );
                  Navigator.pop(dialogContext, shiftDay);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<void> _confirmDelete({
    required BuildContext context,
    required Shift shift,
    required ShiftProvider provider,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Shift'),
          content: Text('Are you sure you want to delete "${shift.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final success = await provider.deleteShift(shift.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shift deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to delete shift'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
