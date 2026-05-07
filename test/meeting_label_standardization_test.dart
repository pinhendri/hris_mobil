import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/calendar_event_model.dart';
import 'package:hris_mobile/models/employee_model.dart';
import 'package:hris_mobile/providers/auth_provider.dart';
import 'package:hris_mobile/providers/employee_provider.dart';
import 'package:hris_mobile/providers/event_provider.dart';
import 'package:hris_mobile/providers/language_provider.dart';
import 'package:hris_mobile/screens/admin/add_edit_event_screen.dart';
import 'package:hris_mobile/screens/admin/event_management_screen.dart';
import 'package:provider/provider.dart';

class _FakeEventProvider extends EventProvider {
  _FakeEventProvider({required this.events});

  final List<CalendarEvent> events;

  @override
  bool get isLoading => false;

  @override
  bool get isSubmitting => false;

  @override
  String? get error => null;

  @override
  List<CalendarEvent> get managedEvents => events;

  @override
  Future<void> fetchManagedEvents() async {}
}

class _FakeEmployeeProvider extends EmployeeProvider {
  @override
  List<Employee> get employees => const [];

  @override
  bool get isLoading => false;

  @override
  Future<void> fetchAllEmployees({
    String? search,
    String? department,
    String? companyCode,
  }) async {}
}

Future<void> _pumpWithMeetingProviders(
  WidgetTester tester, {
  required LanguageProvider languageProvider,
  required Widget child,
  List<CalendarEvent> events = const [],
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(bootstrapOfflineProfileSync: false),
        ),
        ChangeNotifierProvider<EventProvider>(
          create: (_) => _FakeEventProvider(events: events),
        ),
        ChangeNotifierProvider<EmployeeProvider>(
          create: (_) => _FakeEmployeeProvider(),
        ),
      ],
      child: MaterialApp(home: child),
    ),
  );

  await tester.pump();
}

CalendarEvent _meeting({bool isCompanyWide = false}) {
  return CalendarEvent(
    id: 1,
    uuid: 'meeting-1',
    title: 'Weekly Payroll Sync',
    description: 'Discuss payroll timeline',
    location: 'Meeting Room A',
    startsAt: DateTime(2026, 5, 10, 9),
    endsAt: null,
    isCompanyWide: isCompanyWide,
    cCode: 'TALENT',
    createdByName: 'HR Admin',
    inviteCount: 3,
    isUserInvited: false,
    invitedEmployees: const [],
  );
}

Future<void> _pumpMeetingScreen(
  WidgetTester tester, {
  required LanguageProvider languageProvider,
  required List<CalendarEvent> events,
}) async {
  await _pumpWithMeetingProviders(
    tester,
    languageProvider: languageProvider,
    events: events,
    child: const EventManagementScreen(),
  );
}

void main() {
  testWidgets('meeting screen uses Indonesian labels when language is id', (
    tester,
  ) async {
    final languageProvider = LanguageProvider(loadOnInit: false);

    await _pumpMeetingScreen(
      tester,
      languageProvider: languageProvider,
      events: const [],
    );

    expect(find.text('Rapat'), findsOneWidget);
    expect(find.text('Buat Rapat'), findsOneWidget);
    expect(
      find.text('Belum ada rapat. Buat rapat pertama Anda.'),
      findsOneWidget,
    );
  });

  testWidgets('meeting screen uses English labels when language is en', (
    tester,
  ) async {
    final languageProvider = LanguageProvider(loadOnInit: false);
    await languageProvider.setLanguageCode('en', persist: false);

    await _pumpMeetingScreen(
      tester,
      languageProvider: languageProvider,
      events: [_meeting()],
    );

    expect(find.text('Meeting'), findsOneWidget);
    expect(find.text('Create Meeting'), findsOneWidget);
    expect(find.text('3 participants'), findsOneWidget);
    expect(find.text('Created by HR Admin'), findsOneWidget);
  });

  testWidgets('create meeting form uses English meeting labels', (
    tester,
  ) async {
    final languageProvider = LanguageProvider(loadOnInit: false);
    await languageProvider.setLanguageCode('en', persist: false);

    await _pumpWithMeetingProviders(
      tester,
      languageProvider: languageProvider,
      child: const AddEditEventScreen(),
    );

    expect(find.text('Create Meeting'), findsWidgets);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Meeting Title'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Message / Agenda'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('End'), findsOneWidget);
    expect(find.text('Company-wide meeting'), findsOneWidget);
    expect(find.text('Search employees to invite'), findsOneWidget);
    expect(find.text('Participants (0)'), findsOneWidget);
    expect(find.text('No employees available to select.'), findsOneWidget);
  });
}
