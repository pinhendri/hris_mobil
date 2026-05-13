import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meeting list uses app bar create and refresh actions', () {
    final source = File(
      'lib/screens/admin/event_management_screen.dart',
    ).readAsStringSync();

    expect(source, contains('actions: ['));
    expect(source, contains('Icons.add'));
    expect(source, contains('Icons.refresh'));
    expect(source, isNot(contains('floatingActionButton')));
    expect(source, isNot(contains('FloatingActionButton')));
    expect(source, isNot(contains('FloatingActionButton.extended')));
  });

  test('meeting form saves from app bar without bottom submit button', () {
    final source = File(
      'lib/screens/admin/add_edit_event_screen.dart',
    ).readAsStringSync();

    expect(source, contains('actions: ['));
    expect(source, contains("context.tr('meeting_save')"));
    expect(source, isNot(contains('ElevatedButton(')));
    expect(source, isNot(contains("context.tr('meeting_create')")));
    expect(source, isNot(contains("context.tr('meeting_update')")));
  });
}
