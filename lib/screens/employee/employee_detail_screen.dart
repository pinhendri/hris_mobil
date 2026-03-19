import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/access_denied_state.dart';
import '../../core/utils/image_helper.dart';
import '../../models/employee_model.dart';
import '../../providers/auth_provider.dart';
import 'add_employee_screen.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final Employee employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canViewEmployee = authProvider.canViewEmployeeScreen;
    final canEditEmployee = authProvider.hasPermission('edit-employee');
    final sections = _buildSections();

    if (!canViewEmployee) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Employee Profile',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const AccessDeniedState(permissionLabel: 'view/manage employee'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Employee Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (canEditEmployee)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEmployeeScreen(employee: employee),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: sections
                    .map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildSectionCard(section),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage:
                  employee.avatarUrl != null && employee.avatarUrl!.isNotEmpty
                  ? ImageHelper.avatar(employee.avatarUrl)
                  : null,
              child: employee.avatarUrl == null || employee.avatarUrl!.isEmpty
                  ? Text(
                      _getInitials(employee.name),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            employee.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _displayValue(employee.positionName ?? employee.position),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _displayValue(
              employee.departmentDescription ?? employee.department,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(employee.status, _getStatusColor(employee.status)),
              if ((employee.cCode ?? '').isNotEmpty)
                _buildBadge('Company ${employee.cCode}', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  List<_DetailSection> _buildSections() {
    return [
      _DetailSection(
        title: 'Basic Information',
        items: [
          _DetailEntry(
            'Employee ID / NIK',
            employee.nik ?? employee.nikEmployee,
          ),
          _DetailEntry('Auto Employee Code', employee.nikEmployee),
          _DetailEntry('Email', employee.email),
          _DetailEntry('Phone', employee.phone),
          _DetailEntry('Gender', employee.gender),
          _DetailEntry('Date of Birth', _formatDate(employee.dateOfBirth)),
          _DetailEntry('Nationality', employee.nationality),
          _DetailEntry('Marital Status', employee.maritalStatus),
          _DetailEntry('Religion', employee.religionName),
          _DetailEntry('Address', employee.address),
        ],
      ),
      _DetailSection(
        title: 'Work Information',
        items: [
          _DetailEntry('Position', employee.positionName ?? employee.position),
          _DetailEntry(
            'Department',
            employee.departmentDescription ?? employee.department,
          ),
          _DetailEntry('Join Date', _formatDate(employee.joinDate)),
          _DetailEntry('Employment Type', employee.employmentType),
          _DetailEntry('Flag', employee.flag),
          _DetailEntry('Contract Type', employee.contractType),
          _DetailEntry('Contract End Date', _formatDate(employee.endDate)),
          _DetailEntry('Supervisor', employee.supervisorName),
          _DetailEntry('Shift', _buildShiftLabel()),
          _DetailEntry('Office Location', employee.officeLocation),
          _DetailEntry('Work Schedule', employee.workSchedule),
        ],
      ),
      _DetailSection(
        title: 'Payroll & Compliance',
        items: [
          _DetailEntry('Salary', _formatCurrency(employee.salary)),
          _DetailEntry('PTKP', employee.ptkpCode),
          _DetailEntry('Tax Number / NPWP', employee.taxNumber),
          _DetailEntry('Bank Name', employee.bankName),
          _DetailEntry('Bank Account Number', employee.bankAccountNumber),
          _DetailEntry('Account Type', employee.accountType),
          _DetailEntry('SSN / Identity Number', employee.ssn),
          _DetailEntry('Work Authorization', employee.workAuthorization),
        ],
      ),
      _DetailSection(
        title: 'Emergency & Health',
        items: [
          _DetailEntry('Emergency Contact Name', employee.emergencyContactName),
          _DetailEntry(
            'Emergency Relationship',
            employee.emergencyContactRelationship,
          ),
          _DetailEntry('Emergency Phone', employee.emergencyContactPhone),
          _DetailEntry('Blood Type', employee.bloodType),
          _DetailEntry('Medical Conditions', employee.medicalConditions),
          _DetailEntry('Emergency Medical Info', employee.emergencyMedicalInfo),
        ],
      ),
      _DetailSection(
        title: 'Education & Access',
        items: [
          _DetailEntry('Highest Education', employee.highestEducation),
          _DetailEntry('Degree / Major', employee.degree),
          _DetailEntry('Institution', employee.institution),
          _DetailEntry('Graduation Date', _formatDate(employee.graduationYear)),
          _DetailEntry(
            'Years of Experience',
            employee.yearsOfExperience?.toString(),
          ),
          _DetailEntry('Previous Employers', employee.previousEmployers),
          _DetailEntry('Skills', _joinValues(employee.skills)),
          _DetailEntry('Certifications', employee.certifications),
          _DetailEntry(
            'Assigned Equipment',
            _joinValues(employee.assignedEquipment),
          ),
          _DetailEntry('System Access', _joinValues(employee.systemAccess)),
          _DetailEntry('Training Plan', employee.trainingPlan),
        ],
      ),
      _DetailSection(
        title: 'Attachments & Acknowledgement',
        items: [
          _DetailEntry(
            'CV',
            employee.cvUrl != null && employee.cvUrl!.isNotEmpty
                ? 'Available'
                : null,
          ),
          _DetailEntry(
            'Company Policies Acknowledged',
            _boolLabel(employee.companyPoliciesAcknowledged),
          ),
          _DetailEntry(
            'Handbook Acknowledged',
            _boolLabel(employee.handbookAcknowledged),
          ),
        ],
      ),
    ];
  }

  Widget _buildSectionCard(_DetailSection section) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...section.items.map(_buildInfoRow),
        ],
      ),
    );
  }

  Widget _buildInfoRow(_DetailEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _displayValue(entry.value),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _buildShiftLabel() {
    final shiftName = (employee.shiftName ?? '').trim();
    final shiftDescription = (employee.shiftType ?? '').trim();
    final shift =
        shiftName.isNotEmpty &&
            shiftDescription.isNotEmpty &&
            shiftDescription != shiftName
        ? '$shiftName - $shiftDescription'
        : shiftName.isNotEmpty
        ? shiftName
        : shiftDescription;
    if ((employee.clockIn ?? '').isNotEmpty &&
        (employee.clockOut ?? '').isNotEmpty) {
      final hours = '${employee.clockIn} - ${employee.clockOut}';
      if (shift.isNotEmpty) {
        return '$shift ($hours)';
      }
      return hours;
    }
    return shift;
  }

  String _displayValue(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? '-' : normalized;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatCurrency(double value) {
    if (value <= 0) return '-';
    final normalized = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 2,
    );
    final parts = normalized.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    if (parts.length == 1 || parts.last == '00') {
      return 'Rp $whole';
    }
    return 'Rp $whole.${parts.last}';
  }

  String _joinValues(List<String>? values) {
    if (values == null || values.isEmpty) return '';
    return values.where((value) => value.trim().isNotEmpty).join(', ');
  }

  String _boolLabel(bool? value) {
    if (value == null) return '';
    return value ? 'Yes' : 'No';
  }

  String _getInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) return 'EM';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'on leave':
        return Colors.orange;
      case 'inactive':
      case 'deactive':
        return Colors.grey;
      case 'terminated':
      case 'resigned':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _DetailSection {
  final String title;
  final List<_DetailEntry> items;

  const _DetailSection({required this.title, required this.items});
}

class _DetailEntry {
  final String label;
  final String? value;

  const _DetailEntry(this.label, this.value);
}
