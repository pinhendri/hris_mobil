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

  ShapeBorder _cardShape(BuildContext context) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: _borderColor(context)),
  );

  int _pipelineColumnCount(double width) {
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

  void _showAddJobDialog(BuildContext context, RecruitmentProvider provider) {
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
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedPositionId;
    String? selectedDepartmentId;

    String? selectedFileName;
    File? selectedFile;
    bool isUploading = false;

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
                              trailing: isUploading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
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
                                                  await FilePicker.platform
                                                      .pickFiles(
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
                                                    backgroundColor:
                                                        Colors.green,
                                                    duration: Duration(
                                                      seconds: 1,
                                                    ),
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
                    onPressed: isUploading
                        ? null
                        : () async {
                            if (nameController.text.isEmpty ||
                                emailController.text.isEmpty ||
                                phoneController.text.isEmpty ||
                                selectedDepartmentId == null ||
                                selectedPositionId == null ||
                                selectedFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr(
                                      'recruitment_fill_application_fields',
                                    ),
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

                              final success = await provider
                                  .addApplicationWithCV(
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
                                            context.tr(
                                              'recruitment_unknown_error',
                                            ),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isApplicationsMode
          ? _buildApplicationsTab(provider)
          : _buildRecruitmentPage(provider),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        onPressed: () => isApplicationsMode
            ? _showAddApplicationDialog(context, provider)
            : _showAddJobDialog(context, provider),
      ),
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

                      final actionButton = ElevatedButton.icon(
                        onPressed: () => _showAddJobDialog(context, provider),
                        icon: const Icon(Icons.add),
                        label: Text(context.tr('recruitment_post_job')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      );

                      if (constraints.maxWidth < 420) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleBlock,
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: actionButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: titleBlock),
                          const SizedBox(width: 12),
                          actionButton,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
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
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _pipelineColumnCount(
                            constraints.maxWidth,
                          ),
                          mainAxisExtent: 88,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: provider.pipeline.length,
                        itemBuilder: (context, index) {
                          final stage = provider.pipeline[index];
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(
                                alpha: _isDark(context) ? 0.16 : 0.06,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _borderColor(context)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  stage.stage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _mutedSurfaceColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _borderColor(context)),
                    ),
                    child: Column(
                      children: [
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _metricRow(
                          context.tr('recruitment_avg_time_to_hire'),
                          '${provider.metrics.averageTimeToHire} ${context.tr('recruitment_days')}',
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (provider.metrics.averageTimeToHire / 30)
                              .clamp(0, 1),
                          backgroundColor: _isDark(context)
                              ? const Color(0xFF334155)
                              : Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
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
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.openPositions.length,
                      itemBuilder: (context, index) {
                        final position = provider.openPositions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: _mutedSurfaceColor(context),
                          shape: _cardShape(context),
                          child: ListTile(
                            title: Text(
                              position.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _primaryTextColor(context),
                              ),
                            ),
                            subtitle: Text(
                              provider.getDepartmentName(position.department),
                              style: _bodyStyle(context, size: 12),
                            ),
                            trailing: Chip(
                              label: Text(
                                _urgencyLabel(position.urgency),
                                style: const TextStyle(fontSize: 10),
                              ),
                              backgroundColor: provider
                                  .getUrgencyColor(position.urgency)
                                  .withOpacity(0.2),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
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
                            (application) => _buildRecentApplicationItem(
                              provider,
                              application,
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
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
