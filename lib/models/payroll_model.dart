class Payslip {
  final String id;
  final String month;
  final String year;
  final double basicSalary;
  final double allowances;
  final double deductions;
  final double netSalary;
  final String status;
  final DateTime generatedAt;
  final Map<String, double> earningsDetail;
  final Map<String, double> deductionsDetail;

  Payslip({
    required this.id,
    required this.month,
    required this.year,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    required this.netSalary,
    required this.status,
    required this.generatedAt,
    required this.earningsDetail,
    required this.deductionsDetail,
  });

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      id: json['id'] ?? '',
      month: json['month'] ?? '',
      year: json['year'] ?? '',
      basicSalary: (json['basic_salary'] ?? 0).toDouble(),
      allowances: (json['allowances'] ?? 0).toDouble(),
      deductions: (json['deductions'] ?? 0).toDouble(),
      netSalary: (json['net_salary'] ?? 0).toDouble(),
      status: json['status'] ?? 'Draft',
      generatedAt: DateTime.parse(json['generated_at']),
      earningsDetail: Map<String, double>.from(json['earnings_detail'] ?? {}),
      deductionsDetail: Map<String, double>.from(json['deductions_detail'] ?? {}),
    );
  }
}
