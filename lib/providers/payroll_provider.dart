import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/payroll_model.dart';

class PayrollProvider with ChangeNotifier {
  List<Payslip> _payslips = [];
  bool _isLoading = false;

  List<Payslip> get payslips => _payslips;
  bool get isLoading => _isLoading;

  PayrollProvider() {
    _loadMockData();
  }

  Future<void> fetchPayslips() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    _loadMockData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> downloadPayslip(String id) async {
    final payslip = _payslips.firstWhere(
      (p) => p.id == id,
      orElse: () => _payslips.first,
    );
    final pdfDoc = pw.Document();
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    String companyName = 'Your Company';
    final period = '${payslip.month} ${payslip.year}';
    final issuedDate = DateFormat('dd MMM yyyy').format(payslip.generatedAt);
    final gross =
        payslip.basicSalary +
        payslip.allowances +
        (payslip.earningsDetail.values.fold(0.0, (a, b) => a + b)) -
        (payslip.basicSalary + payslip.allowances); // only extras
    final totalEarnings = payslip.basicSalary + payslip.allowances + gross;
    final totalDeductions =
        payslip.deductions +
        payslip.deductionsDetail.values.fold(0.0, (a, b) => a + b);
    final netPay = payslip.netSalary;

    pw.Widget header() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 40,
              height: 40,
              child: pw.Center(
                child: pw.Text('Logo', style: pw.TextStyle(fontSize: 10)),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('Employee Pay Slip', style: pw.TextStyle(fontSize: 12)),
                pw.Text(
                  'Pay Period: $period',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(),
      ],
    );

    pw.Widget employeeInfo() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Employee Information',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          columnWidths: {0: const pw.FixedColumnWidth(120)},
          children: [
            _row('Employee Name', 'N/A'),
            _row('Employee ID / NIP', payslip.id),
            _row('Designation / Job Title', 'N/A'),
            _row('Department', 'N/A'),
            _row('Date of Issue', issuedDate),
          ],
        ),
      ],
    );

    pw.Widget earnings() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Earnings',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
          },
          border: pw.TableBorder.all(width: 0.5),
          children: [
            _row('Basic Salary', currency.format(payslip.basicSalary)),
            _row('Allowances', currency.format(payslip.allowances)),
            ...payslip.earningsDetail.entries.map(
              (e) => _row(e.key, currency.format(e.value)),
            ),
          ],
        ),
      ],
    );

    pw.Widget deductions() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Deductions',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
          },
          border: pw.TableBorder.all(width: 0.5),
          children: [
            _row('Tax', '-'),
            _row('EPF', '-'),
            _row('Insurance', '-'),
            _row('Loans / Advances', '-'),
            ...payslip.deductionsDetail.entries.map(
              (e) => _row(e.key, currency.format(e.value)),
            ),
          ],
        ),
      ],
    );

    pw.Widget netPaySection() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Net Pay', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Table(
          columnWidths: {0: const pw.FixedColumnWidth(150)},
          children: [
            _row('Gross Earnings', currency.format(totalEarnings)),
            _row('Total Deductions', currency.format(totalDeductions)),
            _row('Net Pay', currency.format(netPay)),
          ],
        ),
      ],
    );

    pw.Widget footer() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 8),
        pw.Divider(),
        pw.Text('Payment Method: Bank Transfer'),
        pw.Text('Bank Details: -'),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              children: [
                pw.Text('Signature of Authorizer'),
                pw.SizedBox(height: 40),
                pw.Container(width: 140, child: pw.Divider()),
              ],
            ),
            pw.Column(
              children: [
                pw.Text("Employee's Signature"),
                pw.SizedBox(height: 40),
                pw.Container(width: 140, child: pw.Divider()),
              ],
            ),
          ],
        ),
      ],
    );

    pdfDoc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        build: (context) => [
          header(),
          pw.SizedBox(height: 8),
          employeeInfo(),
          pw.SizedBox(height: 12),
          earnings(),
          pw.SizedBox(height: 12),
          deductions(),
          pw.SizedBox(height: 12),
          netPaySection(),
          pw.SizedBox(height: 12),
          footer(),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/payslips');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final filePath = '${folder.path}/Payslip_${payslip.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdfDoc.save());
  }

  pw.TableRow _row(String left, String right) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(left)),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(right),
          ),
        ),
      ],
    );
  }

  void _loadMockData() {
    _payslips = [
      Payslip(
        id: 'PAY-2024-01',
        month: 'January',
        year: '2024',
        basicSalary: 15000000,
        allowances: 2500000,
        deductions: 500000,
        netSalary: 17000000,
        status: 'Paid',
        generatedAt: DateTime(2024, 1, 25),
        earningsDetail: {
          'Basic Salary': 15000000,
          'Transport Allowance': 1000000,
          'Meal Allowance': 1500000,
        },
        deductionsDetail: {
          'Tax (PPh 21)': 300000,
          'BPJS Kesehatan': 150000,
          'BPJS Ketenagakerjaan': 50000,
        },
      ),
      Payslip(
        id: 'PAY-2023-12',
        month: 'December',
        year: '2023',
        basicSalary: 15000000,
        allowances: 2500000,
        deductions: 500000,
        netSalary: 17000000,
        status: 'Paid',
        generatedAt: DateTime(2023, 12, 25),
        earningsDetail: {
          'Basic Salary': 15000000,
          'Transport Allowance': 1000000,
          'Meal Allowance': 1500000,
        },
        deductionsDetail: {
          'Tax (PPh 21)': 300000,
          'BPJS Kesehatan': 150000,
          'BPJS Ketenagakerjaan': 50000,
        },
      ),
      Payslip(
        id: 'PAY-2023-11',
        month: 'November',
        year: '2023',
        basicSalary: 15000000,
        allowances: 2500000,
        deductions: 500000,
        netSalary: 17000000,
        status: 'Paid',
        generatedAt: DateTime(2023, 11, 25),
        earningsDetail: {
          'Basic Salary': 15000000,
          'Transport Allowance': 1000000,
          'Meal Allowance': 1500000,
        },
        deductionsDetail: {
          'Tax (PPh 21)': 300000,
          'BPJS Kesehatan': 150000,
          'BPJS Ketenagakerjaan': 50000,
        },
      ),
    ];
  }
}
