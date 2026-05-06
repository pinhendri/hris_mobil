import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/utils/home_performance_loading.dart';

void main() {
  test('loads home performance even when KPI module is not accessible', () {
    expect(
      shouldLoadHomePerformance(canAccessPerformanceModule: false),
      isTrue,
    );
  });
}
