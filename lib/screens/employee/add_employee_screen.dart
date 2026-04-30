import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/access_denied_state.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/employee_model.dart';
import '../../models/recruitment_model.dart' show Position;
import '../../models/shift_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/shift_provider.dart';
import '../../services/api_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  final Employee? employee;
  const AddEmployeeScreen({super.key, this.employee});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers for Tab 1: Personal Information
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  // Controllers for Tab 2: Job Information
  final TextEditingController _employeeIdPreviewController =
      TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  // Controllers for Tab 3: Education & Qualifications
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _certificationsController =
      TextEditingController();

  // Controllers for Tab 4: Work Experience
  final TextEditingController _previousEmployersController =
      TextEditingController();
  final TextEditingController _experienceYearsController =
      TextEditingController();

  // Controllers for Tab 6: Health & Safety
  final TextEditingController _medicalConditionsController =
      TextEditingController();
  final TextEditingController _emergencyMedicalInfoController =
      TextEditingController();

  // Controllers for Tab 7: Legal & Compliance
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _ssnController = TextEditingController();

  // Controllers for Tab 8: Onboarding Information
  final TextEditingController _trainingPlanController = TextEditingController();

  // Variables for Dropdowns and DatePickers
  String? _selectedGender;
  DateTime? _dob;
  String? _selectedNationality;
  String? _selectedMaritalStatus;
  String? _selectedEmergencyRelationship;

  String? _selectedDepartment;
  String? _selectedManager;
  DateTime? _joinDate;
  String? _selectedPositionId;
  String? _selectedEmploymentType;
  String? _selectedLocation;
  String? _selectedShift;
  String? _selectedWorkSchedule;
  String? _selectedAccountType;

  String? _selectedEducationLevel;
  DateTime? _graduationYear;

  final List<String> _selectedSkills = [];

  String? _selectedBloodType;
  bool _hasMedicalCondition = false;

  String? _selectedWorkAuth;
  String? _selectedContractType;
  bool _policyAcknowledged = false;

  final List<String> _assignedEquipment = [];
  final List<String> _systemAccess = [];
  bool _handbookAcknowledged = false;
  bool _isSubmitting = false;
  List<Position> _positionOptions = const [];

  PlatformFile? _resumeFile;
  PlatformFile? _idFile;
  PlatformFile? _certificateFile;
  PlatformFile? _otherFile;

  // Error messages
  String? _dobError;
  String? _joinDateError;

  // Employee ID auto-generate states
  String _employeePrefix = 'EMP';
  String? _generatedEmployeeId;

  // Mock Data for Dropdowns
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _countries = [
    'USA',
    'UK',
    'Canada',
    'Australia',
    'India',
    'Indonesia',
    'Singapore',
  ];
  final List<String> _maritalStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];
  final List<String> _relationships = ['Family', 'Friend', 'Spouse', 'Other'];
  final List<String> _employmentTypes = [
    'Full-Time',
    'Part-Time',
    'Contract',
    'Temporary',
    'Internship',
  ];
  final List<String> _locations = [
    'HQ - New York',
    'Branch - London',
    'Remote',
  ];
  final List<String> _schedules = ['9 AM - 5 PM', 'Flexible Hours'];
  final List<String> _accountTypes = ['Checking', 'Savings'];
  final List<String> _educationLevels = [
    'High School',
    'Associate',
    "Bachelor's",
    "Master's",
    'Ph.D.',
  ];
  final List<String> _skillOptions = [
    'Java',
    'Flutter',
    'Python',
    'React',
    'Project Management',
  ];
  final List<String> _bloodTypes = ['A', 'B', 'AB', 'O'];
  final List<String> _workAuths = [
    'Citizen',
    'Permanent Resident',
    'Work Visa',
    'Other',
  ];
  final List<String> _contractTypes = ['Signed', 'Pending'];
  final List<String> _equipmentOptions = [
    'Laptop',
    'Phone',
    'ID Badge',
    'Monitor',
  ];
  final List<String> _systemOptions = [
    'Email',
    'HRIS',
    'Intranet',
    'Payroll System',
  ];

  String get _employeeIdPreview =>
      _generatedEmployeeId ?? '${_employeePrefix}XXXXX';

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _pageColor =>
      _isDarkMode ? const Color(0xFF020817) : const Color(0xFFF8FAFC);

  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF111827) : Colors.white;

  Color get _fieldColor =>
      _isDarkMode ? const Color(0xFF0F172A) : AppColors.inputBackground;

  Color get _borderColor =>
      _isDarkMode ? const Color(0xFF334155) : AppColors.inputBorder;

  Color get _primaryTextColor =>
      _isDarkMode ? const Color(0xFFF8FAFC) : AppColors.textPrimary;

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFFCBD5E1) : AppColors.textSecondary;

  InputDecoration _employeeInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _secondaryTextColor),
      labelStyle: TextStyle(color: _secondaryTextColor),
      hintStyle: TextStyle(color: _secondaryTextColor),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: _fieldColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);

    final e = widget.employee;
    if (e != null) {
      _nameController.text = e.name;
      _nikController.text = e.nik ?? '';
      _selectedGender = e.gender;
      _dob = _tryParseDate(e.dateOfBirth);
      _selectedNationality = e.nationality;
      _addressController.text = e.address ?? '';
      _selectedMaritalStatus = e.maritalStatus;
      _emergencyNameController.text = e.emergencyContactName ?? '';
      _selectedEmergencyRelationship = e.emergencyContactRelationship;
      _emergencyPhoneController.text = e.emergencyContactPhone ?? '';
      _generatedEmployeeId = e.nikEmployee ?? e.id;
      _employeeIdPreviewController.text = _employeeIdPreview;
      _positionController.text = e.positionName ?? e.position;
      _selectedPositionId = e.positionId;
      _selectedDepartment = e.departmentId ?? e.department;
      _selectedManager = e.managerId;
      _joinDate = _tryParseDate(e.joinDate);
      _selectedEmploymentType = e.employmentType;
      _salaryController.text = e.salary.toString();
      _selectedLocation = e.officeLocation;
      _selectedShift = e.shiftId ?? e.shiftType;
      _selectedWorkSchedule = e.workSchedule;
      _bankAccountController.text = e.bankAccountNumber ?? '';
      _bankNameController.text = e.bankName ?? '';
      _selectedAccountType = e.accountType;
      _selectedEducationLevel = e.highestEducation;
      _degreeController.text = e.degree ?? '';
      _institutionController.text = e.institution ?? '';
      _graduationYear = _tryParseDate(e.graduationYear);
      _previousEmployersController.text = e.previousEmployers ?? '';
      _experienceYearsController.text = e.yearsOfExperience?.toString() ?? '';
      _selectedSkills.clear();
      if (e.skills != null) _selectedSkills.addAll(e.skills!);
      _certificationsController.text = e.certifications ?? '';
      _hasMedicalCondition = (e.medicalConditions ?? '').isNotEmpty;
      _medicalConditionsController.text = e.medicalConditions ?? '';
      _selectedBloodType = e.bloodType;
      _emergencyMedicalInfoController.text = e.emergencyMedicalInfo ?? '';
      _tinController.text = e.tin ?? '';
      _ssnController.text = e.ssn ?? '';
      _selectedWorkAuth = e.workAuthorization;
      _selectedContractType = e.contractType;
      _policyAcknowledged = e.companyPoliciesAcknowledged ?? false;
      _assignedEquipment.clear();
      if (e.assignedEquipment != null) {
        _assignedEquipment.addAll(e.assignedEquipment!);
      }
      _trainingPlanController.text = e.trainingPlan ?? '';
      _systemAccess.clear();
      if (e.systemAccess != null) _systemAccess.addAll(e.systemAccess!);
      _handbookAcknowledged = e.handbookAcknowledged ?? false;
    } else {
      _employeeIdPreviewController.text = _employeeIdPreview;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeMasterData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _nikController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _employeeIdPreviewController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    _degreeController.dispose();
    _institutionController.dispose();
    _certificationsController.dispose();
    _previousEmployersController.dispose();
    _experienceYearsController.dispose();
    _medicalConditionsController.dispose();
    _emergencyMedicalInfoController.dispose();
    _tinController.dispose();
    _ssnController.dispose();
    _trainingPlanController.dispose();
    super.dispose();
  }

  Future<void> _initializeMasterData() async {
    final authProvider = context.read<AuthProvider>();
    final departmentProvider = context.read<DepartmentProvider>();
    final employeeProvider = context.read<EmployeeProvider>();
    final shiftProvider = context.read<ShiftProvider>();

    final companyCode = authProvider.getCompanyCode();
    if (companyCode.isNotEmpty) {
      departmentProvider.setCurrentCcode(companyCode);
    }

    await Future.wait([
      departmentProvider.fetchDepartments(),
      employeeProvider.fetchAllEmployees(),
      shiftProvider.fetchShifts(),
      _loadPositions(),
      _loadEmployeePrefix(companyCode),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _employeeIdPreviewController.text = _employeeIdPreview;
    });
    _syncMasterSelections();
  }

  Future<void> _loadEmployeePrefix(String companyCode) async {
    try {
      if (companyCode.isEmpty) {
        _employeePrefix = 'EMP';
        return;
      }

      final response = await _apiService.get(
        '/payroll/settings?c_code=$companyCode',
      );

      final dynamic raw = response;
      final dynamic data = raw is Map<String, dynamic>
          ? (raw['data'] ?? raw)
          : raw;

      final dynamic prefixValue = data is Map<String, dynamic>
          ? data['emp_type']
          : null;

      final prefix = (prefixValue ?? '').toString().trim().toUpperCase();

      _employeePrefix = prefix.isEmpty ? 'EMP' : prefix;
    } catch (_) {
      _employeePrefix = 'EMP';
    }
  }

  Future<void> _loadPositions() async {
    try {
      final response = await _apiService.get('/employees/master/position');
      final rawData = response is Map<String, dynamic>
          ? response['data']
          : null;
      if (rawData is! List) {
        return;
      }

      _positionOptions = rawData
          .whereType<Map<String, dynamic>>()
          .map(Position.fromJson)
          .toList(growable: false);
    } catch (_) {
      _positionOptions = const [];
    }
  }

  void _syncMasterSelections() {
    final currentEmployee = widget.employee;
    if (currentEmployee == null) {
      return;
    }

    final departmentProvider = context.read<DepartmentProvider>();
    final shiftProvider = context.read<ShiftProvider>();

    final hasSelectedDepartment =
        _selectedDepartment != null &&
        departmentProvider.departments.any(
          (department) => department.id.toString() == _selectedDepartment,
        );

    if (!hasSelectedDepartment && currentEmployee.department.isNotEmpty) {
      for (final department in departmentProvider.departments) {
        if (department.name.toLowerCase() ==
            currentEmployee.department.toLowerCase()) {
          _selectedDepartment = department.id.toString();
          break;
        }
      }
    }

    if ((_selectedPositionId == null || _selectedPositionId!.isEmpty) &&
        currentEmployee.position.isNotEmpty) {
      for (final position in _positionOptions) {
        if (position.namaJabatan.toLowerCase() ==
            currentEmployee.position.toLowerCase()) {
          _selectedPositionId = position.id.toString();
          _positionController.text = position.namaJabatan;
          break;
        }
      }
    }

    if ((_selectedManager == null || _selectedManager!.isEmpty) &&
        (currentEmployee.managerId?.isNotEmpty ?? false)) {
      _selectedManager = currentEmployee.managerId;
    }

    final hasSelectedShift =
        _selectedShift != null &&
        shiftProvider.shifts.any((shift) => shift.id == _selectedShift);

    if (!hasSelectedShift && (currentEmployee.shiftType?.isNotEmpty ?? false)) {
      final normalizedShift = currentEmployee.shiftType!.trim().toLowerCase();
      for (final shift in shiftProvider.shifts) {
        final shiftName = shift.name.trim().toLowerCase();
        final shiftDescription = (shift.description ?? '').trim().toLowerCase();
        final shiftLabel = _buildShiftOptionLabel(shift).trim().toLowerCase();

        if (shiftName == normalizedShift ||
            shiftDescription == normalizedShift ||
            shiftLabel == normalizedShift) {
          _selectedShift = shift.id;
          break;
        }
      }
    }

    setState(() {});
  }

  Future<void> _selectDate(BuildContext context, {required bool isDob}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: _surfaceColor,
              onSurface: _primaryTextColor,
            ),
            dialogTheme: DialogThemeData(backgroundColor: _surfaceColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDob) {
          _dob = picked;
          _dobError = null;
        } else {
          _joinDate = picked;
          _joinDateError = null;
        }
      });
    }
  }

  Future<void> _selectYear(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          title: Text(
            "Select Year",
            style: TextStyle(color: _primaryTextColor),
          ),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              selectedDate: _graduationYear ?? DateTime.now(),
              onChanged: (DateTime dateTime) {
                setState(() {
                  _graduationYear = dateTime;
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final requiredPermission = widget.employee == null
        ? 'create-employee'
        : 'edit-employee';

    if (!authProvider.hasPermission(requiredPermission)) {
      return Scaffold(
        backgroundColor: _pageColor,
        appBar: AppBar(
          title: Text(
            widget.employee == null ? 'Add New Employee' : 'Edit Employee',
            style: TextStyle(
              color: _primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _surfaceColor,
          surfaceTintColor: _surfaceColor,
          foregroundColor: _primaryTextColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: _primaryTextColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: AccessDeniedState(permissionLabel: requiredPermission),
      );
    }

    return Scaffold(
      backgroundColor: _pageColor,
      appBar: AppBar(
        title: Text(
          widget.employee == null ? 'Add New Employee' : 'Edit Employee',
          style: TextStyle(
            color: _primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _surfaceColor,
        surfaceTintColor: _surfaceColor,
        foregroundColor: _primaryTextColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: _secondaryTextColor,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '1. Personal'),
            Tab(text: '2. Job'),
            Tab(text: '3. Education'),
            Tab(text: '4. Experience'),
            Tab(text: '5. Documents'),
            Tab(text: '6. Health'),
            Tab(text: '7. Legal'),
            Tab(text: '8. Onboarding'),
            Tab(text: '9. Review'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPersonalTab(),
            _buildJobTab(),
            _buildEducationTab(),
            _buildExperienceTab(),
            _buildDocumentsTab(),
            _buildHealthTab(),
            _buildLegalTab(),
            _buildOnboardingTab(),
            _buildReviewTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Personal Information (Mandatory)'),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Full Name',
            controller: _nameController,
            icon: Icons.person_outline,
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'NIK / KTP',
            controller: _nikController,
            icon: Icons.badge_outlined,
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Gender',
            value: _selectedGender,
            items: _genders,
            icon: Icons.people_outline,
            onChanged: (val) => setState(() => _selectedGender = val),
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildDatePicker(
            label: 'Date of Birth',
            selectedDate: _dob,
            errorText: _dobError,
            onTap: () => _selectDate(context, isDob: true),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Nationality',
            value: _selectedNationality,
            items: _countries,
            icon: Icons.flag_outlined,
            onChanged: (val) => setState(() => _selectedNationality = val),
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Address',
            controller: _addressController,
            icon: Icons.home_outlined,
            maxLines: 3,
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Phone Number',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email Address',
            controller: _emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (!value.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Marital Status',
            value: _selectedMaritalStatus,
            items: _maritalStatuses,
            icon: Icons.family_restroom,
            onChanged: (val) => setState(() => _selectedMaritalStatus = val),
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Emergency Contact'),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Emergency Contact Name',
            controller: _emergencyNameController,
            icon: Icons.person,
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Relationship',
            value: _selectedEmergencyRelationship,
            items: _relationships,
            icon: Icons.favorite_outline,
            onChanged: (val) =>
                setState(() => _selectedEmergencyRelationship = val),
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Emergency Contact Phone',
            controller: _emergencyPhoneController,
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 32),
          _buildNextButton(1),
        ],
      ),
    );
  }

  Widget _buildJobTab() {
    final departmentOptions = context
        .watch<DepartmentProvider>()
        .departments
        .map(
          (department) => _OptionItem(
            value: department.id.toString(),
            label: department.name,
          ),
        )
        .toList(growable: false);

    final managerOptions = context
        .watch<EmployeeProvider>()
        .employees
        .where((employee) => employee.uuid != widget.employee?.uuid)
        .map(
          (employee) => _OptionItem(value: employee.uuid, label: employee.name),
        )
        .toList(growable: false);

    final positionOptions = _positionOptions
        .map(
          (position) => _OptionItem(
            value: position.id.toString(),
            label: position.namaJabatan,
          ),
        )
        .toList(growable: false);

    final shiftOptions = context
        .watch<ShiftProvider>()
        .shifts
        .map(
          (shift) => _OptionItem(
            value: shift.id,
            label: _buildShiftOptionLabel(shift),
          ),
        )
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Job Information (Mandatory)'),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Employee ID',
            controller: _employeeIdPreviewController,
            icon: Icons.badge_outlined,
            readOnly: true,
            enabled: false,
            hint:
                'Auto generated from prefix ${_employeePrefix.isEmpty ? "EMP" : _employeePrefix}',
          ),
          const SizedBox(height: 8),
          Text(
            _generatedEmployeeId != null
                ? 'Employee ID final dibuat oleh sistem.'
                : 'Preview saja. Employee ID final akan dibuat otomatis saat data disimpan.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionDropdown(
            label: 'Job Title',
            value: _selectedPositionId,
            items: positionOptions,
            icon: Icons.work_outline,
            onChanged: (value) {
              setState(() {
                _selectedPositionId = value;
                String selectedLabel = '';
                for (final item in positionOptions) {
                  if (item.value == value) {
                    selectedLabel = item.label;
                    break;
                  }
                }
                _positionController.text = selectedLabel;
              });
            },
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildOptionDropdown(
            label: 'Department',
            value: _selectedDepartment,
            items: departmentOptions,
            icon: Icons.business_outlined,
            onChanged: (val) => setState(() => _selectedDepartment = val),
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildOptionDropdown(
            label: 'Manager/Supervisor',
            value: _selectedManager,
            items: managerOptions,
            icon: Icons.supervisor_account_outlined,
            onChanged: (val) => setState(() => _selectedManager = val),
          ),
          const SizedBox(height: 16),
          _buildDatePicker(
            label: 'Date of Joining',
            selectedDate: _joinDate,
            errorText: _joinDateError,
            onTap: () => _selectDate(context, isDob: false),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Employment Type',
            value: _selectedEmploymentType,
            items: _employmentTypes,
            icon: Icons.work_history_outlined,
            onChanged: (val) => setState(() => _selectedEmploymentType = val),
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Salary/Compensation',
            controller: _salaryController,
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Office Location',
            value: _selectedLocation,
            items: _locations,
            icon: Icons.location_on_outlined,
            onChanged: (val) => setState(() => _selectedLocation = val),
          ),
          const SizedBox(height: 16),
          _buildOptionDropdown(
            label: 'Shift Type',
            value: _selectedShift,
            items: shiftOptions,
            icon: Icons.schedule,
            onChanged: (val) => setState(() => _selectedShift = val),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Work Schedule',
            value: _selectedWorkSchedule,
            items: _schedules,
            icon: Icons.access_time,
            onChanged: (val) => setState(() => _selectedWorkSchedule = val),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Payroll Information'),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Bank Account Number',
            controller: _bankAccountController,
            icon: Icons.account_balance,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Bank Name',
            controller: _bankNameController,
            icon: Icons.account_balance_wallet,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Account Type',
            value: _selectedAccountType,
            items: _accountTypes,
            icon: Icons.credit_card,
            onChanged: (val) => setState(() => _selectedAccountType = val),
          ),
          const SizedBox(height: 32),
          _buildNextButton(2),
        ],
      ),
    );
  }

  Widget _buildEducationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Education & Qualifications (Optional)'),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Highest Level of Education',
            value: _selectedEducationLevel,
            items: _educationLevels,
            icon: Icons.school_outlined,
            onChanged: (val) => setState(() => _selectedEducationLevel = val),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Degree/Certification Obtained',
            controller: _degreeController,
            icon: Icons.book_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Institution Name',
            controller: _institutionController,
            icon: Icons.apartment_outlined,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectYear(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _graduationYear == null
                        ? 'Year of Graduation'
                        : _graduationYear!.year.toString(),
                    style: TextStyle(
                      color: _graduationYear == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildNextButton(3),
        ],
      ),
    );
  }

  Widget _buildExperienceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Work Experience (Optional)'),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Previous Employers',
            controller: _previousEmployersController,
            icon: Icons.business,
            maxLines: 4,
            hint: 'List previous employers and job titles...',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Years of Experience',
            controller: _experienceYearsController,
            icon: Icons.timer_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const Text(
            'Skills',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _skillOptions.map((skill) {
              final isSelected = _selectedSkills.contains(skill);
              return FilterChip(
                label: Text(skill),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSkills.add(skill);
                    } else {
                      _selectedSkills.remove(skill);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Certifications',
            controller: _certificationsController,
            icon: Icons.card_membership,
            maxLines: 2,
          ),
          const SizedBox(height: 32),
          _buildNextButton(4),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Documents Upload (Optional)'),
          const SizedBox(height: 16),
          _buildFileUpload(
            'Resume/CV',
            _resumeFile,
            (file) => setState(() => _resumeFile = file),
          ),
          const SizedBox(height: 16),
          _buildFileUpload(
            'Identification Proof',
            _idFile,
            (file) => setState(() => _idFile = file),
          ),
          const SizedBox(height: 16),
          _buildFileUpload(
            'Educational Certificates',
            _certificateFile,
            (file) => setState(() => _certificateFile = file),
          ),
          const SizedBox(height: 16),
          _buildFileUpload(
            'Other Documents',
            _otherFile,
            (file) => setState(() => _otherFile = file),
          ),
          const SizedBox(height: 32),
          _buildNextButton(5),
        ],
      ),
    );
  }

  Widget _buildFileUpload(
    String label,
    PlatformFile? file,
    Function(PlatformFile?) onFileSelected,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.inputBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
                  );
                  if (result != null) {
                    onFileSelected(result.files.first);
                  }
                },
                child: const Text('Upload'),
              ),
            ],
          ),
          if (file != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.name,
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  onPressed: () => onFileSelected(null),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Health & Safety (Optional)'),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'Do you have any medical conditions or allergies?',
            ),
            value: _hasMedicalCondition,
            onChanged: (val) {
              setState(() {
                _hasMedicalCondition = val;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          if (_hasMedicalCondition) ...[
            const SizedBox(height: 8),
            _buildTextField(
              label: 'Please specify',
              controller: _medicalConditionsController,
              icon: Icons.medical_services_outlined,
              maxLines: 3,
            ),
          ],
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Blood Type',
            value: _selectedBloodType,
            items: _bloodTypes,
            icon: Icons.bloodtype_outlined,
            onChanged: (val) => setState(() => _selectedBloodType = val),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Emergency Medical Information',
            controller: _emergencyMedicalInfoController,
            icon: Icons.info_outline,
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          _buildNextButton(6),
        ],
      ),
    );
  }

  Widget _buildLegalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Legal & Compliance (Optional)'),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Tax Identification Number (TIN)',
            controller: _tinController,
            icon: Icons.numbers,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'SSN / National ID',
            controller: _ssnController,
            icon: Icons.badge,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Work Authorization Status',
            value: _selectedWorkAuth,
            items: _workAuths,
            icon: Icons.verified_user_outlined,
            onChanged: (val) => setState(() => _selectedWorkAuth = val),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Contract Type',
            value: _selectedContractType,
            items: _contractTypes,
            icon: Icons.description_outlined,
            onChanged: (val) => setState(() => _selectedContractType = val),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text(
              'I agree to abide by the company’s policies and code of conduct.',
            ),
            value: _policyAcknowledged,
            onChanged: (val) => setState(() => _policyAcknowledged = val!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 32),
          _buildNextButton(7),
        ],
      ),
    );
  }

  Widget _buildOnboardingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Onboarding Information (Optional)'),
          const SizedBox(height: 16),
          const Text(
            'Assigned Office Equipment',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          ..._equipmentOptions.map((eq) {
            return CheckboxListTile(
              title: Text(eq),
              value: _assignedEquipment.contains(eq),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _assignedEquipment.add(eq);
                  } else {
                    _assignedEquipment.remove(eq);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
          }),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Training and Development Plan',
            controller: _trainingPlanController,
            icon: Icons.school,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Access to Systems',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          ..._systemOptions.map((sys) {
            return CheckboxListTile(
              title: Text(sys),
              value: _systemAccess.contains(sys),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _systemAccess.add(sys);
                  } else {
                    _systemAccess.remove(sys);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
          }),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text(
              'I have read and understand the employee handbook.',
            ),
            value: _handbookAcknowledged,
            onChanged: (val) => setState(() => _handbookAcknowledged = val!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 32),
          _buildNextButton(8),
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Final Review and Submission'),
          const SizedBox(height: 16),
          const Text(
            'Please review all the information provided in the previous tabs. '
            'Ensure that all mandatory fields in "Personal" and "Job" tabs are filled correctly.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            'Employee ID Preview: $_employeeIdPreview',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submitForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.employee == null
                          ? 'Submit Employee Data'
                          : 'Update Employee Data',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    final bool isPersonalValid =
        _nameController.text.isNotEmpty &&
        _nikController.text.isNotEmpty &&
        _selectedGender != null &&
        _dob != null &&
        _selectedNationality != null &&
        _addressController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _selectedMaritalStatus != null &&
        _emergencyNameController.text.isNotEmpty &&
        _selectedEmergencyRelationship != null &&
        _emergencyPhoneController.text.isNotEmpty;

    final bool isJobValid =
        _selectedPositionId != null &&
        _selectedDepartment != null &&
        _joinDate != null &&
        _selectedEmploymentType != null &&
        _salaryController.text.isNotEmpty;

    if (!isPersonalValid) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all mandatory fields in Personal Info tab',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!isJobValid) {
      _tabController.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all mandatory fields in Job Info tab'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    final provider = context.read<EmployeeProvider>();
    final payload = _buildEmployeePayload();

    setState(() {
      _isSubmitting = true;
    });

    final bool success = widget.employee == null
        ? await provider.createEmployee(payload)
        : await provider.updateEmployee(
            widget.employee!,
            overrideData: payload,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      String? finalEmployeeId;

      try {
        final createdEmployee = provider.selectedEmployee;
        finalEmployeeId = createdEmployee?.nikEmployee;
      } catch (_) {
        finalEmployeeId = null;
      }

      if (finalEmployeeId != null && finalEmployeeId.isNotEmpty) {
        _generatedEmployeeId = finalEmployeeId;
        _employeeIdPreviewController.text = finalEmployeeId;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            widget.employee == null ? 'Employee Created' : 'Employee Updated',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.employee == null
                    ? 'Employee berhasil dibuat.'
                    : 'Employee berhasil diupdate.',
              ),
              const SizedBox(height: 8),
              Text('Employee ID: ${finalEmployeeId ?? _employeeIdPreview}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.error ?? 'Failed to save employee.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Map<String, dynamic> _buildEmployeePayload() {
    final companyCode = context.read<AuthProvider>().getCompanyCode();
    final salary = double.tryParse(_salaryController.text.trim());
    final int? positionId = int.tryParse(_selectedPositionId ?? '');
    final int? departmentId = int.tryParse(_selectedDepartment ?? '');
    final int? shiftId = int.tryParse(_selectedShift ?? '');

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'nik': _nikController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'position': positionId,
      'department': departmentId,
      'status': widget.employee?.status ?? 'Active',
      'join_date': _formatDate(_joinDate),
      'salary': salary,
      'basic_salary': salary,
      'immediate_supervisor': _selectedManager,
      'shift_id': shiftId,
      'shift': shiftId,
      'c_code': companyCode,
      'flag': _deriveFlag(),
      'gender': _selectedGender,
      'date_of_birth': _formatDate(_dob),
      'nationality': _selectedNationality,
      'address': _addressController.text.trim(),
      'marital_status': _selectedMaritalStatus,
      'emergency_contact_name': _emergencyNameController.text.trim(),
      'emergency_contact_relationship': _selectedEmergencyRelationship,
      'emergency_contact_phone': _emergencyPhoneController.text.trim(),
      'employment_type': _selectedEmploymentType,
      'office_location': _selectedLocation,
      'work_schedule': _selectedWorkSchedule,
      'bank_account_number': _bankAccountController.text.trim(),
      'bank_name': _bankNameController.text.trim(),
      'account_type': _selectedAccountType,
      'highest_education': _selectedEducationLevel,
      'degree': _degreeController.text.trim(),
      'institution': _institutionController.text.trim(),
      'graduation_year': _formatDate(_graduationYear),
      'previous_employers': _previousEmployersController.text.trim(),
      'years_of_experience': int.tryParse(
        _experienceYearsController.text.trim(),
      ),
      'skills': _selectedSkills.isEmpty ? null : _selectedSkills,
      'certifications': _certificationsController.text.trim(),
      'medical_conditions': _hasMedicalCondition
          ? _medicalConditionsController.text.trim()
          : null,
      'blood_type': _selectedBloodType,
      'emergency_medical_info': _emergencyMedicalInfoController.text.trim(),
      'tax_number': _tinController.text.trim(),
      'ssn': _ssnController.text.trim(),
      'work_authorization': _selectedWorkAuth,
      'contract_type': _selectedContractType,
      'company_policies_acknowledged': _policyAcknowledged,
      'assigned_equipment': _assignedEquipment.isEmpty
          ? null
          : _assignedEquipment,
      'training_plan': _trainingPlanController.text.trim(),
      'system_access': _systemAccess.isEmpty ? null : _systemAccess,
      'handbook_acknowledged': _handbookAcknowledged,
    };

    payload.removeWhere((key, value) {
      if (value == null) {
        return true;
      }

      if (value is String) {
        return value.trim().isEmpty;
      }

      return false;
    });

    return payload;
  }

  String _deriveFlag() {
    switch ((_selectedEmploymentType ?? '').toLowerCase()) {
      case 'contract':
      case 'temporary':
        return 'Kontrak';
      default:
        return 'Permanen';
    }
  }

  String? _formatDate(DateTime? value) {
    if (value == null) {
      return null;
    }

    return DateFormat('yyyy-MM-dd').format(value);
  }

  String _buildShiftOptionLabel(Shift shift) {
    final description = (shift.description ?? '').trim();
    final hasDescription = description.isNotEmpty && description != shift.name;
    return hasDescription ? '${shift.name} - $description' : shift.name;
  }

  Widget _buildNextButton(int nextTabIndex) {
    final bool showSave = nextTabIndex >= 2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showSave) ...[
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : () => _submitForm(),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _isSubmitting
                  ? 'Saving...'
                  : (widget.employee == null ? 'Save' : 'Update'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        ElevatedButton(
          onPressed: () {
            if (nextTabIndex <= 8) {
              _tabController.animateTo(nextTabIndex);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _primaryTextColor,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hint,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
      enabled: enabled,
      style: TextStyle(color: _primaryTextColor),
      decoration: _employeeInputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final bool valueExists =
        value == null || items.any((item) => item == value);
    final String? safeValue = valueExists ? value : null;

    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$safeValue'),
      initialValue: safeValue,
      items: items
          .map(
            (String item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: TextStyle(color: _primaryTextColor)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
      dropdownColor: _surfaceColor,
      style: TextStyle(color: _primaryTextColor),
      decoration: _employeeInputDecoration(label: label, icon: icon),
      icon: Icon(Icons.arrow_drop_down, color: _secondaryTextColor),
    );
  }

  Widget _buildOptionDropdown({
    required String label,
    required String? value,
    required List<_OptionItem> items,
    required IconData icon,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final bool valueExists =
        value == null || items.any((item) => item.value == value);
    final String? safeValue = valueExists ? value : null;

    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$safeValue-${items.length}'),
      initialValue: safeValue,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.value,
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _primaryTextColor),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
      dropdownColor: _surfaceColor,
      style: TextStyle(color: _primaryTextColor),
      decoration: _employeeInputDecoration(label: label, icon: icon),
      icon: Icon(Icons.arrow_drop_down, color: _secondaryTextColor),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required String? errorText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _fieldColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: errorText != null ? Colors.red : _borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: errorText != null ? Colors.red : _secondaryTextColor,
            ),
            const SizedBox(width: 12),
            Text(
              selectedDate == null
                  ? label
                  : DateFormat('dd/MM/yyyy').format(selectedDate),
              style: TextStyle(
                color: selectedDate == null
                    ? (errorText != null ? Colors.red : _secondaryTextColor)
                    : _primaryTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _tryParseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      try {
        return DateFormat('dd/MM/yyyy').parse(value);
      } catch (_) {
        return null;
      }
    }
  }
}

class _OptionItem {
  final String value;
  final String label;

  const _OptionItem({required this.value, required this.label});
}
