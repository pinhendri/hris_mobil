import '../models/leave_model.dart';
import '../models/claim_model.dart';
import '../models/user.dart';

String normalizeLeaveActorId(String? value) {
  return (value ?? '').trim().toLowerCase();
}

bool leaveRequestBelongsToUser(LeaveRequest request, User user) {
  final requestEmployeeUuid = normalizeLeaveActorId(request.uuid);
  final userUuid = normalizeLeaveActorId(user.uuid);
  final userEmployeeUuid = normalizeLeaveActorId(user.employeeUuid);

  return requestEmployeeUuid.isNotEmpty &&
      (requestEmployeeUuid == userUuid ||
          requestEmployeeUuid == userEmployeeUuid);
}

bool leaveRequestNeedsCurrentUserApproval(LeaveRequest request, User user) {
  final status = request.status.trim().toLowerCase();
  final supervisorUuid = normalizeLeaveActorId(request.immediateSupervisor);
  final userUuid = normalizeLeaveActorId(user.uuid);
  final userEmployeeUuid = normalizeLeaveActorId(user.employeeUuid);

  if (status != 'pending' || request.isCompanyLeave) {
    return false;
  }

  if (leaveRequestBelongsToUser(request, user)) {
    return false;
  }

  return supervisorUuid.isNotEmpty &&
      (supervisorUuid == userUuid || supervisorUuid == userEmployeeUuid);
}

List<LeaveRequest> pendingLeaveApprovalsForUser(
  Iterable<LeaveRequest> requests,
  User? user,
) {
  if (user == null) {
    return const [];
  }

  return requests
      .where((request) => leaveRequestNeedsCurrentUserApproval(request, user))
      .toList(growable: false);
}

bool claimBelongsToUser(ClaimModel claim, User user) {
  final claimEmployeeUuid = normalizeLeaveActorId(claim.employeeUuid);
  final userUuid = normalizeLeaveActorId(user.uuid);
  final userEmployeeUuid = normalizeLeaveActorId(user.employeeUuid);

  return claimEmployeeUuid.isNotEmpty &&
      (claimEmployeeUuid == userUuid || claimEmployeeUuid == userEmployeeUuid);
}

bool claimNeedsCurrentUserApproval(ClaimModel claim, User user) {
  final status = claim.status.trim().toLowerCase();
  final supervisorUuid = normalizeLeaveActorId(
    claim.employeeImmediateSupervisor,
  );
  final userUuid = normalizeLeaveActorId(user.uuid);
  final userEmployeeUuid = normalizeLeaveActorId(user.employeeUuid);

  if (status != 'submitted') {
    return false;
  }

  if (claimBelongsToUser(claim, user)) {
    return false;
  }

  if (claim.approverId != null && claim.approverId == user.id) {
    return true;
  }

  return supervisorUuid.isNotEmpty &&
      (supervisorUuid == userUuid || supervisorUuid == userEmployeeUuid);
}

List<ClaimModel> pendingClaimApprovalsForUser(
  Iterable<ClaimModel> claims,
  User? user,
) {
  if (user == null) {
    return const [];
  }

  return claims
      .where((claim) => claimNeedsCurrentUserApproval(claim, user))
      .toList(growable: false);
}

int pendingOvertimeApprovalCountForUser(
  Iterable<Map<String, dynamic>> overtimeRows,
  User? user,
) {
  if (user == null) {
    return 0;
  }

  return overtimeRows
      .where((row) => overtimeRowNeedsCurrentUserApproval(row, user))
      .length;
}

bool overtimeRowNeedsCurrentUserApproval(Map<String, dynamic> row, User user) {
  final status = (row['status'] ?? 'pending').toString().trim().toLowerCase();
  if (status != 'pending' && status != 'submitted') {
    return false;
  }

  final employee = row['employee'] is Map
      ? Map<String, dynamic>.from(row['employee'] as Map)
      : const <String, dynamic>{};
  final approver = row['approver'] is Map
      ? Map<String, dynamic>.from(row['approver'] as Map)
      : const <String, dynamic>{};

  final employeeUuid = normalizeLeaveActorId(
    employee['uuid']?.toString() ?? row['employee_uuid']?.toString(),
  );
  final supervisorUuid = normalizeLeaveActorId(
    employee['immediate_supervisor']?.toString() ??
        row['employee_immediate_supervisor']?.toString(),
  );
  final userUuid = normalizeLeaveActorId(user.uuid);
  final userEmployeeUuid = normalizeLeaveActorId(user.employeeUuid);

  if (employeeUuid.isNotEmpty &&
      (employeeUuid == userUuid || employeeUuid == userEmployeeUuid)) {
    return false;
  }

  final approverId = _parseInt(row['approver_id'] ?? approver['id']);
  if (approverId != null && approverId == user.id) {
    return true;
  }

  return supervisorUuid.isNotEmpty &&
      (supervisorUuid == userUuid || supervisorUuid == userEmployeeUuid);
}

int? _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '');
}
