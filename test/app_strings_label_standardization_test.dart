import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/localization/app_strings.dart';
import 'package:hris_mobile/providers/language_provider.dart';
import 'package:provider/provider.dart';

void main() {
  Future<Map<String, String>> lookupLabels(
    WidgetTester tester,
    LanguageProvider languageProvider,
  ) async {
    late Map<String, String> labels;

    await tester.pumpWidget(
      ChangeNotifierProvider<LanguageProvider>.value(
        value: languageProvider,
        child: Builder(
          builder: (context) {
            labels = {
              'event': AppStrings.of(
                context,
                'feature_label_event_management',
                listen: false,
              ),
              'meeting_subtitle': AppStrings.of(
                context,
                'meeting_page_subtitle',
                listen: false,
              ),
              'meeting_create': AppStrings.of(
                context,
                'meeting_create',
                listen: false,
              ),
              'meeting_empty': AppStrings.of(
                context,
                'meeting_empty',
                listen: false,
              ),
              'meeting_invitee_count': AppStrings.of(
                context,
                'meeting_invitee_count',
                listen: false,
              ).replaceAll('{count}', '3'),
              'meeting_form_title': AppStrings.of(
                context,
                'meeting_title_label',
                listen: false,
              ),
              'meeting_search': AppStrings.of(
                context,
                'meeting_search_invitees',
                listen: false,
              ),
              'broadcast': AppStrings.of(
                context,
                'feature_label_broadcast',
                listen: false,
              ),
              'broadcast_title': AppStrings.of(
                context,
                'broadcast_page_title',
                listen: false,
              ),
              'broadcast_compose': AppStrings.of(
                context,
                'broadcast_compose_tab',
                listen: false,
              ),
              'broadcast_send': AppStrings.of(
                context,
                'broadcast_send',
                listen: false,
              ),
              'broadcast_message_title': AppStrings.of(
                context,
                'broadcast_message_title',
                listen: false,
              ),
              'settings': AppStrings.of(
                context,
                'admin_section_configuration',
                listen: false,
              ),
              'settings_hint': AppStrings.of(
                context,
                'feature_admin_submenu_hint',
                listen: false,
              ),
              'tasks': AppStrings.of(
                context,
                'feature_label_tasks',
                listen: false,
              ),
              'task_page_subtitle': AppStrings.of(
                context,
                'task_page_subtitle',
                listen: false,
              ),
              'task_add': AppStrings.of(
                context,
                'task_action_add',
                listen: false,
              ),
              'task_create': AppStrings.of(
                context,
                'task_form_create_title',
                listen: false,
              ),
              'task_self': AppStrings.of(
                context,
                'task_filter_mine',
                listen: false,
              ),
              'task_assignee': AppStrings.of(
                context,
                'task_assignee_label',
                listen: false,
              ),
              'task_empty': AppStrings.of(
                context,
                'task_empty_title',
                listen: false,
              ),
              'task_due': AppStrings.of(
                context,
                'task_due_prefix',
                listen: false,
              ),
              'task_no_due': AppStrings.of(
                context,
                'task_no_due_date',
                listen: false,
              ),
              'recruitment': AppStrings.of(
                context,
                'feature_label_recruitment',
                listen: false,
              ),
              'job_postings': AppStrings.of(
                context,
                'feature_label_job_postings',
                listen: false,
              ),
              'applications': AppStrings.of(
                context,
                'feature_label_applications',
                listen: false,
              ),
              'recruitment_ops': AppStrings.of(
                context,
                'feature_label_recruitment_ops',
                listen: false,
              ),
              'employees_one': AppStrings.of(
                context,
                'feature_label_employee_one',
                listen: false,
              ),
              'leave': AppStrings.of(
                context,
                'feature_label_leave',
                listen: false,
              ),
              'vendor': AppStrings.of(
                context,
                'feature_label_clients',
                listen: false,
              ),
              'correction': AppStrings.of(
                context,
                'feature_label_corrections',
                listen: false,
              ),
              'correction_attendance': AppStrings.of(
                context,
                'correction_attendance',
                listen: false,
              ),
              'kpi_list': AppStrings.of(context, 'kpi_master', listen: false),
              'kpi_evaluation_list': AppStrings.of(
                context,
                'kpi_evaluation_list',
                listen: false,
              ),
              'recruitment_subtitle': AppStrings.of(
                context,
                'recruitment_page_subtitle',
                listen: false,
              ),
              'recruitment_pipeline': AppStrings.of(
                context,
                'recruitment_pipeline_title',
                listen: false,
              ),
              'recruitment_open_positions': AppStrings.of(
                context,
                'recruitment_open_positions',
                listen: false,
              ),
              'recruitment_candidate_pipeline': AppStrings.of(
                context,
                'recruitment_candidate_pipeline',
                listen: false,
              ),
              'recruitment_recent_applications': AppStrings.of(
                context,
                'recruitment_recent_applications',
                listen: false,
              ),
              'recruitment_post_job': AppStrings.of(
                context,
                'recruitment_post_job',
                listen: false,
              ),
              'recruitment_add_application': AppStrings.of(
                context,
                'recruitment_add_application',
                listen: false,
              ),
              'recruitment_new_application': AppStrings.of(
                context,
                'recruitment_new_application',
                listen: false,
              ),
              'recruitment_ops_title': AppStrings.of(
                context,
                'recruitment_ops_page_title',
                listen: false,
              ),
              'recruitment_ops_subtitle': AppStrings.of(
                context,
                'recruitment_ops_page_subtitle',
                listen: false,
              ),
              'recruitment_ops_scheduling': AppStrings.of(
                context,
                'recruitment_ops_tab_scheduling',
                listen: false,
              ),
              'recruitment_ops_feedback': AppStrings.of(
                context,
                'recruitment_ops_tab_feedback',
                listen: false,
              ),
              'recruitment_ops_offers': AppStrings.of(
                context,
                'recruitment_ops_tab_offers',
                listen: false,
              ),
            };
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    return labels;
  }

  testWidgets('Indonesian feature labels match frontend menu naming', (
    tester,
  ) async {
    final languageProvider = LanguageProvider(loadOnInit: false);

    final labels = await lookupLabels(tester, languageProvider);

    expect(labels['event'], 'Rapat');
    expect(
      labels['meeting_subtitle'],
      'Buat undangan rapat dan kelola peserta.',
    );
    expect(labels['meeting_create'], 'Buat Rapat');
    expect(
      labels['meeting_empty'],
      'Belum ada rapat. Buat rapat pertama Anda.',
    );
    expect(labels['meeting_invitee_count'], '3 peserta');
    expect(labels['meeting_form_title'], 'Judul Rapat');
    expect(labels['meeting_search'], 'Cari karyawan untuk diundang');
    expect(labels['broadcast'], 'Pengumuman');
    expect(labels['broadcast_title'], 'Pengumuman');
    expect(labels['broadcast_compose'], 'Buat');
    expect(labels['broadcast_send'], 'Kirim Pengumuman');
    expect(labels['broadcast_message_title'], 'Pesan Pengumuman');
    expect(labels['settings'], 'Pengaturan');
    expect(labels['settings_hint'], 'Pilih menu pengaturan yang ingin dibuka.');
    expect(labels['tasks'], 'Tugas');
    expect(
      labels['task_page_subtitle'],
      'Kelola tugas pribadi dan tugas yang diberikan atasan ke bawahan.',
    );
    expect(labels['task_add'], 'Tambah Tugas');
    expect(labels['task_create'], 'Buat Tugas');
    expect(labels['task_self'], 'Saya');
    expect(labels['task_assignee'], 'Penerima Tugas');
    expect(labels['task_empty'], 'Tidak ada tugas');
    expect(labels['task_due'], 'Tenggat');
    expect(labels['task_no_due'], 'Tidak ada tenggat');
    expect(labels['recruitment'], 'Rekrutmen');
    expect(labels['job_postings'], 'Lowongan');
    expect(labels['applications'], 'Lamaran');
    expect(labels['recruitment_ops'], 'Operasional Rekrutmen');
    expect(labels['employees_one'], 'Karyawan Satu');
    expect(labels['leave'], 'Manajemen Cuti');
    expect(labels['vendor'], 'Manajemen Vendor');
    expect(labels['correction'], 'Koreksi');
    expect(labels['correction_attendance'], 'Koreksi Absensi');
    expect(labels['kpi_list'], 'Daftar KPI');
    expect(labels['kpi_evaluation_list'], 'Daftar Evaluasi');
    expect(
      labels['recruitment_subtitle'],
      'Kelola lowongan pekerjaan dan pantau proses lamaran kandidat.',
    );
    expect(labels['recruitment_pipeline'], 'Pipeline Rekrutmen');
    expect(labels['recruitment_open_positions'], 'Posisi Terbuka');
    expect(labels['recruitment_candidate_pipeline'], 'Pipeline Kandidat');
    expect(labels['recruitment_recent_applications'], 'Lamaran Terbaru');
    expect(labels['recruitment_post_job'], 'Buat Lowongan Baru');
    expect(labels['recruitment_add_application'], 'Tambah Lamaran');
    expect(labels['recruitment_new_application'], 'Lamaran Baru');
    expect(labels['recruitment_ops_title'], 'Operasional Rekrutmen');
    expect(
      labels['recruitment_ops_subtitle'],
      'Penjadwalan interview, feedback interviewer, dan manajemen job offer.',
    );
    expect(labels['recruitment_ops_scheduling'], 'Penjadwalan');
    expect(labels['recruitment_ops_feedback'], 'Feedback');
    expect(labels['recruitment_ops_offers'], 'Penawaran');
  });

  testWidgets('English feature labels match frontend menu naming', (
    tester,
  ) async {
    final languageProvider = LanguageProvider(loadOnInit: false);
    await languageProvider.setLanguageCode('en', persist: false);

    final labels = await lookupLabels(tester, languageProvider);

    expect(labels['event'], 'Meeting');
    expect(
      labels['meeting_subtitle'],
      'Create meeting invitations and manage participants.',
    );
    expect(labels['meeting_create'], 'Create Meeting');
    expect(
      labels['meeting_empty'],
      'No meetings yet. Create your first meeting.',
    );
    expect(labels['meeting_invitee_count'], '3 participants');
    expect(labels['meeting_form_title'], 'Meeting Title');
    expect(labels['meeting_search'], 'Search employees to invite');
    expect(labels['broadcast'], 'Broadcast');
    expect(labels['broadcast_title'], 'Broadcast');
    expect(labels['broadcast_compose'], 'Compose');
    expect(labels['broadcast_send'], 'Send Broadcast');
    expect(labels['broadcast_message_title'], 'Broadcast Message');
    expect(labels['settings'], 'Settings');
    expect(
      labels['settings_hint'],
      'Choose the settings menu you want to open.',
    );
    expect(labels['tasks'], 'Tasks');
    expect(
      labels['task_page_subtitle'],
      'Manage personal tasks and tasks assigned by managers to subordinates.',
    );
    expect(labels['task_add'], 'Add Task');
    expect(labels['task_create'], 'Create Task');
    expect(labels['task_self'], 'Me');
    expect(labels['task_assignee'], 'Task Recipient');
    expect(labels['task_empty'], 'No tasks found');
    expect(labels['task_due'], 'Due');
    expect(labels['task_no_due'], 'No due date');
    expect(labels['recruitment'], 'Recruitment');
    expect(labels['job_postings'], 'Job Postings');
    expect(labels['applications'], 'Applications');
    expect(labels['recruitment_ops'], 'Recruitment Ops');
    expect(labels['employees_one'], 'EmployeesOne');
    expect(labels['leave'], 'Leave Management');
    expect(labels['vendor'], 'Vendor Management');
    expect(labels['correction'], 'Corection');
    expect(labels['correction_attendance'], 'Attendance Corection');
    expect(labels['kpi_list'], 'KPI List');
    expect(labels['kpi_evaluation_list'], 'List Evaluation');
    expect(
      labels['recruitment_subtitle'],
      'Manage job postings and track candidate applications.',
    );
    expect(labels['recruitment_pipeline'], 'Recruitment Pipeline');
    expect(labels['recruitment_open_positions'], 'Open Positions');
    expect(labels['recruitment_candidate_pipeline'], 'Candidate Pipeline');
    expect(labels['recruitment_recent_applications'], 'Recent Applications');
    expect(labels['recruitment_post_job'], 'Post New Job');
    expect(labels['recruitment_add_application'], 'Add Application');
    expect(labels['recruitment_new_application'], 'New Application');
    expect(labels['recruitment_ops_title'], 'Recruitment Operations');
    expect(
      labels['recruitment_ops_subtitle'],
      'Interview scheduling, interviewer feedback, and job offer management.',
    );
    expect(labels['recruitment_ops_scheduling'], 'Scheduling');
    expect(labels['recruitment_ops_feedback'], 'Feedback');
    expect(labels['recruitment_ops_offers'], 'Offers');
  });
}
