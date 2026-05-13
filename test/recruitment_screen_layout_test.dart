import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/localization/app_strings.dart';
import 'package:hris_mobile/models/recruitment_model.dart';
import 'package:hris_mobile/providers/language_provider.dart';
import 'package:hris_mobile/providers/recruitment_provider.dart';
import 'package:hris_mobile/screens/recruitment/recruitment_screen.dart';
import 'package:provider/provider.dart';

class _FakeRecruitmentProvider extends RecruitmentProvider {
  @override
  List<PipelineStage> get pipeline => [
    PipelineStage(
      stage: 'Applied',
      count: 12,
      candidates: [
        Candidate(name: 'Ari Saputra', position: 'Mobile Candidate'),
      ],
    ),
    PipelineStage(stage: 'Screening', count: 8),
    PipelineStage(stage: 'Interview', count: 5),
    PipelineStage(stage: 'Offer', count: 2),
    PipelineStage(stage: 'Hired', count: 1),
    PipelineStage(stage: 'Rejected', count: 0),
    PipelineStage(stage: 'Withdrawn', count: 1),
  ];

  @override
  RecruitmentMetrics get metrics =>
      RecruitmentMetrics(conversionRate: 42, averageTimeToHire: 14);

  @override
  List<OpenPosition> get openPositions => [
    OpenPosition(
      id: 7,
      title: 'Senior Flutter Engineer',
      positionId: '42',
      department: '3',
      applicants: 5,
      status: 'Active',
      urgency: 'High',
      requirement: 'Build mobile HR workflows',
      datePosted: '2026-05-08',
    ),
  ];

  @override
  List<Application> get applications => [];

  @override
  Future<void> refreshData() async {}

  @override
  String getDepartmentName(String? departmentId) {
    return departmentId == '3'
        ? 'Engineering'
        : super.getDepartmentName(departmentId);
  }

  @override
  Future<String?> fetchJobRequirement(int jobId) async {
    return 'Build mobile HR workflows';
  }

  @override
  Future<bool> closeJob(int jobId) async => true;
}

void main() {
  testWidgets('recruitment feature menu follows frontend recruitment page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final languageProvider = LanguageProvider(loadOnInit: false);
    await languageProvider.setLanguageCode('en', persist: false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
          ),
          ChangeNotifierProvider<RecruitmentProvider>(
            create: (_) => _FakeRecruitmentProvider(),
          ),
        ],
        child: const MaterialApp(home: RecruitmentScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Recruitment Pipeline'), findsOneWidget);
    expect(find.text('Post New Job'), findsOneWidget);
    expect(find.text('Applications'), findsNothing);
    expect(find.text('Add Application'), findsNothing);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pump();

    expect(find.text('Recent Applications'), findsOneWidget);
  });

  testWidgets('open positions show frontend job posting details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final languageProvider = LanguageProvider(loadOnInit: false);
    await languageProvider.setLanguageCode('en', persist: false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
          ),
          ChangeNotifierProvider<RecruitmentProvider>(
            create: (_) => _FakeRecruitmentProvider(),
          ),
        ],
        child: const MaterialApp(home: RecruitmentScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Open Positions'), findsOneWidget);
    expect(find.text('Senior Flutter Engineer'), findsOneWidget);
    expect(find.text('Engineering'), findsOneWidget);
    expect(find.text('High Priority'), findsOneWidget);
    expect(find.text('2026-05-08'), findsOneWidget);
    expect(find.byTooltip('View job requirements'), findsOneWidget);
    expect(find.byTooltip('Close job'), findsOneWidget);

    await tester.tap(find.byTooltip('View job requirements'));
    await tester.pumpAndSettle();

    expect(find.text('Job Requirements'), findsOneWidget);
    expect(find.text('Build mobile HR workflows'), findsOneWidget);
  });

  testWidgets('candidate pipeline mirrors frontend stage information', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final languageProvider = LanguageProvider(loadOnInit: false);
    await languageProvider.setLanguageCode('en', persist: false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
          ),
          ChangeNotifierProvider<RecruitmentProvider>(
            create: (_) => _FakeRecruitmentProvider(),
          ),
        ],
        child: const MaterialApp(home: RecruitmentScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -420));
    await tester.pump();

    expect(find.text('Candidate Pipeline'), findsOneWidget);
    expect(find.text('Applied'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Withdrawn'), findsOneWidget);
    expect(find.text('Ari Saputra'), findsOneWidget);
    expect(find.text('Mobile Candidate'), findsOneWidget);
    expect(find.text('8 candidate(s)'), findsOneWidget);
    expect(find.text('1 candidate(s)'), findsWidgets);
    expect(find.text('Overall Pipeline Health'), findsOneWidget);
    expect(find.text('Conversion Rate'), findsOneWidget);
    expect(find.text('42.0%'), findsOneWidget);
    expect(find.text('Avg Time to Hire'), findsOneWidget);
    expect(find.text('14.0 days'), findsOneWidget);
  });

  testWidgets('recruitment pipeline does not overflow on narrow phones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>(
            create: (_) => LanguageProvider(loadOnInit: false),
          ),
          ChangeNotifierProvider<RecruitmentProvider>(
            create: (_) => _FakeRecruitmentProvider(),
          ),
        ],
        child: const MaterialApp(home: RecruitmentScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text(
        AppStrings.of(
          tester.element(find.byType(Scaffold)),
          'recruitment_candidate_pipeline',
          listen: false,
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
