class Company {
  final int id;
  final String companyName;
  final String cCode;
  final String billingEmail;
  final String status;
  final String subscriptionStatus;

  Company({
    required this.id,
    required this.companyName,
    required this.cCode,
    this.billingEmail = '',
    this.status = '',
    this.subscriptionStatus = '',
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as int? ?? 0,
      companyName: map['company_name'] as String? ?? '',
      cCode: map['c_code'] as String? ?? '',
      billingEmail: map['billing_email']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      subscriptionStatus: map['subscription_status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'c_code': cCode,
      'billing_email': billingEmail,
      'status': status,
      'subscription_status': subscriptionStatus,
    };
  }
}
