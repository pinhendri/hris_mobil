import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('employee form places save action in the app bar only', () {
    final source = File(
      'lib/screens/employee/add_employee_screen.dart',
    ).readAsStringSync();

    expect(source, contains('actions: [_buildSaveAction()]'));
    expect(source, isNot(contains('Submit Employee Data')));
    expect(source, isNot(contains('Update Employee Data')));
    expect(source, isNot(contains('Icons.save_outlined')));
  });
}
