import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user management screen derives colors from active theme', () {
    final source = File(
      'lib/screens/admin/user_management_menu_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Theme.of(context).brightness'));
    expect(source, contains('_pageColor(isDark)'));
    expect(source, contains('_surfaceColor(isDark)'));
    expect(source, contains('_primaryTextColor(isDark)'));
    expect(source, contains('_secondaryTextColor(isDark)'));
    expect(source, isNot(contains('backgroundColor: const Color(0xFFF6F7FB)')));
    expect(source, isNot(contains('backgroundColor: Colors.white')));
    expect(
      source,
      isNot(contains('iconTheme: const IconThemeData(color: Colors.black)')),
    );
  });
}
