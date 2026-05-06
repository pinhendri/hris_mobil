import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/services/offline_support.dart';

void main() {
  group('OfflineSupport retry classification', () {
    test('does not treat HTTP errors wrapped as network errors as offline', () {
      expect(
        OfflineSupport.isRetryableSyncError(
          Exception('Network error: Exception: HTTP 403: Forbidden'),
        ),
        isFalse,
      );
      expect(
        OfflineSupport.isRetryableSyncError(
          Exception('Network error: Exception: HTTP 422: Validation failed'),
        ),
        isFalse,
      );
      expect(
        OfflineSupport.isRetryableSyncError(
          Exception('Network error: Exception: HTTP 500: Server error'),
        ),
        isFalse,
      );
    });

    test('still treats real connection failures as offline', () {
      expect(
        OfflineSupport.isRetryableSyncError(
          const SocketException('Failed host lookup'),
        ),
        isTrue,
      );
    });
  });
}
