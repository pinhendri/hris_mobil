// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hris_mobile/main.dart';
import 'package:hris_mobile/providers/language_provider.dart';

void main() {
  testWidgets('App boots MaterialApp shell', (WidgetTester tester) async {
    final languageProvider = LanguageProvider(loadOnInit: false);

    await tester.pumpWidget(MyApp(languageProvider: languageProvider));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
