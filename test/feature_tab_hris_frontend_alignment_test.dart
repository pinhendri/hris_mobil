import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature tab exposes frontend people development menu permissions', () {
    final source = File('lib/screens/tabs/feature_tab.dart').readAsStringSync();

    expect(source, contains("labelKey: 'people_development'"));
    expect(source, contains("labelKey: 'learning_lms'"));
    expect(source, contains("labelKey: 'talent_management'"));
    expect(source, contains("labelKey: 'employee_relations'"));
    expect(source, contains("'view-pengembangan-sdm'"));
    expect(source, contains("'view-lms'"));
    expect(source, contains("'view-talenta'"));
    expect(source, contains("'view-employee-relation'"));
  });

  test('feature tab exposes frontend claims and overtime permissions', () {
    final source = File('lib/screens/tabs/feature_tab.dart').readAsStringSync();

    expect(source, contains("labelKey: 'feature_label_claims'"));
    expect(source, contains("labelKey: 'feature_label_overtime'"));
    expect(source, contains("'view-claims'"));
    expect(source, contains("'view-overtime'"));
    expect(source, isNot(contains("'create-claims'")));
    expect(source, isNot(contains("'approve-claims'")));
    expect(source, isNot(contains("'create-overtime'")));
    expect(source, isNot(contains("'approve-overtime'")));
  });

  test('broadcast feature requires explicit broadcast permission', () {
    final source = File('lib/screens/tabs/feature_tab.dart').readAsStringSync();
    final helperIndex = source.indexOf('bool _canAccessBroadcastFeature');
    final helperEnd = source.indexOf('bool _canAccessCorrectionsFeature');

    expect(helperIndex, isNonNegative);
    expect(helperEnd, greaterThan(helperIndex));

    final helper = source.substring(helperIndex, helperEnd);
    expect(helper, contains("'view-broadcast'"));
    expect(helper, isNot(contains("'send-broadcast'")));
    expect(helper, isNot(contains("'create-broadcast'")));
    expect(helper, isNot(contains("'edit-broadcast'")));
    expect(helper, isNot(contains("'delete-broadcast'")));
    expect(helper, isNot(contains("'view-recruitment'")));
  });

  test('inventory feature follows frontend visible child permissions', () {
    final source = File('lib/screens/tabs/feature_tab.dart').readAsStringSync();
    final helperIndex = source.indexOf('bool _canAccessInventoryFeature');
    final helperEnd = source.indexOf('bool _canAccessTimeTrackingFeature');

    expect(helperIndex, isNonNegative);
    expect(helperEnd, greaterThan(helperIndex));

    final helper = source.substring(helperIndex, helperEnd);
    expect(helper, contains("'view-inventory-master'"));
    expect(helper, contains("'view-inventory-request'"));
    expect(helper, contains("'view-inventory-receipt'"));
    expect(helper, contains("'view-inventory-report'"));
    expect(helper, isNot(contains("'view-inventory'")));
    expect(helper, isNot(contains("'view-inventory-issued'")));
    expect(helper, isNot(contains("'manage-inventory'")));
    expect(
      source,
      isNot(contains("fallbackPermissions: const ['view-inventory']")),
    );
  });

  test(
    'admin claim menus are not opened by payroll or reports permissions',
    () {
      final source = File('lib/screens/tabs/admin_tab.dart').readAsStringSync();
      final claimManagementIndex = source.indexOf(
        "context.tr('admin_claim_management')",
      );
      final claimReportsIndex = source.indexOf(
        "context.tr('admin_claim_reports')",
      );

      expect(claimManagementIndex, isNonNegative);
      expect(claimReportsIndex, isNonNegative);

      final beforeClaimManagement = source.substring(
        source.lastIndexOf('if (', claimManagementIndex),
        claimManagementIndex,
      );
      final beforeClaimReports = source.substring(
        source.lastIndexOf('if (', claimReportsIndex),
        claimReportsIndex,
      );

      expect(beforeClaimManagement, contains('canAccessClaimsModule'));
      expect(beforeClaimManagement, isNot(contains('canAccessPayrollModule')));
      expect(beforeClaimReports, contains('canAccessClaimsModule'));
      expect(beforeClaimReports, isNot(contains('canAccessReports')));
    },
  );
}
