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
            return AlertDialog(
              title: const Text('Post New Job'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Department',
                        border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Select Position',
                        border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Urgency',
                        border: OutlineInputBorder(),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Job Requirements',
                        border: OutlineInputBorder(),
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
            return AlertDialog(
              title: const Text('New Application'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Department *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
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
                      decoration: const InputDecoration(
                        labelText: 'Position *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
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
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.description, color: Colors.blue),
                            title: Text(
                              selectedFileName ?? 'No file selected',
                              style: TextStyle(
                                color: selectedFileName != null ? Colors.black : Colors.grey,
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
                          const Divider(height: 0),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Supported formats: PDF, DOC, DOCX (Max 2MB)',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
        return AlertDialog(
          title: const Text('Update Status'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: statuses.length,
              itemBuilder: (context, index) {
                final status = statuses[index];
                return ListTile(
                  title: Text(status),
                  leading: Icon(
                    status == app.status
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: status == app.status ? Colors.blue : Colors.grey,
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
        return AlertDialog(
          title: const Text('CV Document'),
          content: SizedBox(
            width: 400,
            height: 500,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('CV is available for download'),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RecruitmentProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recruitment'),
        bottom: TabBar(
          controller: _tabController,
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
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.work, color: AppColors.primary),
                      title: const Text('Post New Job'),
                      onTap: () {
                        Navigator.pop(context);
                        _showAddJobDialog(context, provider);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add, color: Colors.green),
                      title: const Text('Add Application'),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recruitment Pipeline',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track open positions and candidate progress',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timeline, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Candidate Pipeline',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              stage.stage,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Conversion Rate'),
                            Text('${provider.metrics.conversionRate}%'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: provider.metrics.conversionRate / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Avg Time to Hire'),
                            Text('${provider.metrics.averageTimeToHire} days'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (provider.metrics.averageTimeToHire / 30).clamp(0, 1),
                          backgroundColor: Colors.grey[200],
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.work, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Open Positions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (provider.openPositions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No open positions available'),
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
                          child: ListTile(
                            title: Text(
                              position.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              provider.getDepartmentName(position.department),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
      return const Center(
        child: Text('No applications yet'),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(
                        app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            app.positionName ?? 'Position not specified',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
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
                          Icon(Icons.email, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              app.email,
                              style: const TextStyle(fontSize: 13),
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
                          Icon(Icons.phone, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              app.phone,
                              style: const TextStyle(fontSize: 13),
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
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Applied: ${app.time ?? DateFormat('MMM dd, yyyy').format(DateTime.parse(app.createdAt ?? DateTime.now().toString()))}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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