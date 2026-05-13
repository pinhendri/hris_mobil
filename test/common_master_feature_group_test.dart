import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature tab opens common master directly without nested submenu', () {
    final source = File('lib/screens/tabs/feature_tab.dart').readAsStringSync();
    final commonMasterIndex = source.indexOf("labelKey: 'admin_common_master'");

    expect(commonMasterIndex, isNot(-1));

    final userManagementIndex = source.indexOf(
      "labelKey: 'admin_user_management'",
      commonMasterIndex,
    );
    final commonMasterBlock = source.substring(
      commonMasterIndex,
      userManagementIndex,
    );

    expect(commonMasterBlock, isNot(contains('children: [')));
    expect(commonMasterBlock, contains('CommonMasterMenuScreen'));
  });

  test('common master screen shows department as a direct master card', () {
    final source = File(
      'lib/screens/admin/common_master_menu_screen.dart',
    ).readAsStringSync();

    expect(source, contains("title: 'Departemen'"));
    expect(source, contains("'view-department'"));
    expect(source, contains('DepartmentListScreen'));
  });

  test('feature tab does not expose department as a top-level feature', () {
    final source = File('lib/screens/tabs/feature_tab.dart').readAsStringSync();

    expect(source, isNot(contains("labelKey: 'admin_master_department'")));
    expect(source, isNot(contains('DepartmentListScreen')));
  });

  test('admin tab does not expose department as a top-level menu', () {
    final source = File('lib/screens/tabs/admin_tab.dart').readAsStringSync();
    final masterDataStart = source.indexOf(
      "context.tr('admin_section_master_data')",
    );
    final commonMasterIndex = source.indexOf(
      "context.tr('admin_common_master')",
    );

    expect(masterDataStart, isNot(-1));
    expect(commonMasterIndex, isNot(-1));

    final masterDataBeforeCommonMaster = source.substring(
      masterDataStart,
      commonMasterIndex,
    );

    expect(
      masterDataBeforeCommonMaster,
      isNot(contains("context.tr('admin_master_department')")),
    );
    expect(
      masterDataBeforeCommonMaster,
      isNot(contains('DepartmentListScreen')),
    );
  });
}
