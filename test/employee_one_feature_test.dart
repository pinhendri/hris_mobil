import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/user.dart';
import 'package:hris_mobile/providers/employee_provider.dart';

void main() {
  test('feature tab opens Karyawan Satu with a self-scoped employee list', () {
    final source = File('lib/screens/tabs/feature_tab.dart').readAsStringSync();
    final labelIndex = source.indexOf("labelKey: 'feature_label_employee_one'");

    expect(labelIndex, isNonNegative);

    final snippet = source.substring(
      labelIndex,
      math.min(labelIndex + 260, source.length),
    );

    expect(snippet, contains('EmployeeListScreen(selfOnly: true)'));
  });

  test('employee one permission does not open the full employee feature', () {
    final source = File('lib/screens/tabs/feature_tab.dart').readAsStringSync();
    final helperIndex = source.indexOf('bool _canAccessEmployeeFeature');

    expect(helperIndex, isNonNegative);

    final helperSnippet = source.substring(
      helperIndex,
      source.indexOf('bool _canAccessOrgStructureFeature', helperIndex),
    );

    expect(helperSnippet, contains("'view-employee'"));
    expect(helperSnippet, isNot(contains("'view-employee-one'")));
  });

  test(
    'employee-one resolver never treats user account uuid as employee uuid',
    () {
      final accountOnlyUser = User.fromMap({
        'id': 12,
        'name': 'Account Only',
        'email': 'account.only@example.com',
        'uuid': 'user-account-uuid',
      });

      expect(
        EmployeeProvider.currentUserEmployeeUuid(accountOnlyUser),
        isEmpty,
      );

      final employeeLinkedUser = User.fromMap({
        'id': 13,
        'name': 'Employee Linked',
        'email': 'employee.linked@example.com',
        'uuid': 'user-account-uuid',
        'employee_uuid': 'employee-record-uuid',
      });

      expect(
        EmployeeProvider.currentUserEmployeeUuid(employeeLinkedUser),
        'employee-record-uuid',
      );
    },
  );
}
