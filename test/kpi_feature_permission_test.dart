import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kpi feature follows frontend kpi parent and child permissions', () {
    final source = File('lib/screens/tabs/feature_tab.dart').readAsStringSync();
    final helperIndex = source.indexOf('bool _canAccessKpiFeature');

    expect(helperIndex, isNonNegative);

    final helperSnippet = source.substring(
      helperIndex,
      source.indexOf('bool _canAccessInventoryFeature', helperIndex),
    );

    expect(helperSnippet, contains("'view-kpi'"));
    expect(helperSnippet, contains("'view-kpi-master'"));
    expect(helperSnippet, contains("'view-kpi-evaluation'"));
    expect(helperSnippet, contains("'view-department-goals'"));
    expect(helperSnippet, contains("'view-employee-goals'"));
  });

  test('kpi feature exposes four frontend kpi children', () {
    final source = File('lib/screens/tabs/feature_tab.dart').readAsStringSync();
    final kpiIndex = source.indexOf("labelKey: 'feature_label_kpi'");

    expect(kpiIndex, isNonNegative);

    final nextFeatureIndex = source.indexOf(
      "labelKey: 'people_development'",
      kpiIndex,
    );
    final kpiBlock = source.substring(kpiIndex, nextFeatureIndex);

    expect(kpiBlock, contains("labelKey: 'kpi_master'"));
    expect(kpiBlock, contains("labelKey: 'kpi_evaluation_list'"));
    expect(kpiBlock, contains("labelKey: 'kpi_department_goals'"));
    expect(kpiBlock, contains("labelKey: 'kpi_employee_goals'"));
    expect(RegExp(r"FeatureSubmenuItem\(").allMatches(kpiBlock).length, 4);
    expect(kpiBlock, contains("permission: 'view-kpi-master'"));
    expect(kpiBlock, contains("permission: 'view-kpi-evaluation'"));
    expect(kpiBlock, contains("permission: 'view-employee-goals'"));
  });
}
