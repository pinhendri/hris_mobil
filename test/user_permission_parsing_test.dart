import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/user.dart';
import 'package:hris_mobile/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return Directory.systemTemp.path;
          }
          return null;
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  test('flattens permissions assigned through backend roles', () {
    final user = User.fromMap({
      'id': 7,
      'name': 'Role User',
      'email': 'role.user@example.com',
      'uuid': 'user-uuid',
      'roles': [
        {
          'name': 'Payroll Staff',
          'permissions': [
            {'name': 'view-payroll'},
            {'name': 'view-payslip'},
          ],
        },
        {
          'name': 'Attendance Admin',
          'permissions': ['view-default-location'],
        },
      ],
      'permissions': [
        {'name': 'view-attendance'},
      ],
    });

    expect(user.roles, containsAll(['Payroll Staff', 'Attendance Admin']));
    expect(
      user.permissions,
      containsAll([
        'view-attendance',
        'view-payroll',
        'view-payslip',
        'view-default-location',
      ]),
    );
  });

  test('keeps user uuid separate from employee identifiers', () {
    final user = User.fromMap({
      'id': 2,
      'name': 'RBA',
      'email': 'rba@kkk.com',
      'uuid': 'user-account-uuid',
      'employee': {
        'id': 17,
        'name': 'rba@kkk.com',
      },
      'permissions': <String>[],
    });

    expect(user.uuid, 'user-account-uuid');
    expect(user.employeeUuid, isNull);
    expect(user.employeeRecordId, '17');
  });

  test(
    'matches assigned permissions using standardized kebab-case keys',
    () async {
      final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
      addTearDown(authProvider.dispose);

      await authProvider.setUser({
        'id': 8,
        'name': 'Mixed Permission User',
        'email': 'mixed.permission@example.com',
        'uuid': 'mixed-user-uuid',
        'permissions': [
          {'name': 'view-employeeOne'},
          {'name': 'view_Broadcast'},
        ],
      });

      expect(authProvider.hasPermission('view-employee-one'), isTrue);
      expect(authProvider.hasPermission('view-broadcast'), isTrue);
    },
  );

  test(
    'does not treat a regular user with admin permissions as admin hr',
    () async {
      final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
      addTearDown(authProvider.dispose);

      await authProvider.setUser({
        'id': 9,
        'name': 'Regular User',
        'email': 'rba@kkk.com',
        'uuid': 'regular-user-uuid',
        'role': 'user',
        'roles': ['user'],
        'permissions': [
          {'name': 'view-leave'},
          {'name': 'view-broadcast'},
          {'name': 'view-settings'},
        ],
      });

      expect(authProvider.hasPermission('view-leave'), isTrue);
      expect(authProvider.hasAdminHrRole, isFalse);
      expect(authProvider.canAccessAdminPanel, isFalse);
    },
  );

  test('recognizes admin and hr roles for admin hr menus', () async {
    final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
    addTearDown(authProvider.dispose);

    await authProvider.setUser({
      'id': 10,
      'name': 'HR Admin',
      'email': 'hr.admin@example.com',
      'uuid': 'hr-admin-uuid',
      'role': 'HR Admin',
      'permissions': [
        {'name': 'view-leave'},
      ],
    });

    expect(authProvider.hasAdminHrRole, isTrue);
    expect(authProvider.canAccessAdminPanel, isTrue);
  });

  test('does not let time tracking permission grant task access', () async {
    final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
    addTearDown(authProvider.dispose);

    await authProvider.setUser({
      'id': 11,
      'name': 'Time Tracking User',
      'email': 'time.tracking@example.com',
      'uuid': 'time-tracking-user-uuid',
      'role': 'user',
      'permissions': [
        {'name': 'view-time-tracking'},
      ],
    });

    expect(authProvider.hasPermission('view-time-tracking'), isTrue);
    expect(authProvider.hasPermission('view-tasks'), isFalse);
  });

  test('treats platform super admin role as full access fallback', () async {
    final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
    addTearDown(authProvider.dispose);

    await authProvider.setUser({
      'id': 12,
      'name': 'Super Admin',
      'email': 'super.admin@example.com',
      'uuid': 'super-admin-user-uuid',
      'role': 'super-admin',
      'permissions': <String>[],
    });

    expect(authProvider.hasPermission('view-employee'), isTrue);
    expect(authProvider.hasPermission('view-settings'), isTrue);
    expect(authProvider.hasPermission('assign-roles'), isTrue);
  });
}
