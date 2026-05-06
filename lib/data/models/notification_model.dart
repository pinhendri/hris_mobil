import 'dart:convert';
import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String type;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.type,
    required this.message,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    Map<String, dynamic>? parsedData;
    if (rawData is Map<String, dynamic>) {
      parsedData = rawData;
    } else if (rawData is String && rawData.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          parsedData = decoded;
        }
      } catch (_) {
        parsedData = null;
      }
    }

    return NotificationItem(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      message: json['message']?.toString() ?? '',
      data: parsedData,
      createdAt: DateTime.parse(
        json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['is_read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'message': message,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      type: type,
      message: message,
      data: data,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  String? get leaveRequestId => data?['leave_request_id']?.toString();
  String? get taskId => data?['task_id']?.toString();
  String? get claimId => data?['claim_id']?.toString();
  String? get overtimeRequestId => data?['overtime_request_id']?.toString();
  int? get employeeId => data?['employee_id'];
  String? get startDate => data?['start_date'];
  String? get endDate => data?['end_date'];
  int? get days => data?['days'];

  String get formattedMessage {
    switch (type) {
      case 'leave_request':
        return message;
      case 'company_leave':
        return 'Company leave: $message';
      case 'leave_approved':
        return 'Approved: $message';
      case 'leave_rejected':
        return 'Rejected: $message';
      case 'task_assigned':
      case 'task_completed':
      case 'task_status_update':
      case 'claim_request':
      case 'claim_status_update':
      case 'overtime_request':
      case 'overtime_status_update':
        return message;
      default:
        return message;
    }
  }

  IconData get icon {
    switch (type) {
      case 'leave_request':
        return Icons.event_note;
      case 'company_leave':
        return Icons.beach_access;
      case 'leave_approved':
        return Icons.check_circle;
      case 'leave_rejected':
        return Icons.cancel;
      case 'task_assigned':
      case 'task_completed':
      case 'task_status_update':
        return Icons.task_alt_rounded;
      case 'claim_request':
      case 'claim_status_update':
        return Icons.receipt_long_outlined;
      case 'overtime_request':
      case 'overtime_status_update':
        return Icons.more_time_rounded;
      case 'attendance':
        return Icons.access_time;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color get color {
    switch (type) {
      case 'leave_request':
        return Colors.orange;
      case 'company_leave':
        return Colors.blue;
      case 'leave_approved':
        return Colors.green;
      case 'leave_rejected':
        return Colors.red;
      case 'task_assigned':
      case 'task_completed':
      case 'task_status_update':
        return Colors.indigo;
      case 'claim_request':
      case 'claim_status_update':
        return Colors.purple;
      case 'overtime_request':
      case 'overtime_status_update':
        return Colors.deepOrange;
      case 'attendance':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String get displayTitle {
    if (title.isNotEmpty) {
      return title;
    }

    switch (type) {
      case 'leave_request':
        return 'Pengajuan Cuti Baru';
      case 'company_leave':
        return 'Cuti Bersama';
      case 'leave_approved':
        return 'Cuti Disetujui';
      case 'leave_rejected':
        return 'Cuti Ditolak';
      case 'task_assigned':
        return 'Task Baru';
      case 'task_completed':
      case 'task_status_update':
        return 'Update Task';
      case 'claim_request':
        return 'Klaim Biaya Baru';
      case 'claim_status_update':
        return 'Update Klaim Biaya';
      case 'overtime_request':
        return 'Request Lembur Baru';
      case 'overtime_status_update':
        return 'Update Lembur';
      case 'attendance':
        return 'Absensi';
      case 'warning':
        return 'Peringatan';
      case 'error':
        return 'Error';
      default:
        return 'Notifikasi';
    }
  }

  String get targetModule {
    final explicit = data?['target']?.toString().trim().toLowerCase();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    final normalizedType = type.trim().toLowerCase();
    if (normalizedType.contains('task')) {
      return 'task';
    }
    if (normalizedType.contains('claim')) {
      return 'claim';
    }
    if (normalizedType.contains('overtime')) {
      return 'overtime';
    }
    if (normalizedType.contains('leave')) {
      return 'leave';
    }
    return '';
  }
}
