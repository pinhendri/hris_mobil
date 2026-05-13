import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/employee_model.dart';

void main() {
  test('employee model keeps religion id and name from backend', () {
    final employee = Employee.fromJson({
      'id': 1,
      'uuid': 'employee-1',
      'name': 'Andi',
      'position': 'Staff',
      'department': 'HR',
      'religion_id': 1,
      'religion_name': 'Islam',
    });

    expect(employee.religionId, '1');
    expect(employee.religionName, 'Islam');
    expect(employee.toJson()['religion_id'], '1');
  });

  test('mobile employee personal form loads and submits religion id', () {
    final source = File(
      'lib/screens/employee/add_employee_screen.dart',
    ).readAsStringSync();

    expect(source, contains('class _ReligionOption'));
    expect(source, contains("Future<void> _loadReligions()"));
    expect(source, contains("'/religions'"));
    expect(source, contains("_selectedReligion = e.religionId;"));
    expect(source, contains("label: 'Religion'"));
    expect(
      source,
      contains("'religion_id': int.tryParse(_selectedReligion ?? '')"),
    );
  });
}
