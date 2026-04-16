import 'package:flutter/material.dart';

import '../constants/api_constants.dart';

class ImageHelper {
  /// Mengembalikan ImageProvider untuk avatar
  /// Jika path null atau kosong, pakai default avatar lokal
  static ImageProvider avatar(String? path) {
    if (path == null || path.trim().isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }

    final uri =
        path.startsWith('http') ? path : '${ApiConstants.baseUrl}$path';
    return NetworkImage(uri);
  }
}
