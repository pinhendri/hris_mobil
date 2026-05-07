import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../models/recruitment_operations_model.dart';
import '../../providers/recruitment_operations_provider.dart';

class RecruitmentOperationsScreen extends StatefulWidget {
  const RecruitmentOperationsScreen({super.key});

  @override
  State<RecruitmentOperationsScreen> createState() =>
      _RecruitmentOperationsScreenState();
}

class _RecruitmentOperationsScreenState
    extends State<RecruitmentOperationsScreen> {
  final _interviewTypeController = TextEditingController(text: 'screening');
  final _scheduledAtController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _locationController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _scheduleNotesController = TextEditingController();
  final _strengthsController = TextEditingController();
  final _concernsController = TextEditingController();
  final _summaryController = TextEditingController();
  final _offeredPositionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _startDateController = TextEditingController();
  final _offerNotesController = TextEditingController();

  int? _scheduleApplicationId;
  int? _scheduleInterviewerId;
  String _scheduleStatus = 'scheduled';
  int? _feedbackScheduleId;
  int _feedbackRating = 3;
  String _feedbackRecommendation = 'hold';
  int? _offerApplicationId;
  String _offerStatus = 'draft';

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _pageColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF101214) : AppColors.background;

  Color _surfaceColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1B1F24) : Colors.white;

  Color _mutedSurfaceColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

  Color _borderColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  Color _primaryTextColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

  Color _secondaryTextColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    final provider = context.read<RecruitmentOperationsProvider>();
    Future.microtask(provider.loadData);
  }

  @override
  void dispose() {
    _interviewTypeController.dispose();
    _scheduledAtController.dispose();
    _durationController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    _scheduleNotesController.dispose();
    _strengthsController.dispose();
    _concernsController.dispose();
    _summaryController.dispose();
    _offeredPositionController.dispose();
    _salaryController.dispose();
    _startDateController.dispose();
    _offerNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _pageColor(context),
        appBar: AppBar(
          title: Text(context.tr('recruitment_ops_page_title')),
          backgroundColor: isDark ? const Color(0xFF1B1F24) : Colors.white,
          foregroundColor: isDark ? Colors.white : const Color(0xFF111827),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: _secondaryTextColor(context),
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: context.tr('recruitment_ops_tab_scheduling')),
              Tab(text: context.tr('recruitment_ops_tab_feedback')),
              Tab(text: context.tr('recruitment_ops_tab_offers')),
            ],
          ),
        ),
        body: Consumer<RecruitmentOperationsProvider>(
          builder: (context, provider, _) {
            final hasData =
                provider.applications.isNotEmpty ||
                provider.schedules.isNotEmpty ||
                provider.offers.isNotEmpty;

            if (provider.isLoading && !hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null && !hasData) {
              return _MessageView(
                icon: Icons.manage_search_outlined,
                title: context.tr('recruitment_ops_page_title'),
                message: provider.error!,
                actionLabel: context.tr('recruitment_ops_retry'),
                onAction: provider.loadData,
              );
            }

            return Column(
              children: [
                _HeaderCard(
                  title: context.tr('recruitment_ops_page_title'),
                  subtitle: context.tr('recruitment_ops_page_subtitle'),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSchedulingTab(provider),
                      _buildFeedbackTab(provider),
                      _buildOffersTab(provider),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSchedulingTab(RecruitmentOperationsProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            icon: Icons.event_available_outlined,
            title: context.tr('recruitment_ops_interview_schedule'),
            child: Column(
              children: [
                _candidateDropdown(
                  value: _scheduleApplicationId,
                  applications: provider.applications,
                  onChanged: (value) =>
                      setState(() => _scheduleApplicationId = value),
                ),
                const SizedBox(height: 12),
                _interviewerDropdown(
                  value: _scheduleInterviewerId,
                  interviewers: provider.interviewers,
                  onChanged: (value) =>
                      setState(() => _scheduleInterviewerId = value),
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _interviewTypeController,
                  label: context.tr('recruitment_ops_interview_type'),
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _scheduledAtController,
                  label: context.tr('recruitment_ops_schedule'),
                  readOnly: true,
                  suffixIcon: Icons.calendar_today_outlined,
                  onTap: _pickScheduleDateTime,
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _durationController,
                  label: context.tr('recruitment_ops_duration_minutes'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _scheduleStatusDropdown(),
                const SizedBox(height: 12),
                _textField(
                  controller: _locationController,
                  label: context.tr('recruitment_ops_location'),
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _meetingLinkController,
                  label: context.tr('recruitment_ops_meeting_link'),
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _scheduleNotesController,
                  label: context.tr('recruitment_ops_notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _primaryButton(
                  icon: Icons.save_outlined,
                  label: context.tr('recruitment_ops_save_schedule'),
                  onPressed: provider.isLoading
                      ? null
                      : () => _saveSchedule(provider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.fact_check_outlined,
            title: context.tr('recruitment_ops_interview_register'),
            child: _buildScheduleRegister(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab(RecruitmentOperationsProvider provider) {
    final feedbackItems = provider.schedules
        .where((item) => item.feedback != null)
        .toList();

    return RefreshIndicator(
      onRefresh: provider.loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            icon: Icons.rate_review_outlined,
            title: context.tr('recruitment_ops_interviewer_feedback'),
            child: Column(
              children: [
                _scheduleDropdown(
                  value: _feedbackScheduleId,
                  schedules: provider.schedules,
                  onChanged: (value) =>
                      setState(() => _feedbackScheduleId = value),
                ),
                const SizedBox(height: 12),
                _ratingDropdown(),
                const SizedBox(height: 12),
                _recommendationDropdown(),
                const SizedBox(height: 12),
                _textField(
                  controller: _strengthsController,
                  label: context.tr('recruitment_ops_strengths'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _concernsController,
                  label: context.tr('recruitment_ops_concerns'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _summaryController,
                  label: context.tr('recruitment_ops_summary'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _primaryButton(
                  icon: Icons.save_outlined,
                  label: context.tr('recruitment_ops_save_feedback'),
                  onPressed: provider.isLoading
                      ? null
                      : () => _saveFeedback(provider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.reviews_outlined,
            title: context.tr('recruitment_ops_feedback_register'),
            child: feedbackItems.isEmpty
                ? _EmptyState(
                    message: context.tr('recruitment_ops_no_feedback'),
                  )
                : Column(
                    children: feedbackItems
                        .map((item) => _FeedbackCard(schedule: item))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersTab(RecruitmentOperationsProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            icon: Icons.local_offer_outlined,
            title: context.tr('recruitment_ops_offer_management'),
            child: Column(
              children: [
                _candidateDropdown(
                  value: _offerApplicationId,
                  applications: provider.applications,
                  onChanged: (value) =>
                      setState(() => _offerApplicationId = value),
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _offeredPositionController,
                  label: context.tr('recruitment_ops_offered_position'),
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _salaryController,
                  label: context.tr('recruitment_ops_proposed_salary'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _startDateController,
                  label: context.tr('recruitment_ops_start_date'),
                  readOnly: true,
                  suffixIcon: Icons.calendar_today_outlined,
                  onTap: _pickStartDate,
                ),
                const SizedBox(height: 12),
                _offerStatusDropdown(),
                const SizedBox(height: 12),
                _textField(
                  controller: _offerNotesController,
                  label: context.tr('recruitment_ops_notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _primaryButton(
                  icon: Icons.save_outlined,
                  label: context.tr('recruitment_ops_save_offer'),
                  onPressed: provider.isLoading
                      ? null
                      : () => _saveOffer(provider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.track_changes_outlined,
            title: context.tr('recruitment_ops_offer_tracker'),
            child: provider.offers.isEmpty
                ? _EmptyState(message: context.tr('recruitment_ops_no_offers'))
                : Column(
                    children: provider.offers
                        .map(
                          (offer) => _OfferCard(
                            offer: offer,
                            onUpdateStatus: () =>
                                _showOfferStatusDialog(provider, offer),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRegister(RecruitmentOperationsProvider provider) {
    if (provider.isLoading && provider.schedules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          context.tr('recruitment_ops_loading_schedules'),
          style: TextStyle(color: _secondaryTextColor(context)),
        ),
      );
    }

    if (provider.schedules.isEmpty) {
      return _EmptyState(message: context.tr('recruitment_ops_no_schedules'));
    }

    return Column(
      children: provider.schedules
          .map(
            (schedule) => _ScheduleCard(
              schedule: schedule,
              onDelete: () => _deleteSchedule(provider, schedule.id),
            ),
          )
          .toList(),
    );
  }

  Widget _candidateDropdown({
    required int? value,
    required List<RecruitmentOpsApplicationOption> applications,
    required ValueChanged<int?> onChanged,
  }) {
    final safeValue = applications.any((item) => item.id == value)
        ? value
        : null;

    return DropdownButtonFormField<int>(
      key: ValueKey('schedule-candidate-$safeValue-${applications.length}'),
      initialValue: safeValue,
      isExpanded: true,
      dropdownColor: _surfaceColor(context),
      style: TextStyle(color: _primaryTextColor(context)),
      decoration: _inputDecoration(
        label: context.tr('recruitment_ops_select_candidate'),
        icon: Icons.person_search_outlined,
      ),
      items: applications.map((item) {
        final position =
            item.positionName ?? context.tr('recruitment_ops_no_position');
        return DropdownMenuItem<int>(
          value: item.id,
          child: Text('$position - ${item.name}'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _interviewerDropdown({
    required int? value,
    required List<RecruitmentOpsInterviewerOption> interviewers,
    required ValueChanged<int?> onChanged,
  }) {
    final safeValue = interviewers.any((item) => item.id == value)
        ? value
        : null;

    return DropdownButtonFormField<int>(
      key: ValueKey('schedule-interviewer-$safeValue-${interviewers.length}'),
      initialValue: safeValue,
      isExpanded: true,
      dropdownColor: _surfaceColor(context),
      style: TextStyle(color: _primaryTextColor(context)),
      decoration: _inputDecoration(
        label: context.tr('recruitment_ops_select_interviewer'),
        icon: Icons.badge_outlined,
      ),
      items: interviewers
          .map(
            (item) =>
                DropdownMenuItem<int>(value: item.id, child: Text(item.name)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _scheduleDropdown({
    required int? value,
    required List<InterviewSchedule> schedules,
    required ValueChanged<int?> onChanged,
  }) {
    final safeValue = schedules.any((item) => item.id == value) ? value : null;

    return DropdownButtonFormField<int>(
      key: ValueKey('feedback-schedule-$safeValue-${schedules.length}'),
      initialValue: safeValue,
      isExpanded: true,
      dropdownColor: _surfaceColor(context),
      style: TextStyle(color: _primaryTextColor(context)),
      decoration: _inputDecoration(
        label: context.tr('recruitment_ops_select_schedule'),
        icon: Icons.event_note_outlined,
      ),
      items: schedules.map((item) {
        final candidate =
            item.application?.name ?? context.tr('recruitment_ops_candidate');
        return DropdownMenuItem<int>(
          value: item.id,
          child: Text('$candidate - ${item.interviewType}'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _scheduleStatusDropdown() {
    const statuses = ['scheduled', 'rescheduled', 'completed', 'cancelled'];

    return DropdownButtonFormField<String>(
      key: ValueKey('schedule-status-$_scheduleStatus'),
      initialValue: _scheduleStatus,
      isExpanded: true,
      dropdownColor: _surfaceColor(context),
      style: TextStyle(color: _primaryTextColor(context)),
      decoration: _inputDecoration(
        label: context.tr('recruitment_ops_status'),
        icon: Icons.flag_outlined,
      ),
      items: statuses
          .map(
            (status) => DropdownMenuItem<String>(
              value: status,
              child: Text(_scheduleStatusLabel(status)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _scheduleStatus = value);
        }
      },
    );
  }

  Widget _ratingDropdown() {
    return DropdownButtonFormField<int>(
      key: ValueKey('feedback-rating-$_feedbackRating'),
      initialValue: _feedbackRating,
      isExpanded: true,
      dropdownColor: _surfaceColor(context),
      style: TextStyle(color: _primaryTextColor(context)),
      decoration: _inputDecoration(
        label: context.tr('recruitment_ops_recommendation'),
        icon: Icons.star_outline,
      ),
      items: List.generate(5, (index) => index + 1)
          .map(
            (rating) => DropdownMenuItem<int>(
              value: rating,
              child: Text(
                context
                    .tr('recruitment_ops_rating')
                    .replaceAll('{value}', rating.toString()),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _feedbackRating = value);
        }
      },
    );
  }

  Widget _recommendationDropdown() {
    const values = ['strong_yes', 'yes', 'hold', 'no'];

    return DropdownButtonFormField<String>(
      key: ValueKey('feedback-recommendation-$_feedbackRecommendation'),
      initialValue: _feedbackRecommendation,
      isExpanded: true,
      dropdownColor: _surfaceColor(context),
      style: TextStyle(color: _primaryTextColor(context)),
      decoration: _inputDecoration(
        label: context.tr('recruitment_ops_recommendation'),
        icon: Icons.thumb_up_alt_outlined,
      ),
      items: values
          .map(
            (value) => DropdownMenuItem<String>(
              value: value,
              child: Text(_recommendationLabel(value)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _feedbackRecommendation = value);
        }
      },
    );
  }

  Widget _offerStatusDropdown() {
    const statuses = ['draft', 'sent', 'accepted', 'rejected', 'withdrawn'];

    return DropdownButtonFormField<String>(
      key: ValueKey('offer-status-$_offerStatus'),
      initialValue: _offerStatus,
      isExpanded: true,
      dropdownColor: _surfaceColor(context),
      style: TextStyle(color: _primaryTextColor(context)),
      decoration: _inputDecoration(
        label: context.tr('recruitment_ops_status'),
        icon: Icons.flag_outlined,
      ),
      items: statuses
          .map(
            (status) => DropdownMenuItem<String>(
              value: status,
              child: Text(_offerStatusLabel(status)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _offerStatus = value);
        }
      },
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    IconData? suffixIcon,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(color: _primaryTextColor(context)),
      cursorColor: AppColors.primary,
      decoration: _inputDecoration(label: label, suffixIcon: suffixIcon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
      filled: true,
      fillColor: _mutedSurfaceColor(context),
      labelStyle: TextStyle(color: _secondaryTextColor(context)),
      prefixIconColor: _secondaryTextColor(context),
      suffixIconColor: _secondaryTextColor(context),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: now,
    );

    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (!mounted || time == null) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    _scheduledAtController.text = DateFormat(
      "yyyy-MM-dd'T'HH:mm",
    ).format(selected);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: now,
    );

    if (!mounted || date == null) return;

    _startDateController.text = DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _saveSchedule(RecruitmentOperationsProvider provider) async {
    if (_scheduleApplicationId == null || _scheduledAtController.text.isEmpty) {
      _showSnack(context.tr('recruitment_ops_schedule_required'), false);
      return;
    }

    final success = await provider.saveSchedule({
      'application_id': _scheduleApplicationId,
      'interviewer_employee_id': _scheduleInterviewerId,
      'interview_type': _interviewTypeController.text.trim(),
      'scheduled_at': _scheduledAtController.text.trim(),
      'duration_minutes': int.tryParse(_durationController.text.trim()) ?? 60,
      'location': _nullIfBlank(_locationController.text),
      'meeting_link': _nullIfBlank(_meetingLinkController.text),
      'status': _scheduleStatus,
      'notes': _nullIfBlank(_scheduleNotesController.text),
    });

    if (!mounted) return;
    _showSnack(
      success
          ? context.tr('recruitment_ops_schedule_saved')
          : provider.error ?? context.tr('generic_error'),
      success,
    );

    if (success) {
      _scheduledAtController.clear();
      _locationController.clear();
      _meetingLinkController.clear();
      _scheduleNotesController.clear();
      setState(() {
        _scheduleApplicationId = null;
        _scheduleInterviewerId = null;
        _scheduleStatus = 'scheduled';
      });
    }
  }

  Future<void> _deleteSchedule(
    RecruitmentOperationsProvider provider,
    int id,
  ) async {
    final success = await provider.deleteSchedule(id);
    if (!mounted) return;
    _showSnack(
      success
          ? context.tr('recruitment_ops_delete_schedule_success')
          : provider.error ?? context.tr('generic_error'),
      success,
    );
  }

  Future<void> _saveFeedback(RecruitmentOperationsProvider provider) async {
    if (_feedbackScheduleId == null) {
      _showSnack(context.tr('recruitment_ops_feedback_required'), false);
      return;
    }

    final success = await provider.saveFeedback({
      'interview_schedule_id': _feedbackScheduleId,
      'rating': _feedbackRating,
      'recommendation': _feedbackRecommendation,
      'strengths': _nullIfBlank(_strengthsController.text),
      'concerns': _nullIfBlank(_concernsController.text),
      'summary': _nullIfBlank(_summaryController.text),
    });

    if (!mounted) return;
    _showSnack(
      success
          ? context.tr('recruitment_ops_feedback_saved')
          : provider.error ?? context.tr('generic_error'),
      success,
    );

    if (success) {
      _strengthsController.clear();
      _concernsController.clear();
      _summaryController.clear();
      setState(() {
        _feedbackScheduleId = null;
        _feedbackRating = 3;
        _feedbackRecommendation = 'hold';
      });
    }
  }

  Future<void> _saveOffer(RecruitmentOperationsProvider provider) async {
    final salary = num.tryParse(_salaryController.text.trim());
    if (_offerApplicationId == null ||
        _offeredPositionController.text.trim().isEmpty ||
        salary == null) {
      _showSnack(context.tr('recruitment_ops_offer_required'), false);
      return;
    }

    final success = await provider.saveOffer({
      'application_id': _offerApplicationId,
      'offered_position': _offeredPositionController.text.trim(),
      'proposed_salary': salary,
      'start_date': _nullIfBlank(_startDateController.text),
      'offer_status': _offerStatus,
      'notes': _nullIfBlank(_offerNotesController.text),
    });

    if (!mounted) return;
    _showSnack(
      success
          ? context.tr('recruitment_ops_offer_saved')
          : provider.error ?? context.tr('generic_error'),
      success,
    );

    if (success) {
      _offeredPositionController.clear();
      _salaryController.clear();
      _startDateController.clear();
      _offerNotesController.clear();
      setState(() {
        _offerApplicationId = null;
        _offerStatus = 'draft';
      });
    }
  }

  Future<void> _showOfferStatusDialog(
    RecruitmentOperationsProvider provider,
    JobOffer offer,
  ) async {
    var selectedStatus = offer.offerStatus.isEmpty
        ? 'draft'
        : offer.offerStatus;
    const statuses = ['draft', 'sent', 'accepted', 'rejected', 'withdrawn'];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              backgroundColor: _surfaceColor(context),
              title: Text(context.tr('recruitment_ops_update_status')),
              content: DropdownButtonFormField<String>(
                key: ValueKey('offer-status-dialog-$selectedStatus'),
                initialValue: statuses.contains(selectedStatus)
                    ? selectedStatus
                    : 'draft',
                isExpanded: true,
                items: statuses
                    .map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(_offerStatusLabel(status)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedStatus = value);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(context.tr('recruitment_cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    final success = await provider.updateOfferStatus(
                      offer.id,
                      selectedStatus,
                    );
                    if (!mounted) return;
                    _showSnack(
                      success
                          ? context.tr('recruitment_ops_offer_status_updated')
                          : provider.error ?? context.tr('generic_error'),
                      success,
                    );
                  },
                  child: Text(context.tr('recruitment_save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnack(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  String _scheduleStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return context.tr('recruitment_ops_status_scheduled');
      case 'rescheduled':
        return context.tr('recruitment_ops_status_rescheduled');
      case 'completed':
        return context.tr('recruitment_ops_status_completed');
      case 'cancelled':
        return context.tr('recruitment_ops_status_cancelled');
      default:
        return status;
    }
  }

  String _offerStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return context.tr('recruitment_ops_draft');
      case 'sent':
        return context.tr('recruitment_ops_sent');
      case 'accepted':
        return context.tr('recruitment_ops_accepted');
      case 'rejected':
        return context.tr('recruitment_status_rejected');
      case 'withdrawn':
        return context.tr('recruitment_ops_withdrawn');
      default:
        return status;
    }
  }

  String _recommendationLabel(String recommendation) {
    switch (recommendation.toLowerCase()) {
      case 'strong_yes':
        return context.tr('recruitment_ops_recommendation_strong_yes');
      case 'yes':
        return context.tr('recruitment_ops_recommendation_yes');
      case 'hold':
        return context.tr('recruitment_ops_recommendation_hold');
      case 'no':
        return context.tr('recruitment_ops_recommendation_no');
      default:
        return recommendation;
    }
  }

  String _formatDateTime(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value.isEmpty ? '-' : value;
    return DateFormat('dd MMM yyyy HH:mm').format(parsed);
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  String _formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    ).format(value);
  }

  String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1F24) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF1B1F24) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.onDelete});

  final InterviewSchedule schedule;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final state = context
        .findAncestorStateOfType<_RecruitmentOperationsScreenState>()!;
    final candidate =
        schedule.application?.name ?? context.tr('recruitment_ops_empty_dash');
    final position =
        schedule.application?.positionName ??
        context.tr('recruitment_ops_empty_dash');
    final interviewer =
        schedule.interviewer?.name ?? context.tr('recruitment_ops_empty_dash');

    return _RegisterCard(
      children: [
        _InfoRow(
          label: context.tr('recruitment_ops_candidate'),
          value: candidate,
        ),
        _InfoRow(
          label: context.tr('recruitment_ops_position'),
          value: position,
        ),
        _InfoRow(
          label: context.tr('recruitment_ops_interviewer'),
          value: interviewer,
        ),
        _InfoRow(
          label: context.tr('recruitment_ops_schedule'),
          value: state._formatDateTime(schedule.scheduledAt),
        ),
        _InfoRow(
          label: context.tr('recruitment_ops_status'),
          value: state._scheduleStatusLabel(schedule.status),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: Text(context.tr('recruitment_ops_delete')),
          ),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.schedule});

  final InterviewSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final feedback = schedule.feedback!;
    final state = context
        .findAncestorStateOfType<_RecruitmentOperationsScreenState>()!;
    return _RegisterCard(
      children: [
        _InfoRow(
          label: context.tr('recruitment_ops_candidate'),
          value:
              schedule.application?.name ??
              context.tr('recruitment_ops_empty_dash'),
        ),
        _InfoRow(
          label: context.tr('recruitment_ops_interview'),
          value: schedule.interviewType,
        ),
        _InfoRow(
          label: context.tr('recruitment_ops_recommendation'),
          value: state._recommendationLabel(feedback.recommendation),
        ),
        _InfoRow(
          label: context.tr('recruitment_ops_summary'),
          value: feedback.summary ?? context.tr('recruitment_ops_empty_dash'),
        ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onUpdateStatus});

  final JobOffer offer;
  final VoidCallback onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final state = context
        .findAncestorStateOfType<_RecruitmentOperationsScreenState>()!;
    return _RegisterCard(
      children: [
        _InfoRow(
          label: context.tr('recruitment_ops_candidate'),
          value:
              offer.application?.name ??
              context.tr('recruitment_ops_empty_dash'),
        ),
        _InfoRow(
          label: context.tr('recruitment_ops_position'),
          value: offer.offeredPosition,
        ),
        _InfoRow(
          label: context.tr('recruitment_ops_salary'),
          value: state._formatCurrency(offer.proposedSalary),
        ),
        _InfoRow(
          label: context.tr('recruitment_ops_start_date'),
          value: state._formatDate(offer.startDate),
        ),
        _InfoRow(
          label: context.tr('recruitment_ops_status'),
          value: state._offerStatusLabel(offer.offerStatus),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: onUpdateStatus,
            icon: const Icon(Icons.edit_outlined),
            label: Text(context.tr('recruitment_ops_update_status')),
          ),
        ),
      ],
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
