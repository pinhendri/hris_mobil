import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/employee_model.dart';

void main() {
  test('mobile edit employee form pre-fills contact fields before update', () {
    final source = File(
      'lib/screens/employee/add_employee_screen.dart',
    ).readAsStringSync();
    final initStateStart = source.indexOf('void initState()');
    final initStateEnd = source.indexOf(
      '@override\n  void dispose()',
      initStateStart,
    );

    expect(initStateStart, isNonNegative);
    expect(initStateEnd, isNonNegative);

    final initStateSource = source.substring(initStateStart, initStateEnd);

    expect(initStateSource, contains("_emailController.text = e.email ?? '';"));
    expect(initStateSource, contains("_phoneController.text = e.phone ?? '';"));
  });

  test('employee update refreshes selected employee from backend detail', () {
    final source = File(
      'lib/providers/employee_provider.dart',
    ).readAsStringSync();
    final updateStart = source.indexOf('Future<bool> updateEmployee(');
    final createStart = source.indexOf('// Create new employee', updateStart);

    expect(updateStart, isNonNegative);
    expect(createStart, isNonNegative);

    final updateSource = source.substring(updateStart, createStart);

    expect(
      updateSource,
      matches(RegExp(r'await\s+fetchEmployeeDetail\(\s*updatedEmployee\.uuid')),
    );
    expect(updateSource, contains('_mergeEmployeeUpdatePayload'));
  });

  test('employee model reads backend aliases used by mobile and frontend', () {
    final employee = Employee.fromJson({
      'id': 7,
      'uuid': 'emp-7',
      'nik': '123',
      'nik_employee': 'MSS-001',
      'name': 'Ayu',
      'position': {'id': 3, 'nama_jabatan': 'HR Manager'},
      'department': {'id': 2, 'name': 'Human Resource'},
      'status': 'Active',
      'join_date': '2026-05-01',
      'profile_picture': '/avatars/ayu.png',
      'basic_salary': '12000000',
      'end_date': '2026-12-31',
      'cv_url': '/docs/cv.pdf',
      'supervisor': {'uuid': 'lead-1', 'name': 'Budi'},
      'shift': {
        'id': 5,
        'name': 'Morning',
        'description': '08:00 - 17:00',
        'clock_in': '08:00',
        'clock_out': '17:00',
      },
      'skills': 'Recruitment, Payroll',
      'assigned_equipment': 'Laptop, Phone',
      'system_access': 'HRIS, Email',
      'company_policies_acknowledged': 1,
      'handbook_acknowledged': 'true',
    });

    expect(employee.position, 'HR Manager');
    expect(employee.positionId, '3');
    expect(employee.department, 'Human Resource');
    expect(employee.departmentId, '2');
    expect(employee.avatarUrl, '/avatars/ayu.png');
    expect(employee.salary, 12000000);
    expect(employee.endDate, '2026-12-31');
    expect(employee.cvUrl, '/docs/cv.pdf');
    expect(employee.managerId, 'lead-1');
    expect(employee.supervisorName, 'Budi');
    expect(employee.shiftId, '5');
    expect(employee.shiftName, 'Morning');
    expect(employee.clockIn, '08:00');
    expect(employee.clockOut, '17:00');
    expect(employee.skills, ['Recruitment', 'Payroll']);
    expect(employee.assignedEquipment, ['Laptop', 'Phone']);
    expect(employee.systemAccess, ['HRIS', 'Email']);
    expect(employee.companyPoliciesAcknowledged, isTrue);
    expect(employee.handbookAcknowledged, isTrue);
  });

  test(
    'frontend employee detail exposes the same information groups as mobile',
    () {
      final source = File(
        'talent-unbound-main/src/pages/EmployeeDetail.tsx',
      ).readAsStringSync();

      expect(source, contains('Basic Information'));
      expect(source, contains('Work Information'));
      expect(source, contains('Payroll & Compliance'));
      expect(source, contains('Emergency & Health'));
      expect(source, contains('Education & Access'));
      expect(source, contains('Attachments & Acknowledgement'));
      expect(source, isNot(contains('User Role Debug Info')));
    },
  );

  test(
    'frontend edit employee resolves religion value from backend aliases',
    () {
      final source = File(
        'talent-unbound-main/src/pages/EditEmployee.tsx',
      ).readAsStringSync();

      expect(source, contains('const resolveReligionId'));
      expect(source, contains('const defaultReligionOptions'));
      expect(source, contains('data.religion?.id'));
      expect(source, contains('data.religion_name'));
      expect(source, contains('resolveReligionId(data, religionOptions)'));
      expect(source, contains('const visibleReligionOptions'));
      expect(source, contains('visibleReligionOptions.map'));
      expect(source, contains('<select'));
      expect(source, contains('<option value="">Select religion</option>'));
      expect(source, isNot(contains('api_laravel.get("/api/religions")')));
    },
  );
}
