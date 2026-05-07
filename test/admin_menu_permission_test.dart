import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_mobile/providers/auth_provider.dart';
import 'package:hris_mobile/providers/language_provider.dart';
import 'package:hris_mobile/screens/tabs/admin_tab.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('hides meeting menu without event permission', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final authProvider = AuthProvider();
    await authProvider.setUser({
      'id': 1,
      'name': 'Permission Admin',
      'email': 'admin@example.com',
      'uuid': 'admin-uuid',
      'permissions': ['view-permissions'],
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider(
            create: (_) => LanguageProvider(loadOnInit: false),
          ),
        ],
        child: const MaterialApp(home: AdminTab()),
      ),
    );

    expect(find.text('Rapat'), findsNothing);
  });
}
