import 'company.dart';

bool _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().trim().toLowerCase() ?? '';
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

class TrialStatus {
  final String status;
  final bool isTrial;
  final bool isExpired;
  final bool isInGracePeriod;
  final int? daysRemaining;
  final DateTime? trialEndsAt;

  const TrialStatus({
    required this.status,
    required this.isTrial,
    required this.isExpired,
    required this.isInGracePeriod,
    this.daysRemaining,
    this.trialEndsAt,
  });

  factory TrialStatus.fromMap(Map<String, dynamic> map) {
    return TrialStatus(
      status: map['status']?.toString() ?? '',
      isTrial: _toBool(map['is_trial']),
      isExpired: _toBool(map['is_expired']),
      isInGracePeriod: _toBool(map['is_in_grace_period']),
      daysRemaining: int.tryParse((map['days_remaining'] ?? '').toString()),
      trialEndsAt: DateTime.tryParse(map['trial_ends_at']?.toString() ?? ''),
    );
  }
}

class SaasContextSummary {
  final Company? currentCompany;
  final String planName;
  final String subscriptionStatus;
  final String billingEmail;

  const SaasContextSummary({
    this.currentCompany,
    this.planName = '',
    this.subscriptionStatus = '',
    this.billingEmail = '',
  });

  factory SaasContextSummary.fromMap(Map<String, dynamic> map) {
    final companyMap = map['company'];
    final subscriptionMap = map['subscription'];
    final planMap = subscriptionMap is Map<String, dynamic>
        ? subscriptionMap['plan']
        : null;

    return SaasContextSummary(
      currentCompany: companyMap is Map<String, dynamic>
          ? Company.fromMap(companyMap)
          : null,
      planName: planMap is Map<String, dynamic>
          ? planMap['name']?.toString() ?? ''
          : '',
      subscriptionStatus: subscriptionMap is Map<String, dynamic>
          ? subscriptionMap['status']?.toString() ?? ''
          : '',
      billingEmail: companyMap is Map<String, dynamic>
          ? companyMap['billing_email']?.toString() ?? ''
          : '',
    );
  }
}

class SaasInvitation {
  final int id;
  final String email;
  final String name;
  final String role;
  final String status;
  final String authMode;
  final String token;
  final DateTime? expiresAt;

  const SaasInvitation({
    required this.id,
    required this.email,
    this.name = '',
    this.role = '',
    required this.status,
    required this.authMode,
    this.token = '',
    this.expiresAt,
  });

  factory SaasInvitation.fromMap(Map<String, dynamic> map) {
    return SaasInvitation(
      id: map['id'] as int? ?? int.tryParse(map['id']?.toString() ?? '') ?? 0,
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      authMode: map['auth_mode']?.toString() ?? '',
      token: map['token']?.toString() ?? '',
      expiresAt: DateTime.tryParse(map['expires_at']?.toString() ?? ''),
    );
  }
}
