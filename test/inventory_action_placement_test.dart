import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inventory uses app bar create and form save actions', () {
    final source = File(
      'lib/screens/inventory/inventory_screen.dart',
    ).readAsStringSync();

    expect(source, contains('actions: ['));
    expect(source, contains('Icons.add'));
    expect(source, contains('_InventoryRequestFormScreen'));
    expect(source, isNot(contains('floatingActionButton')));
    expect(source, isNot(contains('FloatingActionButton')));
    expect(source, isNot(contains('AlertDialog(')));
    expect(source, isNot(contains('FloatingActionButton.extended')));
  });

  test('inventory screen derives colors from active theme', () {
    final source = File(
      'lib/screens/inventory/inventory_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Theme.of(context).brightness'));
    expect(source, contains('_pageColor(context)'));
    expect(source, contains('_surfaceColor(context)'));
    expect(source, contains('_primaryTextColor(context)'));
    expect(source, isNot(contains('static const Color _pageColor')));
    expect(source, isNot(contains('static const Color _surfaceColor')));
    expect(source, isNot(contains('static const Color _primaryTextColor')));
  });
}
