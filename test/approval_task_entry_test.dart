import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hris_mobile/providers/auth_provider.dart';
import 'package:hris_mobile/providers/language_provider.dart';
import 'package:hris_mobile/screens/tabs/approval_tab.dart';
import 'package:hris_mobile/screens/claims/claims_screen.dart';
import 'package:hris_mobile/screens/tasks/tasks_screen.dart';

void main() {
  testWidgets('approval task entry provides TaskProvider to TasksScreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(
            create: (_) => LanguageProvider(loadOnInit: false),
          ),
        ],
        child: const MaterialApp(home: ApprovalTasksScreen()),
      ),
    );

    expect(find.byType(TasksScreen), findsOneWidget);
  });

  testWidgets('approval claims entry provides ClaimProvider to ClaimsScreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: ApprovalClaimsScreen()),
      ),
    );

    expect(find.byType(ClaimsScreen), findsOneWidget);
  });
}
