import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature tab groups recruitment menus under one recruitment header', () {
    final source = File('lib/screens/tabs/feature_tab.dart').readAsStringSync();
    final recruitmentIndex = source.indexOf(
      "labelKey: 'feature_label_recruitment'",
    );

    expect(recruitmentIndex, isNot(-1));

    final applicationsIndex = source.indexOf(
      "labelKey: 'feature_label_applications'",
      recruitmentIndex,
    );
    final opsIndex = source.indexOf(
      "labelKey: 'feature_label_recruitment_ops'",
      recruitmentIndex,
    );
    final inventoryIndex = source.indexOf(
      "labelKey: 'feature_label_inventory'",
      recruitmentIndex,
    );
    final recruitmentBlock = source.substring(recruitmentIndex, inventoryIndex);

    expect(recruitmentBlock, contains('children: ['));
    expect(
      recruitmentBlock,
      contains("labelKey: 'feature_label_job_postings'"),
    );
    expect(applicationsIndex, lessThan(inventoryIndex));
    expect(opsIndex, lessThan(inventoryIndex));
  });

  test('recruitment screen uses app bar create and top save actions', () {
    final source = File(
      'lib/screens/recruitment/recruitment_screen.dart',
    ).readAsStringSync();

    expect(source, contains('actions: ['));
    expect(source, contains('Icons.add'));
    expect(source, contains('_RecruitmentJobFormScreen'));
    expect(source, contains('_RecruitmentApplicationFormScreen'));
    expect(source, isNot(contains('floatingActionButton')));
  });
}
