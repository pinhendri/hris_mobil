import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/department_model.dart';
import '../../providers/department_provider.dart';
import '../../providers/employee_provider.dart';

class AddEditDepartmentScreen extends StatefulWidget {
  final Department? department;

  const AddEditDepartmentScreen({super.key, this.department});

  @override
  State<AddEditDepartmentScreen> createState() =>
      _AddEditDepartmentScreenState();
}

class _AddEditDepartmentScreenState extends State<AddEditDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;

  String? _selectedHeadId;
  String? _selectedLocation;
  String? _selectedType;
  String? _selectedManagerRole;
  String? _selectedParentId;
  String? _status;

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.department?.name ?? '',
    );
    _codeController = TextEditingController(
      text: widget.department?.code ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.department?.description ?? '',
    );

    _selectedHeadId = widget.department?.headId;
    _selectedLocation = widget.department?.location;
    _selectedType = widget.department?.type ?? 'Functional';
    _selectedManagerRole = widget.department?.managerRole;
_selectedParentId = widget.department?.parentId?.toString();
    _status = widget.department?.status ?? 'Active';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      Provider.of<EmployeeProvider>(context, listen: false).fetchEmployees();
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveDepartment() async {
  if (!_formKey.currentState!.validate()) return;

  final provider = Provider.of<DepartmentProvider>(context, listen: false);
  
  // Prepare data for API - this matches what your backend expects
  final Map<String, dynamic> departmentData = {
    'name': _nameController.text,
    'code': _codeController.text,
    'description': _descriptionController.text,
    'employee_id': _selectedHeadId, // Backend uses employee_id
    'location': _selectedLocation,
    'type': _selectedType ?? 'Functional',
    'manager_role': _selectedManagerRole,
    'status': _status ?? 'Active',
  };
  
  // Add parent_id only if it's not null
  if (_selectedParentId != null && _selectedParentId!.isNotEmpty) {
    departmentData['parent_id'] = int.tryParse(_selectedParentId!);
  }

  try {
    bool success;
    if (widget.department == null) {
      // Create new department
      success = await provider.addDepartment(departmentData);
    } else {
      // Update existing department
      success = await provider.updateDepartment(widget.department!.id, departmentData);
    }
    
    if (success && mounted) {
      Navigator.pop(context, true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.department == null
                ? 'Department created successfully'
                : 'Department updated successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (!success && mounted) {
      // Show error from provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'Operation failed',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final departmentProvider = Provider.of<DepartmentProvider>(context);
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    // Filter potential parents (cannot be itself)
    final potentialParents = departmentProvider.departments.where((d) {
      return d.id != widget.department?.id;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.department == null ? 'Add Department' : 'Edit Department',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: departmentProvider.isLoading ? null : _saveDepartment,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: departmentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('General Info'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Department Name',
                      hint: 'e.g. Information Technology',
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _codeController,
                      label: 'Department Code',
                      hint: 'e.g. IT-001',
                      readOnly:
                          widget.department != null, // Read-only in edit mode
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a code' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Brief description of the department',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Structure & Leadership'),
                    const SizedBox(height: 16),

                    _buildDropdown<String>(
                      label: 'Department Head',
                      value: _selectedHeadId,
                      items: employeeProvider.employees.map((e) {
                        return DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedHeadId = value),
                      hint: 'Select Manager',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<String>(
                      label: 'Manager Role',
                      value: _selectedManagerRole,
                      items: departmentProvider.availableRoles.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedManagerRole = value),
                      hint: 'Select Role',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<String>(
                      label: 'Parent Department',
                      value: _selectedParentId,
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'None (Top Level)',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ),
                        ...potentialParents.map((d) {
                          return DropdownMenuItem(
                            value: d.id.toString(),
                            child: Text(d.name, style: GoogleFonts.poppins()),
                          );
                        }),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedParentId = value),
                      hint: 'Select Parent Department',
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Classification'),
                    const SizedBox(height: 16),

                    _buildDropdown<String>(
                      label: 'Type',
                      value: _selectedType,
                      items: departmentProvider.availableTypes.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedType = value),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<String>(
                      label: 'Location',
                      value: _selectedLocation,
                      items: departmentProvider.availableLocations.map((l) {
                        return DropdownMenuItem(
                          value: l,
                          child: Text(l, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedLocation = value),
                      hint: 'Select Location',
                    ),
                    const SizedBox(height: 16),
                    if (widget.department != null) ...[
                      _buildDropdown<String>(
                        label: 'Status',
                        value: _status,
                        items: ['Active', 'Inactive'].map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(s, style: GoogleFonts.poppins()),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _status = value),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          validator: validator,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            filled: readOnly,
            fillColor: readOnly ? Colors.grey[100] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? hint,
  }) {
    // Ensure value exists in items to prevent "There should be exactly one item" error
    // This happens when the selected value is not in the list (e.g. data loading or ID mismatch)
    final bool valueExists =
        value == null || items.any((item) => item.value == value);
    final T? safeValue = valueExists ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          key: ValueKey('${label}_$safeValue'),
          initialValue: safeValue,
          items: items,
          onChanged: onChanged,
          style: GoogleFonts.poppins(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }
}
