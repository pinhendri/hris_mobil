import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/bot_assistant_model.dart';

void main() {
  test('create leave draft fields match frontend action payload', () {
    final fields = botActionFieldConfigs['create-leave-draft']!;
    final leaveType = fields.first;

    expect(leaveType.name, 'type');
    expect(leaveType.type, BotActionFieldType.select);
    expect(leaveType.defaultValue, 'Annual');
    expect(
      leaveType.options?.map((option) => option.value),
      containsAll(['Annual', 'Sick', 'Personal']),
    );
    expect(fields.map((field) => field.name), [
      'type',
      'start_date',
      'end_date',
      'reason',
    ]);
  });
}
