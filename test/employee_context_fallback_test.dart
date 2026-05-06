import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/utils/employee_context_fallback.dart';

void main() {
  test('extracts employee id from leave balance payload', () {
    final context = employeeContextFromLeaveBalance({
      'success': true,
      'data': {
        'employee_id': 61,
        'uuid': '5161bc07-8162-4c16-a137-f8d723af1492',
        'employee': 'rba@kkk.com',
        'department': 'hendri_local',
      },
    });

    expect(context?.id, 61);
    expect(context?.uuid, '5161bc07-8162-4c16-a137-f8d723af1492');
  });
}
