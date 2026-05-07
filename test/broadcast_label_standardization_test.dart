import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/broadcast_models.dart';
import 'package:hris_mobile/providers/auth_provider.dart';
import 'package:hris_mobile/providers/broadcast_provider.dart';
import 'package:hris_mobile/providers/language_provider.dart';
import 'package:hris_mobile/screens/admin/broadcast_screen.dart';
import 'package:provider/provider.dart';

class _FakeBroadcastProvider extends BroadcastProvider {
  @override
  List<BroadcastDepartmentOption> get departments => const [];

  @override
  List<BroadcastEmployeeOption> get employees => const [];

  @override
  List<BroadcastHistoryItem> get history => const [];

  @override
  bool get isLoading => false;

  @override
  bool get isSending => false;

  @override
  bool get companyRequired => false;

  @override
  bool get employeeDirectoryRestricted => false;

  @override
  bool get departmentDirectoryRestricted => false;

  @override
  bool get historyRestricted => false;

  @override
  String? get error => null;

  @override
  Future<void> initialize({bool showLoading = true}) async {}

  @override
  Future<void> refreshHistory() async {}
}

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider() : super(bootstrapOfflineProfileSync: false);

  @override
  bool get canAccessBroadcastModule => true;

  @override
  String getCompanyCode() => 'TALENT';
}

void main() {
  testWidgets('broadcast screen uses Indonesian labels consistently', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final languageProvider = LanguageProvider(loadOnInit: false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
          ),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => _FakeAuthProvider(),
          ),
          ChangeNotifierProvider<BroadcastProvider>(
            create: (_) => _FakeBroadcastProvider(),
          ),
        ],
        child: const MaterialApp(home: BroadcastScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Pengumuman'), findsOneWidget);
    expect(find.text('Buat'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Pesan Pengumuman'), findsOneWidget);
    expect(find.text('Broadcast'), findsNothing);
    expect(find.text('Broadcast Message'), findsNothing);
    expect(find.text('Send Broadcast'), findsNothing);
    expect(find.text('Kirim Pengumuman'), findsOneWidget);
    expect(find.text('Send Broadcast'), findsNothing);
  });
}
