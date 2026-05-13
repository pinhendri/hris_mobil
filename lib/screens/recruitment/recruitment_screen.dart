import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/recruitment_provider.dart';
import '../../models/recruitment_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';

enum RecruitmentScreenMode { recruitment, applications }

class RecruitmentScreen extends StatefulWidget {
  const RecruitmentScreen({
    super.key,
    this.mode = RecruitmentScreenMode.recruitment,
  });

  final RecruitmentScreenMode mode;

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  bool _isLoading = true;

  final Map<int, String> _hoveredJobRequirement = {};

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

  TextStyle _titleStyle(BuildContext context, {double size = 16}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.bold,
    color: _primaryTextColor(context),
  );

  TextStyle _bodyStyle(BuildContext context, {double size = 14}) =>
      TextStyle(fontSize: size, color: _secondaryTextColor(context));

  String _replaceToken(String key, String token, Object value) {
    return context.tr(key).replaceAll(token, value.toString());
  }

  bool _useRecruitmentPageForm() => true;

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return context.tr('recruitment_status_applied');
      case 'screening':
        return context.tr('recruitment_status_screening');
      case 'interview':
        return context.tr('recruitment_status_interview');
      case 'offer':
        return context.tr('recruitment_status_offer');
      case 'hired':
        return context.tr('recruitment_status_hired');
      case 'rejected':
        return context.tr('recruitment_status_rejected');
      default:
        return status;
    }
  }

  String _urgencyLabel(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return context.tr('recruitment_urgency_high');
      case 'medium':
        return context.tr('recruitment_urgency_medium');
      case 'low':
        return context.tr('recruitment_urgency_low');
      default:
        return urgency;
    }
  }

  String _jobUrgencyBadgeLabel(String urgency) {
    if (urgency.toLowerCase() == 'high') {
      return context.tr('recruitment_high_priority');
    }
    return _urgencyLabel(urgency);
  }

  ShapeBorder _cardShape(BuildContext context) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: _borderColor(context)),
  );

  int _pipelineColumnCount(double width) {
    if (width >= 720) return 7;
    if (width >= 520) return 5;
    if (width >= 300) return 3;
    return 2;
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: _titleStyle(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _metricRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: _bodyStyle(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: _primaryTextColor(context)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    IconData? icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: _mutedSurfaceColor(context),
      labelStyle: TextStyle(color: _secondaryTextColor(context)),
      hintStyle: TextStyle(color: _secondaryTextColor(context)),
      prefixIconColor: _secondaryTextColor(context),
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

  Theme _dialogTheme(BuildContext context, Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        dialogTheme: DialogThemeData(backgroundColor: _surfaceColor(context)),
        cardColor: _surfaceColor(context),
        colorScheme: Theme.of(context).colorScheme.copyWith(
          surface: _surfaceColor(context),
          onSurface: _primaryTextColor(context),
          primary: AppColors.primary,
        ),
      ),
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    final provider = Provider.of<RecruitmentProvider>(context, listen: false);
    await provider.refreshData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchJobRequirement(int jobId) async {
    if (_hoveredJobRequirement.containsKey(jobId)) return;
    final provider = Provider.of<RecruitmentProvider>(context, listen: false);
    final requirement = await provider.fetchJobRequirement(jobId);
    if (requirement != null && mounted) {
      setState(() {
        _hoveredJobRequirement[jobId] = requirement;
      });
    }
  }

  Future<void> _showJobRequirementDialog(
    RecruitmentProvider provider,
    OpenPosition position,
  ) async {
    if (!_hoveredJobRequirement.containsKey(position.id)) {
      await _fetchJobRequirement(position.id);
    }

    if (!mounted) return;

    final cachedRequirement = _hoveredJobRequirement[position.id]?.trim();
    final requirement = cachedRequirement?.isNotEmpty == true
        ? cachedRequirement!
        : position.requirement.trim().isNotEmpty
        ? position.requirement.trim()
        : '-';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return _dialogTheme(
          context,
          AlertDialog(
            backgroundColor: _surfaceColor(context),
            title: Text(
              context.tr('recruitment_job_requirements'),
              style: _titleStyle(context, size: 20),
            ),
            content: SingleChildScrollView(
              child: Text(
                requirement,
                style: TextStyle(
                  color: _primaryTextColor(context),
                  height: 1.45,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.tr('recruitment_close')),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmCloseJob(
    RecruitmentProvider provider,
    OpenPosition position,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _dialogTheme(
          context,
          AlertDialog(
            backgroundColor: _surfaceColor(context),
            title: Text(
              context.tr('recruitment_close_job'),
              style: _titleStyle(context, size: 20),
            ),
            content: Text(
              position.title,
              style: TextStyle(color: _primaryTextColor(context)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('recruitment_cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.tr('recruitment_close')),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    final success = await provider.closeJob(position.id);
    if (success && mounted) {
      await _loadData();
    }
  }

  void _showAddJobDialog(BuildContext context, RecruitmentProvider provider) {
    if (_useRecruitmentPageForm()) {
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: const _RecruitmentJobFormScreen(),
          ),
        ),
      ).then((saved) async {
        if (saved == true && mounted) {
          await _loadData();
        }
      });
      return;
    }

    String? selectedDepartment;
    String? selectedPositionId;
    String? selectedPositionTitle;
    String selectedUrgency = 'Medium';
    final requirementController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _dialogTheme(
              context,
              AlertDialog(
                backgroundColor: _surfaceColor(context),
                title: Text(
                  context.tr('recruitment_post_job'),
                  style: _titleStyle(context, size: 20),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        dropdownColor: _surfaceColor(context),
                        style: TextStyle(color: _primaryTextColor(context)),
                        iconEnabledColor: _secondaryTextColor(context),
                        decoration: _inputDecoration(
                          context,
                          label: context.tr('recruitment_select_department'),
                        ),
                        items: provider.departments.map((dept) {
                          return DropdownMenuItem(
                            value: dept.id.toString(),
                            child: Text(dept.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDepartment = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        dropdownColor: _surfaceColor(context),
                        style: TextStyle(color: _primaryTextColor(context)),
                        iconEnabledColor: _secondaryTextColor(context),
                        decoration: _inputDecoration(
                          context,
                          label: context.tr('recruitment_select_position'),
                        ),
                        items: provider.positions.map((pos) {
                          return DropdownMenuItem(
                            value: pos.id.toString(),
                            child: Text(pos.namaJabatan),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPositionId = value;
                            final selectedPos = provider.positions.firstWhere(
                              (p) => p.id.toString() == value,
                              orElse: () => Position(id: 0, namaJabatan: ''),
                            );
                            selectedPositionTitle = selectedPos.namaJabatan;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: selectedUrgency,
                        dropdownColor: _surfaceColor(context),
                        style: TextStyle(color: _primaryTextColor(context)),
                        iconEnabledColor: _secondaryTextColor(context),
                        decoration: _inputDecoration(
                          context,
                          label: context.tr('recruitment_select_urgency'),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'High',
                            child: Text(context.tr('recruitment_urgency_high')),
                          ),
                          DropdownMenuItem(
                            value: 'Medium',
                            child: Text(
                              context.tr('recruitment_urgency_medium'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Low',
                            child: Text(context.tr('recruitment_urgency_low')),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedUrgency = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: requirementController,
                        maxLines: 6,
                        style: TextStyle(color: _primaryTextColor(context)),
                        cursorColor: AppColors.primary,
                        decoration: _inputDecoration(
                          context,
                          label: context.tr('recruitment_job_requirements'),
                          hint: context.tr('recruitment_requirement_hint'),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(context.tr('recruitment_cancel')),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedDepartment == null ||
                          selectedPositionId == null ||
                          requirementController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr('recruitment_fill_all_fields'),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(dialogContext);

                      final jobData = {
                        'title': selectedPositionTitle,
                        'position_id': selectedPositionId,
                        'department': selectedDepartment,
                        'urgency': selectedUrgency,
                        'requirement': requirementController.text,
                      };

                      final success = await provider.createJob(jobData);

                      if (success && context.mounted) {
                        await _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr('recruitment_job_posted_success'),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: Text(context.tr('recruitment_save')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddApplicationDialog(
    BuildContext context,
    RecruitmentProvider provider,
  ) {
    if (_useRecruitmentPageForm()) {
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: const _RecruitmentApplicationFormScreen(),
          ),
        ),
      ).then((saved) async {
        if (saved == true && mounted) {
          await _loadData();
        }
      });
      return;
    }

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedPositionId;
    String? selectedDepartmentId;

    String? selectedFileName;
    File? selectedFile;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _dialogTheme(
              context,
              AlertDialog(
                backgroundColor: _surfaceColor(context),
                title: Text(
                  context.tr('recruitment_new_application'),
                  style: _titleStyle(context, size: 20),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        style: TextStyle(color: _primaryTextColor(context)),
                        cursorColor: AppColors.primary,
                        decoration: _inputDecoration(
                          context,
                          label: context.tr('recruitment_full_name'),
                          icon: Icons.person,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: emailController,
                        style: TextStyle(color: _primaryTextColor(context)),
                        cursorColor: AppColors.primary,
                        decoration: _inputDecoration(
                          context,
                          label: context.tr('recruitment_email'),
                          icon: Icons.email,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: phoneController,
                        style: TextStyle(color: _primaryTextColor(context)),
                        cursorColor: AppColors.primary,
                        decoration: _inputDecoration(
                          context,
                          label: context.tr('recruitment_phone'),
                          icon: Icons.phone,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        dropdownColor: _surfaceColor(context),
                        style: TextStyle(color: _primaryTextColor(context)),
                        iconEnabledColor: _secondaryTextColor(context),
                        decoration: _inputDecoration(
                          context,
                          label: context.tr('recruitment_department'),
                          icon: Icons.business,
                        ),
                        items: provider.departments.map((dept) {
                          return DropdownMenuItem(
                            value: dept.id.toString(),
                            child: Text(dept.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDepartmentId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        dropdownColor: _surfaceColor(context),
                        style: TextStyle(color: _primaryTextColor(context)),
                        iconEnabledColor: _secondaryTextColor(context),
                        decoration: _inputDecoration(
                          context,
                          label: context.tr('recruitment_position'),
                          icon: Icons.work,
                        ),
                        items: provider.positions.map((pos) {
                          return DropdownMenuItem(
                            value: pos.id.toString(),
                            child: Text(pos.namaJabatan),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPositionId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: _mutedSurfaceColor(context),
                          border: Border.all(color: _borderColor(context)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.description,
                                color: Colors.blue,
                              ),
                              title: Text(
                                selectedFileName ??
                                    context.tr('recruitment_no_file_selected'),
                                style: TextStyle(
                                  color: selectedFileName != null
                                      ? _primaryTextColor(context)
                                      : _secondaryTextColor(context),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selectedFileName != null)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selectedFileName = null;
                                          selectedFile = null;
                                        });
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.upload_file,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () async {
                                      try {
                                        FilePickerResult? result =
                                            await FilePicker.platform.pickFiles(
                                              type: FileType.custom,
                                              allowedExtensions: [
                                                'pdf',
                                                'doc',
                                                'docx',
                                              ],
                                              allowMultiple: false,
                                            );

                                        if (result != null) {
                                          setState(() {
                                            selectedFileName =
                                                result.files.single.name;
                                            selectedFile = File(
                                              result.files.single.path!,
                                            );
                                          });

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                context.tr(
                                                  'recruitment_file_selected_success',
                                                ),
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              _replaceToken(
                                                'recruitment_file_select_error',
                                                '{error}',
                                                e,
                                              ),
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 0, color: _borderColor(context)),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                context.tr('recruitment_supported_formats'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _secondaryTextColor(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(context.tr('recruitment_cancel')),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty ||
                          emailController.text.isEmpty ||
                          phoneController.text.isEmpty ||
                          selectedDepartmentId == null ||
                          selectedPositionId == null ||
                          selectedFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr('recruitment_fill_application_fields'),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // TUTUP DIALOG APLIKASI
                      Navigator.pop(dialogContext);

                      // TAMPILKAN LOADING DIALOG
                      BuildContext? loadingContext;
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) {
                          loadingContext = ctx;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );

                      try {
                        final applicationData = {
                          'name': nameController.text,
                          'email': emailController.text,
                          'phone': phoneController.text,
                          'department_id': selectedDepartmentId,
                          'position_id': selectedPositionId,
                        };

                        final success = await provider.addApplicationWithCV(
                          applicationData,
                          selectedFile!,
                        );

                        // TUTUP LOADING DIALOG
                        if (loadingContext != null && mounted) {
                          if (Navigator.canPop(loadingContext!)) {
                            Navigator.pop(loadingContext!);
                          }
                        }

                        if (success && mounted) {
                          await _loadData();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr(
                                  'recruitment_application_submitted_success',
                                ),
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _replaceToken(
                                  'recruitment_failed',
                                  '{error}',
                                  provider.error ??
                                      context.tr('recruitment_unknown_error'),
                                ),
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } catch (e) {
                        // TUTUP LOADING DIALOG KALAU ERROR
                        if (loadingContext != null && mounted) {
                          if (Navigator.canPop(loadingContext!)) {
                            Navigator.pop(loadingContext!);
                          }
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _replaceToken(
                                  'recruitment_error',
                                  '{error}',
                                  e,
                                ),
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(context.tr('recruitment_submit')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStatusDialog(
    BuildContext context,
    RecruitmentProvider provider,
    Application app,
  ) {
    final statuses = [
      'Applied',
      'Screening',
      'Interview',
      'Offer',
      'Hired',
      'Rejected',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return _dialogTheme(
          context,
          AlertDialog(
            backgroundColor: _surfaceColor(context),
            title: Text(
              context.tr('recruitment_update_status'),
              style: _titleStyle(context, size: 20),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: statuses.length,
                itemBuilder: (context, index) {
                  final status = statuses[index];
                  return ListTile(
                    title: Text(
                      _statusLabel(status),
                      style: TextStyle(color: _primaryTextColor(context)),
                    ),
                    leading: Icon(
                      status == app.status
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: status == app.status
                          ? AppColors.primary
                          : _secondaryTextColor(context),
                    ),
                    onTap: () async {
                      Navigator.pop(dialogContext);

                      // Tampilkan loading
                      BuildContext? loadingContext;
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) {
                          loadingContext = ctx;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );

                      try {
                        final success = await provider.updateApplicationStatus(
                          app.id,
                          status,
                        );

                        // Tutup loading
                        if (loadingContext != null && mounted) {
                          if (Navigator.canPop(loadingContext!)) {
                            Navigator.pop(loadingContext!);
                          }
                        }

                        if (success && mounted) {
                          await _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _replaceToken(
                                  'recruitment_status_updated',
                                  '{status}',
                                  _statusLabel(status),
                                ),
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (loadingContext != null && mounted) {
                          if (Navigator.canPop(loadingContext!)) {
                            Navigator.pop(loadingContext!);
                          }
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _replaceToken(
                                  'recruitment_error',
                                  '{error}',
                                  e,
                                ),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.tr('recruitment_cancel')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCVPreview(BuildContext context, String? cvUrl) {
    if (cvUrl == null || cvUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('recruitment_cv_unavailable'))),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return _dialogTheme(
          context,
          AlertDialog(
            backgroundColor: _surfaceColor(context),
            title: Text(
              context.tr('recruitment_cv_document'),
              style: _titleStyle(context, size: 20),
            ),
            content: SizedBox(
              width: 400,
              height: 500,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('recruitment_cv_available'),
                      style: TextStyle(color: _primaryTextColor(context)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr('recruitment_download_started'),
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.download),
                      label: Text(context.tr('recruitment_download_cv')),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('recruitment_close')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RecruitmentProvider>(context);
    final isDark = _isDark(context);
    final isApplicationsMode =
        widget.mode == RecruitmentScreenMode.applications;

    return Scaffold(
      backgroundColor: _pageColor(context),
      appBar: AppBar(
        title: Text(
          context.tr(
            isApplicationsMode
                ? 'feature_label_applications'
                : 'recruitment_page_title',
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1B1F24) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF111827),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => isApplicationsMode
                ? _showAddApplicationDialog(context, provider)
                : _showAddJobDialog(context, provider),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isApplicationsMode
          ? _buildApplicationsTab(provider)
          : _buildRecruitmentPage(provider),
    );
  }

  Widget _buildRecruitmentPage(RecruitmentProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            color: _surfaceColor(context),
            shape: _cardShape(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final titleBlock = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('recruitment_pipeline_title'),
                            style: _titleStyle(context, size: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('recruitment_pipeline_subtitle'),
                            style: _bodyStyle(context),
                          ),
                        ],
                      );

                      if (constraints.maxWidth < 420) {
                        return titleBlock;
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [Expanded(child: titleBlock)],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildOpenPositionsSection(provider),
          const SizedBox(height: 16),

          _buildPipelineSection(provider),
          const SizedBox(height: 16),

          _buildRecentApplicationsSection(provider),
        ],
      ),
    );
  }

  Widget _buildOpenPositionsSection(RecruitmentProvider provider) {
    return Card(
      elevation: 2,
      color: _surfaceColor(context),
      shape: _cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              Icons.work,
              context.tr('recruitment_open_positions'),
            ),
            const SizedBox(height: 16),
            if (provider.openPositions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.tr('recruitment_no_open_positions'),
                    style: _bodyStyle(context),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.openPositions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _buildOpenPositionCard(
                    provider,
                    provider.openPositions[index],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenPositionCard(
    RecruitmentProvider provider,
    OpenPosition position,
  ) {
    final urgencyColor = provider.getUrgencyColor(position.urgency);
    final dateText = position.datePosted.trim().isEmpty
        ? '-'
        : position.datePosted.trim();
    final isClosed = position.status.toLowerCase() == 'closed';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _mutedSurfaceColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _primaryTextColor(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  provider.getDepartmentName(position.department),
                  style: _bodyStyle(context, size: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(
                      _jobUrgencyBadgeLabel(position.urgency),
                      style: TextStyle(
                        fontSize: 11,
                        color: urgencyColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    backgroundColor: urgencyColor.withValues(alpha: 0.12),
                    side: BorderSide(
                      color: urgencyColor.withValues(alpha: 0.3),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateText,
                style: _bodyStyle(context, size: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: context.tr('recruitment_view_job_requirements'),
                    icon: Icon(
                      Icons.visibility_outlined,
                      color: AppColors.primary,
                    ),
                    onPressed: () =>
                        _showJobRequirementDialog(provider, position),
                  ),
                  if (!isClosed)
                    IconButton(
                      tooltip: context.tr('recruitment_close_job'),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      onPressed: () => _confirmCloseJob(provider, position),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineSection(RecruitmentProvider provider) {
    return Card(
      elevation: 2,
      color: _surfaceColor(context),
      shape: _cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              Icons.timeline,
              context.tr('recruitment_candidate_pipeline'),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = _pipelineColumnCount(constraints.maxWidth);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: columns >= 5 ? 184 : 168,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: provider.pipeline.length,
                  itemBuilder: (context, index) {
                    return _buildPipelineStageCard(provider.pipeline[index]);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            _buildPipelineHealthPanel(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineStageCard(PipelineStage stage) {
    final candidates = stage.candidates.take(2).toList(growable: false);
    final hiddenCount = stage.candidates.length - candidates.length;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: _isDark(context) ? 0.16 : 0.06,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Column(
        children: [
          Text(
            stage.stage,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${stage.count}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: candidates.isEmpty
                ? Center(
                    child: Text(
                      _replaceToken(
                        'recruitment_candidate_count',
                        '{count}',
                        stage.count,
                      ),
                      textAlign: TextAlign.center,
                      style: _bodyStyle(context, size: 11),
                    ),
                  )
                : Column(
                    children: [
                      for (final candidate in candidates)
                        _buildPipelineCandidateTile(candidate),
                      if (hiddenCount > 0)
                        Text(
                          _replaceToken(
                            'recruitment_candidate_count',
                            '{count}',
                            '+$hiddenCount',
                          ),
                          style: _bodyStyle(context, size: 10),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineCandidateTile(Candidate candidate) {
    final initials = candidate.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _isDark(context)
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary.withValues(alpha: 0.16),
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryTextColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  candidate.position ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bodyStyle(context, size: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineHealthPanel(RecruitmentProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _mutedSurfaceColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('recruitment_pipeline_health'),
            style: TextStyle(
              color: _primaryTextColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _metricRow(
            context.tr('recruitment_conversion_rate'),
            '${provider.metrics.conversionRate}%',
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: provider.metrics.conversionRate / 100,
            backgroundColor: _isDark(context)
                ? const Color(0xFF334155)
                : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 8),
          _metricRow(
            context.tr('recruitment_avg_time_to_hire'),
            '${provider.metrics.averageTimeToHire} ${context.tr('recruitment_days')}',
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (provider.metrics.averageTimeToHire / 30).clamp(0, 1),
            backgroundColor: _isDark(context)
                ? const Color(0xFF334155)
                : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentApplicationsSection(RecruitmentProvider provider) {
    return Card(
      elevation: 2,
      color: _surfaceColor(context),
      shape: _cardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              Icons.assignment_ind_outlined,
              context.tr('recruitment_recent_applications'),
            ),
            const SizedBox(height: 16),
            if (provider.applications.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.tr('recruitment_no_applications'),
                    style: _bodyStyle(context),
                  ),
                ),
              )
            else
              Column(
                children: provider.applications
                    .take(5)
                    .map(
                      (application) =>
                          _buildRecentApplicationItem(provider, application),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentApplicationItem(
    RecruitmentProvider provider,
    Application application,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _mutedSurfaceColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(
              alpha: _isDark(context) ? 0.22 : 0.10,
            ),
            child: Text(
              application.name.isNotEmpty
                  ? application.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: _isDark(context) ? const Color(0xFF93C5FD) : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  application.positionName ??
                      context.tr('recruitment_position_not_specified'),
                  style: _bodyStyle(context, size: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(
              _statusLabel(application.status),
              style: const TextStyle(fontSize: 11),
            ),
            backgroundColor: provider
                .getStatusColor(application.status)
                .withValues(alpha: 0.12),
          ),
          if (application.cv != null)
            IconButton(
              icon: Icon(Icons.visibility, color: Colors.blue[300]),
              onPressed: () => _showCVPreview(context, application.cv),
              tooltip: context.tr('recruitment_view_cv'),
            ),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab(RecruitmentProvider provider) {
    if (provider.applications.isEmpty) {
      return Center(
        child: Text(
          context.tr('recruitment_no_applications'),
          style: _bodyStyle(context),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.applications.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.people, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  context.tr('recruitment_recent_applications'),
                  style: _titleStyle(context),
                ),
              ],
            ),
          );
        }

        final app = provider.applications[index - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: _surfaceColor(context),
          shape: _cardShape(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: _isDark(context) ? 0.22 : 0.10,
                      ),
                      child: Text(
                        app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDark(context)
                              ? const Color(0xFF93C5FD)
                              : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _primaryTextColor(context),
                            ),
                          ),
                          Text(
                            app.positionName ??
                                context.tr(
                                  'recruitment_position_not_specified',
                                ),
                            style: TextStyle(
                              fontSize: 14,
                              color: _secondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showStatusDialog(context, provider, app),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: provider
                              .getStatusColor(app.status)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: provider
                                .getStatusColor(app.status)
                                .withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _statusLabel(app.status),
                              style: TextStyle(
                                color: provider.getStatusColor(app.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 12,
                              color: provider.getStatusColor(app.status),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 16,
                            color: _secondaryTextColor(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              app.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: _primaryTextColor(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: _secondaryTextColor(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              app.phone,
                              style: TextStyle(
                                fontSize: 13,
                                color: _primaryTextColor(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _secondaryTextColor(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${context.tr('recruitment_applied_prefix')}: ${app.time ?? DateFormat('MMM dd, yyyy').format(DateTime.parse(app.createdAt ?? DateTime.now().toString()))}',
                      style: _bodyStyle(context, size: 12),
                    ),
                    const Spacer(),
                    if (app.cv != null)
                      IconButton(
                        icon: Icon(Icons.visibility, color: Colors.blue[300]),
                        onPressed: () => _showCVPreview(context, app.cv),
                        tooltip: context.tr('recruitment_view_cv'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _RecruitmentJobFormScreen extends StatefulWidget {
  const _RecruitmentJobFormScreen();

  @override
  State<_RecruitmentJobFormScreen> createState() =>
      _RecruitmentJobFormScreenState();
}

class _RecruitmentJobFormScreenState extends State<_RecruitmentJobFormScreen> {
  String? _selectedDepartment;
  String? _selectedPositionId;
  String? _selectedPositionTitle;
  String _selectedUrgency = 'Medium';
  final TextEditingController _requirementController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _requirementController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedDepartment == null ||
        _selectedPositionId == null ||
        _requirementController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('recruitment_fill_all_fields')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<RecruitmentProvider>();
    final success = await provider.createJob({
      'title': _selectedPositionTitle,
      'position_id': _selectedPositionId,
      'department': _selectedDepartment,
      'urgency': _selectedUrgency,
      'requirement': _requirementController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('recruitment_job_posted_success')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.error ?? context.tr('recruitment_unknown_error'),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecruitmentProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1B1F24) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101214) : AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('recruitment_post_job')),
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    context.tr('recruitment_save'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: context.tr('recruitment_select_department'),
                border: const OutlineInputBorder(),
              ),
              items: provider.departments
                  .map(
                    (dept) => DropdownMenuItem(
                      value: dept.id.toString(),
                      child: Text(dept.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedDepartment = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: context.tr('recruitment_select_position'),
                border: const OutlineInputBorder(),
              ),
              items: provider.positions
                  .map(
                    (pos) => DropdownMenuItem(
                      value: pos.id.toString(),
                      child: Text(pos.namaJabatan),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final selected = provider.positions.firstWhere(
                  (position) => position.id.toString() == value,
                  orElse: () => Position(id: 0, namaJabatan: ''),
                );
                setState(() {
                  _selectedPositionId = value;
                  _selectedPositionTitle = selected.namaJabatan;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedUrgency,
              decoration: InputDecoration(
                labelText: context.tr('recruitment_select_urgency'),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'High',
                  child: Text(context.tr('recruitment_urgency_high')),
                ),
                DropdownMenuItem(
                  value: 'Medium',
                  child: Text(context.tr('recruitment_urgency_medium')),
                ),
                DropdownMenuItem(
                  value: 'Low',
                  child: Text(context.tr('recruitment_urgency_low')),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedUrgency = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _requirementController,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: context.tr('recruitment_job_requirements'),
                hintText: context.tr('recruitment_requirement_hint'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecruitmentApplicationFormScreen extends StatefulWidget {
  const _RecruitmentApplicationFormScreen();

  @override
  State<_RecruitmentApplicationFormScreen> createState() =>
      _RecruitmentApplicationFormScreenState();
}

class _RecruitmentApplicationFormScreenState
    extends State<_RecruitmentApplicationFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedDepartmentId;
  String? _selectedPositionId;
  String? _selectedFileName;
  File? _selectedFile;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    setState(() {
      _selectedFileName = result.files.single.name;
      _selectedFile = File(result.files.single.path!);
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _selectedDepartmentId == null ||
        _selectedPositionId == null ||
        _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('recruitment_fill_application_fields')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<RecruitmentProvider>();
    final success = await provider.addApplicationWithCV({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'department_id': _selectedDepartmentId,
      'position_id': _selectedPositionId,
    }, _selectedFile!);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('recruitment_application_submitted_success'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.error ?? context.tr('recruitment_unknown_error'),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecruitmentProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1B1F24) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101214) : AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('recruitment_new_application')),
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    context.tr('recruitment_submit'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.tr('recruitment_full_name'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.tr('recruitment_email'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: context.tr('recruitment_phone'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: context.tr('recruitment_department'),
                border: const OutlineInputBorder(),
              ),
              items: provider.departments
                  .map(
                    (dept) => DropdownMenuItem(
                      value: dept.id.toString(),
                      child: Text(dept.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedDepartmentId = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: context.tr('recruitment_position'),
                border: const OutlineInputBorder(),
              ),
              items: provider.positions
                  .map(
                    (pos) => DropdownMenuItem(
                      value: pos.id.toString(),
                      child: Text(pos.namaJabatan),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedPositionId = value);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(
                _selectedFileName ?? context.tr('recruitment_no_file_selected'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
