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
    PipelineStage(stage: 'Applied', count: 12),
    PipelineStage(stage: 'Screening', count: 8),
    PipelineStage(stage: 'Interview', count: 5),
    PipelineStage(stage: 'Offer', count: 2),
    PipelineStage(stage: 'Hired', count: 1),
  ];

  @override
  RecruitmentMetrics get metrics =>
      RecruitmentMetrics(conversionRate: 42, averageTimeToHire: 14);

  @override
  List<OpenPosition> get openPositions => [];

  @override
  List<Application> get applications => [];

  @override
  Future<void> refreshData() async {}
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
