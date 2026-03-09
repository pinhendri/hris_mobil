import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // Pastikan import ini ada

class Client {
  final String id; // uuid dari backend
  final String name;
  final String? address;
  final String? contactPerson;
  final String? phone;
  final String? pksNumber; // pks_number dari backend
  final DateTime? contractStart;
  final DateTime? contractEnd;
  final bool? autoRenew;
  final String? status; // 'active', 'expired', 'pending'
  final String? notes;
  final String? locationMap;
  final int? assignedCount;
  final String? companyCode;

  Client({
    required this.id,
    required this.name,
    this.address,
    this.contactPerson,
    this.phone,
    this.pksNumber,
    this.contractStart,
    this.contractEnd,
    this.autoRenew,
    this.status,
    this.notes,
    this.locationMap,
    this.assignedCount,
    this.companyCode,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['uuid'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      contactPerson: json['contact_person'],
      phone: json['phone'],
      pksNumber: json['pks_number'],
      contractStart: json['contract_start'] != null 
          ? DateTime.parse(json['contract_start']) 
          : null,
      contractEnd: json['contract_end'] != null 
          ? DateTime.parse(json['contract_end']) 
          : null,
      autoRenew: json['auto_renew'],
      status: json['status'],
      notes: json['notes'],
      locationMap: json['location_map'],
      assignedCount: json['assigned_count'],
      companyCode: json['company_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': id,
      'name': name,
      'address': address,
      'contact_person': contactPerson,
      'phone': phone,
      'pks_number': pksNumber,
      'contract_start': contractStart?.toIso8601String(),
      'contract_end': contractEnd?.toIso8601String(),
      'auto_renew': autoRenew,
      'status': status,
      'notes': notes,
      'location_map': locationMap,
      'assigned_count': assignedCount,
      'company_code': companyCode,
    };
  }

  // Helper method untuk mendapatkan warna status
  Color getStatusColor() {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Helper method untuk format tanggal kontrak
  String getFormattedContractPeriod() {
    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      
      String startStr = contractStart != null 
          ? formatter.format(contractStart!)
          : '-';
      String endStr = contractEnd != null 
          ? formatter.format(contractEnd!)
          : '-';
          
      return '$startStr - $endStr';
    } catch (e) {
      // Fallback if date formatting fails
      return '${contractStart?.toString() ?? '-'} - ${contractEnd?.toString() ?? '-'}';
    }
  }

  // Helper method untuk mendapatkan teks status dalam bahasa Indonesia
  String getStatusText() {
    switch (status) {
      case 'active':
        return 'Active';
      case 'expired':
        return 'Expired';
      case 'pending':
        return 'Pending';
      default:
        return 'Unknown';
    }
  }

  // Helper method untuk mendapatkan contract start dalam format string
  String getFormattedContractStart() {
    if (contractStart == null) return '-';
    try {
      return DateFormat('yyyy-MM-dd').format(contractStart!);
    } catch (e) {
      return contractStart!.toString();
    }
  }

  // Helper method untuk mendapatkan contract end dalam format string
  String getFormattedContractEnd() {
    if (contractEnd == null) return '-';
    try {
      return DateFormat('yyyy-MM-dd').format(contractEnd!);
    } catch (e) {
      return contractEnd!.toString();
    }
  }
}