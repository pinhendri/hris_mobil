import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_mobile/providers/auth_provider.dart';
import 'package:hris_mobile/providers/language_provider.dart';
import 'package:hris_mobile/providers/theme_provider.dart';
import 'package:hris_mobile/screens/main_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'shows admin tab when role-assigned permissions allow admin menu',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final authProvider = AuthProvider(bootstrapOfflineProfileSync: false);
      addTearDown(authProvider.dispose);

      await authProvider.setUser({
        'id': 1,
        'name': 'Role Assigned User',
        'email': 'role.assigned@example.com',
        'uuid': 'role-assigned-user-uuid',
        'role': 'user',
        'permissions': ['view-permissions'],
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(
              create: (_) => ThemeProvider(loadOnInit: false),
            ),
            ChangeNotifierProvider(
              create: (_) => LanguageProvider(loadOnInit: false),
            ),
          ],
          child: const MaterialApp(home: MainScreen(initialIndex: 3)),
        ),
      );

      expect(find.text('Admin'), findsOneWidget);
    },
  );
}
