import 'package:flutter/material.dart'; 

class NotificationItem {
  final String id;
  final String type;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.message,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'].toString(),
      type: json['type'] ?? 'info',
      message: json['message'] ?? '',
      data: json['data'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      type: type,
      message: message,
      data: data,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  // Helper methods untuk mendapatkan informasi tambahan dari data
  String? get leaveRequestId => data?['leave_request_id']?.toString();
  int? get employeeId => data?['employee_id'];
  String? get startDate => data?['start_date'];
  String? get endDate => data?['end_date'];
  int? get days => data?['days'];
  
  // Format pesan untuk ditampilkan di UI
  String get formattedMessage {
    if (type == 'leave_request') {
      return message;
    } else if (type == 'leave_approved') {
      return '✅ $message';
    } else if (type == 'leave_rejected') {
      return '❌ $message';
    }
    return message;
  }
  
  // Dapatkan icon berdasarkan tipe
  IconData get icon {
    switch (type) {
      case 'leave_request':
        return Icons.event_note;
      case 'leave_approved':
        return Icons.check_circle;
      case 'leave_rejected':
        return Icons.cancel;
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
  
  // Dapatkan warna berdasarkan tipe
  Color get color {
    switch (type) {
      case 'leave_request':
        return Colors.orange;
      case 'leave_approved':
        return Colors.green;
      case 'leave_rejected':
        return Colors.red;
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
  
  // Dapatkan judul berdasarkan tipe
  String get displayTitle {
    switch (type) {
      case 'leave_request':
        return 'Pengajuan Cuti Baru';
      case 'leave_approved':
        return 'Cuti Disetujui';
      case 'leave_rejected':
        return 'Cuti Ditolak';
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
}