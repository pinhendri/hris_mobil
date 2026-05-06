import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/employee_model.dart';
import 'package:hris_mobile/providers/employee_provider.dart';

void main() {
  test('returns only employees in the current employee subordinate tree', () {
    final manager = _employee(id: '1', uuid: 'manager-uuid', name: 'Manager');
    final directReport = _employee(
      id: '2',
      uuid: 'direct-uuid',
      name: 'Direct Report',
      managerId: 'manager-uuid',
    );
    final indirectReport = _employee(
      id: '3',
      uuid: 'indirect-uuid',
      name: 'Indirect Report',
      managerId: 'direct-uuid',
    );
    final otherEmployee = _employee(
      id: '4',
      uuid: 'other-uuid',
      name: 'Other Employee',
      managerId: 'someone-else',
    );

    final result = EmployeeProvider.filterSubordinateTree(
      employees: [manager, directReport, indirectReport, otherEmployee],
      managerEmployeeId: 'manager-uuid',
    );

    expect(result.map((employee) => employee.uuid), [
      'direct-uuid',
      'indirect-uuid',
    ]);
  });

  test('matches subordinate tree when manager id is stored as numeric id', () {
    final directReport = _employee(
      id: '2',
      uuid: 'direct-uuid',
      name: 'Direct Report',
      managerId: '1',
    );

    final result = EmployeeProvider.filterSubordinateTree(
      employees: [directReport],
      managerEmployeeId: '1',
    );

    expect(result.single.uuid, 'direct-uuid');
  });
}

Employee _employee({
  required String id,
  required String uuid,
  required String name,
  String? managerId,
}) {
  return Employee(
    id: id,
    uuid: uuid,
    name: name,
    position: 'Staff',
    department: 'Operations',
    status: 'Active',
    joinDate: '2026-01-01',
    managerId: managerId,
  );
}
