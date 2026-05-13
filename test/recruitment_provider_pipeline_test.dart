import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'recruitment provider builds the same seven pipeline stages as frontend',
    () {
      final source = File(
        'lib/providers/recruitment_provider.dart',
      ).readAsStringSync();
      final stageListStart = source.indexOf('const stages = [');

      expect(stageListStart, isNonNegative);

      final stageListEnd = source.indexOf('];', stageListStart);
      final stageListSource = source.substring(stageListStart, stageListEnd);

      expect(stageListSource, contains("'Applied'"));
      expect(stageListSource, contains("'Screening'"));
      expect(stageListSource, contains("'Interview'"));
      expect(stageListSource, contains("'Offer'"));
      expect(stageListSource, contains("'Hired'"));
      expect(stageListSource, contains("'Rejected'"));
      expect(stageListSource, contains("'Withdrawn'"));
      expect(RegExp(r"'[^']+'").allMatches(stageListSource).length, 7);
    },
  );
}
