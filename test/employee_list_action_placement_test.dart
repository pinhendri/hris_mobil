import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('employee list uses app bar add action instead of floating button', () {
    final source = File(
      'lib/screens/employee/employee_list_screen.dart',
    ).readAsStringSync();

    expect(source, contains('actions: ['));
    expect(source, contains('Icons.add'));
    expect(source, isNot(contains('floatingActionButton')));
    expect(source, isNot(contains('FloatingActionButton')));
  });
}
