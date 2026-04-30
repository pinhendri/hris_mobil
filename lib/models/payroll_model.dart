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
      id: _readString(json['id']),
      month: _readString(json['month']),
      year: _readString(json['year']),
      basicSalary: _readDouble(json['basic_salary']),
      allowances: _readDouble(json['allowances']),
      deductions: _readDouble(json['deductions']),
      netSalary: _readDouble(json['net_salary']),
      status: _readString(json['status'], fallback: 'Draft'),
      generatedAt:
          DateTime.tryParse(_readString(json['generated_at'])) ??
          DateTime.now(),
      earningsDetail: _readAmountMap(json['earnings_detail']),
      deductionsDetail: _readAmountMap(json['deductions_detail']),
    );
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_readString(value).replaceAll(',', '')) ?? 0;
  }

  static Map<String, double> _readAmountMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, amount) => MapEntry(_readString(key), _readDouble(amount)),
    )..removeWhere((key, _) => key.isEmpty);
  }
}
