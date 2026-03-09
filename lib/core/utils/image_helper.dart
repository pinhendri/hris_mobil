import 'package:flutter/material.dart';

class ImageHelper {
  static const String _baseUrl = 'http://10.0.2.2:8000'; // sesuaikan jika perlu

  /// Mengembalikan ImageProvider untuk avatar
  /// Jika path null atau kosong, pakai default avatar lokal
  static ImageProvider avatar(String? path) {
    if (path == null || path.trim().isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }

    final uri = path.startsWith('http') ? path : '$_baseUrl$path';
    return NetworkImage(uri);
  }
}