import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/recruitment_provider.dart';
import '../../models/recruitment_model.dart';
import '../../core/constants/app_colors.dart';

class RecruitmentScreen extends StatefulWidget {
  const RecruitmentScreen({super.key});

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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

  TextStyle _bodyStyle(BuildContext context, {double size = 14}) => TextStyle(
    fontSize: size,
    color: _secondaryTextColor(context),
  );

  ShapeBorder _cardShape(BuildContext context) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: _borderColor(context)),
  );

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: _mutedSurfaceColor(context),
      labelStyle: TextStyle(color: _secondaryTextColor(context)),
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
    _tabController = TabController(length: 2, vsync: this);
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
              title: Text('Post New Job', style: _titleStyle(context, size: 20)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      dropdownColor: _surfaceColor(context),
                      style: TextStyle(color: _primaryTextColor(context)),
                      iconEnabledColor: _secondaryTextColor(context),
                      decoration: _inputDecoration(context, label: 'Select Department'),
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
                      decoration: _inputDecoration(context, label: 'Select Position'),
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
                      decoration: _inputDecoration(context, label: 'Urgency'),
                      items: const [
                        DropdownMenuItem(value: 'High', child: Text('High')),
                        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
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
                        label: 'Job Requirements',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDepartment == null ||
                        selectedPositionId == null ||
                        requirementController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
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
                        const SnackBar(
                          content: Text('Job posted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
            );
          },
        );
      },
    );
  }

  void _showAddApplicationDialog(BuildContext context, RecruitmentProvider provider) {
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
                'New Application',
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
                        label: 'Full Name *',
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
                        label: 'Email *',
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
                        label: 'Phone *',
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
                        label: 'Department *',
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
                        label: 'Position *',
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
                            leading: const Icon(Icons.description, color: Colors.blue),
                            title: Text(
                              selectedFileName ?? 'No file selected',
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
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (selectedFileName != null)
                                        IconButton(
                                          icon: const Icon(Icons.clear, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              selectedFileName = null;
                                              selectedFile = null;
                                            });
                                          },
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.upload_file, color: Colors.blue),
                                        onPressed: () async {
                                          try {
                                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                                              type: FileType.custom,
                                              allowedExtensions: ['pdf', 'doc', 'docx'],
                                              allowMultiple: false,
                                            );

                                            if (result != null) {
                                              setState(() {
                                                selectedFileName = result.files.single.name;
                                                selectedFile = File(result.files.single.path!);
                                              });
                                              
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('File selected successfully'),
                                                  backgroundColor: Colors.green,
                                                  duration: Duration(seconds: 1),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error selecting file: $e'),
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
                              'Supported formats: PDF, DOC, DOCX (Max 2MB)',
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
                  child: const Text('Cancel'),
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
                              const SnackBar(
                                content: Text('Please fill all fields and upload CV'),
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
                              selectedFile!
                            );

                            // TUTUP LOADING DIALOG
                            if (loadingContext != null && mounted) {
                              if (Navigator.canPop(loadingContext!)) {
                                Navigator.pop(loadingContext!);
                              }
                            }

                            if (success && mounted) {
                              await _loadData();
                              _tabController.animateTo(1);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Application submitted successfully'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Failed: ${provider.error ?? 'Unknown error'}'),
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
                                  content: Text('❌ Error: $e'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Submit'),
                ),
              ],
            ),
            );
          },
        );
      },
    );
  }

  void _showStatusDialog(BuildContext context, RecruitmentProvider provider, Application app) {
    final statuses = ['Applied', 'Screening', 'Interview', 'Offer', 'Hired', 'Rejected'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return _dialogTheme(
          context,
          AlertDialog(
          backgroundColor: _surfaceColor(context),
          title: Text('Update Status', style: _titleStyle(context, size: 20)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: statuses.length,
              itemBuilder: (context, index) {
                final status = statuses[index];
                return ListTile(
                  title: Text(
                    status,
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
                      final success = await provider.updateApplicationStatus(app.id, status);

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
                            content: Text('✅ Status updated to $status'),
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
                            content: Text('❌ Error: $e'),
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
              child: const Text('Cancel'),
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
        const SnackBar(content: Text('No CV available')),
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
          title: Text('CV Document', style: _titleStyle(context, size: 20)),
          content: SizedBox(
            width: 400,
            height: 500,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'CV is available for download',
                    style: TextStyle(color: _primaryTextColor(context)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download started')),
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download CV'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
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

    return Scaffold(
      backgroundColor: _pageColor(context),
      appBar: AppBar(
        title: const Text('Recruitment'),
        backgroundColor: isDark ? const Color(0xFF1B1F24) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF111827),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: _secondaryTextColor(context),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pipeline'),
            Tab(text: 'Applications'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPipelineTab(provider),
                _buildApplicationsTab(provider),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: _surfaceColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              side: BorderSide(color: _borderColor(context)),
            ),
            builder: (context) {
              return SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.work, color: AppColors.primary),
                      title: Text(
                        'Post New Job',
                        style: TextStyle(color: _primaryTextColor(context)),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showAddJobDialog(context, provider);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add, color: Colors.green),
                      title: Text(
                        'Add Application',
                        style: TextStyle(color: _primaryTextColor(context)),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showAddApplicationDialog(context, provider);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPipelineTab(RecruitmentProvider provider) {
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
                  Text(
                    'Recruitment Pipeline',
                    style: _titleStyle(context, size: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track open positions and candidate progress',
                    style: _bodyStyle(context),
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
                  Row(
                    children: [
                      Icon(Icons.timeline, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Candidate Pipeline',
                        style: _titleStyle(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 0.8,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Conversion Rate', style: _bodyStyle(context)),
                            Text(
                              '${provider.metrics.conversionRate}%',
                              style: TextStyle(color: _primaryTextColor(context)),
                            ),
                          ],
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Avg Time to Hire', style: _bodyStyle(context)),
                            Text(
                              '${provider.metrics.averageTimeToHire} days',
                              style: TextStyle(color: _primaryTextColor(context)),
                            ),
                          ],
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
                  Row(
                    children: [
                      Icon(Icons.work, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Open Positions',
                        style: _titleStyle(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (provider.openPositions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No open positions available',
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
                                position.urgency,
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
        ],
      ),
    );
  }

  Widget _buildApplicationsTab(RecruitmentProvider provider) {
    if (provider.applications.isEmpty) {
      return Center(
        child: Text('No applications yet', style: _bodyStyle(context)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.applications.length,
      itemBuilder: (context, index) {
        final app = provider.applications[index];
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
                            app.positionName ?? 'Position not specified',
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
                          color: provider.getStatusColor(app.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: provider.getStatusColor(app.status).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              app.status,
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
                      'Applied: ${app.time ?? DateFormat('MMM dd, yyyy').format(DateTime.parse(app.createdAt ?? DateTime.now().toString()))}',
                      style: _bodyStyle(context, size: 12),
                    ),
                    const Spacer(),
                    if (app.cv != null)
                      IconButton(
                        icon: Icon(Icons.visibility, color: Colors.blue[300]),
                        onPressed: () => _showCVPreview(context, app.cv),
                        tooltip: 'View CV',
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
    _tabController.dispose();
    super.dispose();
  }
}
