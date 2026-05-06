import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/claim_model.dart';
import 'package:hris_mobile/models/leave_model.dart';
import 'package:hris_mobile/models/user.dart';
import 'package:hris_mobile/utils/leave_approval_utils.dart';

void main() {
  User user({
    String uuid = 'manager-user-uuid',
    String? employeeUuid = 'manager-employee-uuid',
  }) {
    return User(
      id: 1,
      name: 'Manager',
      email: 'manager@example.com',
      uuid: uuid,
      employeeUuid: employeeUuid,
      position: '',
      selectedCCode: 'RBA',
      permissions: const ['view-leave', 'approve-leave'],
    );
  }

  LeaveRequest request({
    String id = '1',
    String employeeUuid = 'staff-employee-uuid',
    String? immediateSupervisor = 'manager-user-uuid',
    String status = 'Pending',
    String type = 'Annual Leave',
  }) {
    return LeaveRequest(
      id: id,
      uuid: employeeUuid,
      employeeName: 'Staff',
      employeeAvatar: '',
      immediateSupervisor: immediateSupervisor,
      type: type,
      startDate: '2026-05-05',
      endDate: '2026-05-05',
      days: 1,
      status: status,
      reason: 'Family matter',
      createdAt: '2026-05-04',
    );
  }

  test(
    'counts only pending staff leave requests that need current user approval',
    () {
      final currentUser = user();
      final requests = [
        request(id: 'needs-approval'),
        request(id: 'already-approved', status: 'Approved'),
        request(id: 'own-request', employeeUuid: 'manager-employee-uuid'),
        request(id: 'company-leave', type: 'Company Leave'),
        request(id: 'other-manager', immediateSupervisor: 'other-manager'),
      ];

      final pendingApprovals = pendingLeaveApprovalsForUser(
        requests,
        currentUser,
      );

      expect(pendingApprovals.map((item) => item.id), ['needs-approval']);
      expect(
        leaveRequestNeedsCurrentUserApproval(request(), currentUser),
        isTrue,
      );
      expect(
        leaveRequestNeedsCurrentUserApproval(
          request(employeeUuid: 'manager-employee-uuid'),
          currentUser,
        ),
        isFalse,
      );
    },
  );

  test('counts only submitted claims that need current user approval', () {
    final currentUser = user();
    final claims = [
      ClaimModel(
        id: 'needs-approval',
        employeeUuid: 'staff-employee-uuid',
        employeeImmediateSupervisor: 'manager-user-uuid',
        title: 'Transport',
        amount: 100000,
        date: DateTime(2026, 5, 4),
        status: 'submitted',
        type: 'transport',
        claimType: 'expense',
        description: '',
      ),
      ClaimModel(
        id: 'own-claim',
        employeeUuid: 'manager-employee-uuid',
        employeeImmediateSupervisor: 'manager-user-uuid',
        title: 'Own',
        amount: 50000,
        date: DateTime(2026, 5, 4),
        status: 'submitted',
        type: 'meal',
        claimType: 'expense',
        description: '',
      ),
      ClaimModel(
        id: 'approved',
        employeeUuid: 'staff-employee-uuid',
        employeeImmediateSupervisor: 'manager-user-uuid',
        title: 'Approved',
        amount: 75000,
        date: DateTime(2026, 5, 4),
        status: 'approved',
        type: 'meal',
        claimType: 'expense',
        description: '',
      ),
    ];

    final pendingClaims = pendingClaimApprovalsForUser(claims, currentUser);

    expect(pendingClaims.map((item) => item.id), ['needs-approval']);
  });

  test('counts only pending overtime maps that need current user approval', () {
    final currentUser = user();
    final overtimeRows = [
      {
        'id': 1,
        'status': 'pending',
        'employee': {
          'uuid': 'staff-employee-uuid',
          'immediate_supervisor': 'manager-user-uuid',
        },
      },
      {
        'id': 2,
        'status': 'submitted',
        'employee_uuid': 'manager-employee-uuid',
        'employee_immediate_supervisor': 'manager-user-uuid',
      },
      {
        'id': 3,
        'status': 'approved',
        'employee': {
          'uuid': 'staff-employee-uuid',
          'immediate_supervisor': 'manager-user-uuid',
        },
      },
    ];

    final pendingOvertime = pendingOvertimeApprovalCountForUser(
      overtimeRows,
      currentUser,
    );

    expect(pendingOvertime, 1);
  });
}
