import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/recruitment_operations_model.dart';
import 'package:hris_mobile/providers/language_provider.dart';
import 'package:hris_mobile/providers/recruitment_operations_provider.dart';
import 'package:hris_mobile/screens/recruitment/recruitment_operations_screen.dart';
import 'package:provider/provider.dart';

class _FakeRecruitmentOperationsProvider extends RecruitmentOperationsProvider {
  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  List<RecruitmentOpsApplicationOption> get applications => [
    RecruitmentOpsApplicationOption(
      id: 1,
      name: 'Andi Saputra',
      positionName: 'Mobile Engineer',
    ),
  ];

  @override
  List<RecruitmentOpsInterviewerOption> get interviewers => [
    RecruitmentOpsInterviewerOption(id: 7, name: 'Budi Interviewer'),
  ];

  @override
  List<InterviewSchedule> get schedules => [
    InterviewSchedule(
      id: 10,
      applicationId: 1,
      interviewType: 'screening',
      scheduledAt: '2026-05-10T09:00:00',
      status: 'scheduled',
      application: applications.first,
      interviewer: interviewers.first,
    ),
  ];

  @override
  List<JobOffer> get offers => [
    JobOffer(
      id: 20,
      applicationId: 1,
      offeredPosition: 'Mobile Engineer',
      proposedSalary: 12000000,
      startDate: '2026-06-01',
      offerStatus: 'draft',
      application: applications.first,
    ),
  ];

  @override
  Future<void> loadData() async {}
}

void main() {
  test('parses recruitment operations payload from frontend endpoint', () {
    final data = RecruitmentOperationsData.fromJson({
      'applications': [
        {
          'id': 1,
          'name': 'Andi Saputra',
          'status': 'screening',
          'position': {'nama_jabatan': 'Mobile Engineer'},
        },
      ],
      'interviewers': [
        {'id': 7, 'name': 'Budi Interviewer'},
      ],
      'schedules': [
        {
          'id': 10,
          'application_id': 1,
          'interview_type': 'screening',
          'scheduled_at': '2026-05-10T09:00:00',
          'status': 'scheduled',
          'application': {
            'id': 1,
            'name': 'Andi Saputra',
            'position': {'nama_jabatan': 'Mobile Engineer'},
          },
          'interviewer': {'id': 7, 'name': 'Budi Interviewer'},
          'feedback': {
            'id': 99,
            'rating': 4,
            'recommendation': 'yes',
            'summary': 'Good fit',
          },
        },
      ],
      'offers': [
        {
          'id': 20,
          'application_id': 1,
          'offered_position': 'Mobile Engineer',
          'proposed_salary': 12000000,
          'start_date': '2026-06-01',
          'offer_status': 'draft',
        },
      ],
    });

    expect(data.applications.single.positionName, 'Mobile Engineer');
    expect(data.schedules.single.feedback?.rating, 4);
    expect(data.offers.single.proposedSalary, 12000000);
  });

  testWidgets('shows recruitment operations sections like frontend', (
    tester,
  ) async {
    final languageProvider = LanguageProvider(loadOnInit: false);
    await languageProvider.setLanguageCode('en', persist: false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
          ),
          ChangeNotifierProvider<RecruitmentOperationsProvider>(
            create: (_) => _FakeRecruitmentOperationsProvider(),
          ),
        ],
        child: const MaterialApp(home: RecruitmentOperationsScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Recruitment Operations'), findsWidgets);
    expect(find.text('Scheduling'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('Offers'), findsOneWidget);
    expect(find.text('Interview Schedule'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pump();

    expect(find.text('Interview Register'), findsOneWidget);
  });
}
