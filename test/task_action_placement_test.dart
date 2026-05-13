import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tasks uses app bar create and form save actions', () {
    final source = File(
      'lib/screens/tasks/tasks_screen.dart',
    ).readAsStringSync();

    expect(source, contains('actions: ['));
    expect(source, contains('Icons.add'));
    expect(source, contains('_TaskFormScreen'));
    expect(source, isNot(contains('showModalBottomSheet')));
    expect(source, isNot(contains('floatingActionButton')));
    expect(source, isNot(contains('FloatingActionButton')));
    expect(source, isNot(contains('child: _TaskFormSheet')));
  });
}
