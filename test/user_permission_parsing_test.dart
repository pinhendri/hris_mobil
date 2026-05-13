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
      'employee': {'id': 17, 'name': 'rba@kkk.com'},
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
    'lets assigned admin permissions show admin menus without requiring an HR role',
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
      expect(authProvider.canAccessAdminPanel, isTrue);
    },
  );

  test(
    'lets assigned employee permission access full employee module without an HR role',
    () async {
      final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
      addTearDown(authProvider.dispose);

      await authProvider.setUser({
        'id': 13,
        'name': 'Employee Viewer',
        'email': 'employee.viewer@example.com',
        'uuid': 'employee-viewer-user-uuid',
        'role': 'user',
        'permissions': [
          {'name': 'view-employee'},
        ],
      });

      expect(authProvider.hasAdminHrRole, isFalse);
      expect(authProvider.canAccessEmployeeModule, isTrue);
      expect(authProvider.canViewAllEmployeeData, isTrue);
      expect(authProvider.shouldUseSelfEmployeeScope, isFalse);
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

  test('does not show broadcast from recruitment permission alone', () async {
    final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
    addTearDown(authProvider.dispose);

    await authProvider.setUser({
      'id': 16,
      'name': 'Recruitment Only User',
      'email': 'hendri.ariiii@gmail.com',
      'uuid': 'recruitment-only-user-uuid',
      'role': 'user',
      'permissions': [
        {'name': 'view-recruitment'},
      ],
    });

    expect(authProvider.canAccessRecruitmentModule, isTrue);
    expect(authProvider.canAccessBroadcastModule, isFalse);
  });

  test(
    'matches frontend by requiring view-broadcast for broadcast menu',
    () async {
      final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
      addTearDown(authProvider.dispose);

      await authProvider.setUser({
        'id': 17,
        'name': 'Broadcast Sender Only',
        'email': 'broadcast.sender@example.com',
        'uuid': 'broadcast-sender-only-user-uuid',
        'role': 'user',
        'permissions': [
          {'name': 'send-broadcast'},
          {'name': 'create-broadcast'},
          {'name': 'edit-broadcast'},
          {'name': 'delete-broadcast'},
        ],
      });

      expect(authProvider.hasPermission('send-broadcast'), isTrue);
      expect(authProvider.canAccessBroadcastModule, isFalse);
    },
  );

  test('matches frontend by requiring view-claims for claims menu', () async {
    final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
    addTearDown(authProvider.dispose);

    await authProvider.setUser({
      'id': 19,
      'name': 'Claim Action Only',
      'email': 'claim.action@example.com',
      'uuid': 'claim-action-only-user-uuid',
      'role': 'user',
      'permissions': [
        {'name': 'create-claims'},
        {'name': 'edit-claims'},
        {'name': 'approve-claims'},
        {'name': 'view-payroll'},
        {'name': 'view-reports'},
      ],
    });

    expect(authProvider.hasPermission('view-claims'), isFalse);
    expect(authProvider.canAccessClaimsModule, isFalse);
    expect(authProvider.canAccessPayrollModule, isTrue);
    expect(authProvider.canAccessReportsModule, isTrue);
  });

  test(
    'keeps settings permission fallback aligned with frontend sidebar',
    () async {
      final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
      addTearDown(authProvider.dispose);

      await authProvider.setUser({
        'id': 14,
        'name': 'Frontend Menu User',
        'email': 'frontend.menu@example.com',
        'uuid': 'frontend-menu-user-uuid',
        'role': 'user',
        'permissions': [
          {'name': 'view-settings'},
        ],
      });

      expect(authProvider.canAccessCorrectionsModule, isTrue);
    },
  );

  test('matches frontend permission keys without legacy aliases', () async {
    final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
    addTearDown(authProvider.dispose);

    await authProvider.setUser({
      'id': 15,
      'name': 'Frontend Permission User',
      'email': 'frontend.permission@example.com',
      'uuid': 'frontend-permission-user-uuid',
      'role': 'user',
      'permissions': [
        {'name': 'view_ic'},
        {'name': 'view_ic_master'},
        {'name': 'view_inventory_receipt'},
        {'name': 'view_user_management'},
        {'name': 'view_user_roles'},
        {'name': 'manage_general_settings'},
        {'name': 'manage_company_profile'},
      ],
    });

    expect(authProvider.hasPermission('view-inventory'), isFalse);
    expect(authProvider.hasPermission('view-inventory-master'), isFalse);
    expect(authProvider.hasPermission('view-inventory-receipt'), isTrue);
    expect(authProvider.canAccessInventoryModule, isTrue);
    expect(authProvider.hasPermission('view-users'), isFalse);
    expect(authProvider.hasPermission('view-roles'), isFalse);
    expect(authProvider.canAccessSettingsModule, isFalse);
    expect(authProvider.canAccessAdminPanel, isFalse);
  });

  test(
    'does not show inventory from parent or legacy inventory permissions alone',
    () async {
      final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
      addTearDown(authProvider.dispose);

      await authProvider.setUser({
        'id': 18,
        'name': 'Inventory Parent Only',
        'email': 'inventory.parent@example.com',
        'uuid': 'inventory-parent-only-user-uuid',
        'role': 'user',
        'permissions': [
          {'name': 'view-inventory'},
          {'name': 'view-ic'},
          {'name': 'manage-inventory'},
          {'name': 'issue-stock'},
        ],
      });

      expect(authProvider.hasPermission('view-inventory'), isTrue);
      expect(authProvider.hasPermission('view-inventory-master'), isFalse);
      expect(authProvider.canAccessInventoryModule, isFalse);
    },
  );

  test(
    'does not use platform admin role as menu permission fallback',
    () async {
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

      expect(authProvider.hasPermission('view-employee'), isFalse);
      expect(authProvider.hasPermission('view-settings'), isFalse);
      expect(authProvider.hasPermission('assign-roles'), isFalse);
      expect(authProvider.canAccessPlatformAdmin, isTrue);
    },
  );
}
