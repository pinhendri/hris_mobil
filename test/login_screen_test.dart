import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/providers/auth_provider.dart';
import 'package:hris_mobile/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('login accepts employee id as the account identifier', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final authProvider = _FakeAuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'EMP001');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('Format email tidak valid'), findsNothing);
    expect(authProvider.lastIdentifier, 'EMP001');
  });
}

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider() : super(bootstrapOfflineProfileSync: false);

  String? lastIdentifier;

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    lastIdentifier = email;
    return {'success': false, 'message': 'Login gagal'};
  }
}
