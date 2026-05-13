import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'admin submenu screens use shared admin palette instead of local page colors',
    () {
      final files = [
        'lib/screens/admin/common_master_menu_screen.dart',
        'lib/screens/admin/event_management_screen.dart',
        'lib/screens/admin/department_list_screen.dart',
        'lib/screens/admin/department_detail_screen.dart',
        'lib/screens/admin/add_edit_department_screen.dart',
        'lib/screens/admin/add_edit_event_screen.dart',
        'lib/screens/admin/user_management_menu_screen.dart',
        'lib/screens/admin/master_shift_screen.dart',
        'lib/screens/admin/shift_assignment_screen.dart',
        'lib/screens/admin/org_structure_screen.dart',
        'lib/screens/admin/correction_management_screen.dart',
        'lib/screens/admin/claim_management_screen.dart',
        'lib/screens/admin/claim_reports_screen.dart',
        'lib/screens/admin/broadcast_screen.dart',
        'lib/screens/admin/leave_management_enhanced_screen.dart',
      ];

      for (final file in files) {
        final source = File(file).readAsStringSync();

        expect(source, contains('AdminPalette'), reason: file);
        expect(
          source,
          isNot(contains('const Color(0xFFF6F7FB)')),
          reason: file,
        );
        expect(source, isNot(contains('Colors.grey[50]')), reason: file);
      }
    },
  );
}
