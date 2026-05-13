import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vendor management screens use the shared feature palette', () {
    final files = [
      File('lib/screens/clients/client_screen.dart'),
      File('lib/screens/clients/assign_employee_screen.dart'),
      File('lib/widgets/client_card.dart'),
    ];

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(
        source,
        contains('VendorPalette'),
        reason: '${file.path} should use the VendorPalette shared colors.',
      );
      expect(
        source,
        isNot(contains('backgroundColor: Colors.blue')),
        reason:
            '${file.path} should not use the old blue app bar/action color.',
      );
    }
  });

  test('vendor management palette follows the feature tab colors', () {
    final palette = File(
      'lib/screens/clients/vendor_palette.dart',
    ).readAsStringSync();

    expect(palette, contains('0xFFF6F4F1'));
    expect(palette, contains('0xFF121212'));
    expect(palette, contains('0xFF5A3F37'));
    expect(palette, contains('0xFF2C7744'));
  });
}
