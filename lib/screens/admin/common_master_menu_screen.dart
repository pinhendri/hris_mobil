import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/department_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'admin_palette.dart';
import 'department_list_screen.dart';

class CommonMasterMenuScreen extends StatelessWidget {
  const CommonMasterMenuScreen({super.key});

  static final List<_MasterMenuConfig> _menus = [
    _MasterMenuConfig(
      title: 'Master Perusahaan',
      subtitle: 'Company Master File',
      endpoint: '/company-master',
      permissions: ['view-company-master', 'assign-roles'],
      icon: Icons.business,
      color: Color(0xFF2563EB),
      fields: [
        _MasterField('Kode', ['c_code']),
        _MasterField('Nama', ['company_name']),
        _MasterField('Kota', ['city']),
        _MasterField('Telepon', ['phone']),
      ],
      searchHint: 'Cari perusahaan...',
    ),
    _MasterMenuConfig(
      title: 'Master PTKP',
      subtitle: 'PTKP Master File',
      endpoint: '/master-ptkp',
      permissions: ['view-ptkp', 'view-settings'],
      icon: Icons.family_restroom,
      color: Color(0xFF059669),
      fields: [
        _MasterField('Kode', ['code']),
        _MasterField('Deskripsi', ['description']),
        _MasterField('PTKP Tahunan', ['ptkp_annual', 'amount'], currency: true),
      ],
      searchHint: 'Cari kode atau deskripsi PTKP...',
    ),
    _MasterMenuConfig(
      title: 'Master Tarif Progresif',
      subtitle: 'Progressive Tax Rate Master File',
      endpoint: '/master-progressive-tax-rates',
      permissions: ['view-progressive-tax-rate', 'view-settings'],
      icon: Icons.percent,
      color: Color(0xFF7C3AED),
      fields: [
        _MasterField('Penghasilan Dari', ['income_from'], currency: true),
        _MasterField('Penghasilan Sampai', ['income_to'], currency: true),
        _MasterField('Tarif', ['rate_percent', 'rate'], percent: true),
        _MasterField('Deskripsi', ['description']),
      ],
      searchHint: 'Cari tarif progresif...',
    ),
    _MasterMenuConfig(
      title: 'Grup User',
      subtitle: 'User Group - Company Assignment',
      endpoint: '/company-assignments',
      permissions: [
        'view-company-assignment',
        'assign-company',
        'assign-roles',
      ],
      icon: Icons.groups_2_outlined,
      color: Color(0xFFEA580C),
      fields: [
        _MasterField('Nama', ['name']),
        _MasterField('Email', ['email']),
        _MasterField('Role', ['role']),
        _MasterField('Company', ['companies'], isCompanyList: true),
      ],
      searchHint: 'Cari user...',
      dataPath: ['data', 'users', 'data'],
    ),
    _MasterMenuConfig(
      title: 'Departemen',
      subtitle: 'Departments',
      endpoint: '/departments',
      permissions: [
        'view-department',
        'create-department',
        'edit-department',
        'delete-department',
      ],
      icon: Icons.business_outlined,
      color: Color(0xFF4158D0),
      fields: [
        _MasterField('Nama', ['name', 'department_name']),
        _MasterField('Kode', ['code', 'department_code']),
        _MasterField('Deskripsi', ['description']),
      ],
      searchHint: 'Cari departemen...',
      screenBuilder: (context) => ChangeNotifierProvider(
        create: (_) => DepartmentProvider(),
        child: const DepartmentListScreen(),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminPalette.page(context),
      appBar: AppBar(
        title: Text(
          'Master Data Umum',
          style: GoogleFonts.poppins(
            color: AdminPalette.text(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AdminPalette.surface(context),
        surfaceTintColor: AdminPalette.surface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AdminPalette.text(context)),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final visibleMenus = _menus
              .where((menu) => authProvider.hasAnyPermission(menu.permissions))
              .toList(growable: false);

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = visibleMenus[index];
              return _MasterMenuCard(config: item);
            },
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemCount: visibleMenus.length,
          );
        },
      ),
    );
  }
}

class _CommonMasterListScreen extends StatefulWidget {
  final _MasterMenuConfig config;

  const _CommonMasterListScreen({required this.config});

  @override
  State<_CommonMasterListScreen> createState() =>
      _CommonMasterListScreenState();
}

class _CommonMasterListScreenState extends State<_CommonMasterListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final endpoint = _buildEndpoint();
      final response = await _apiService.get(endpoint);
      final items = _extractItems(response, widget.config.dataPath);
      setState(() => _items = items);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _buildEndpoint() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return widget.config.endpoint;
    }

    final separator = widget.config.endpoint.contains('?') ? '&' : '?';
    return '${widget.config.endpoint}${separator}search=${Uri.encodeQueryComponent(query)}';
  }

  List<Map<String, dynamic>> _extractItems(
    dynamic response,
    List<String>? preferredPath,
  ) {
    final preferred = _readPath(response, preferredPath);
    if (preferred is List) {
      return preferred.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }

    if (response is List) {
      return response.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }

    if (response is Map) {
      final directData = response['data'];
      if (directData is List) {
        return directData
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList();
      }
      if (directData is Map) {
        for (final key in const ['data', 'items', 'rows', 'users']) {
          final nested = directData[key];
          if (nested is List) {
            return nested
                .whereType<Map>()
                .map(Map<String, dynamic>.from)
                .toList();
          }
        }
      }
    }

    return const [];
  }

  dynamic _readPath(dynamic source, List<String>? path) {
    if (path == null || path.isEmpty) {
      return null;
    }

    dynamic current = source;
    for (final key in path) {
      if (current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final primaryText = AdminPalette.text(context);
    final secondaryText = AdminPalette.mutedText(context);
    final borderColor = AdminPalette.border(context);

    return Scaffold(
      backgroundColor: AdminPalette.page(context),
      appBar: AppBar(
        title: Text(
          config.title,
          style: GoogleFonts.poppins(
            color: primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AdminPalette.surface(context),
        surfaceTintColor: AdminPalette.surface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: primaryText),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: Icon(Icons.refresh, color: secondaryText),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _buildHeader(config),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _loadData(),
                    style: GoogleFonts.poppins(color: primaryText),
                    decoration: InputDecoration(
                      hintText: config.searchHint,
                      hintStyle: GoogleFonts.poppins(color: secondaryText),
                      prefixIcon: Icon(Icons.search, color: secondaryText),
                      filled: true,
                      fillColor: AdminPalette.mutedSurface(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: config.color, width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _isLoading ? null : _loadData,
                  icon: const Icon(Icons.search),
                  style: IconButton.styleFrom(
                    backgroundColor: config.color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isLoading && _items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error.isNotEmpty && _items.isEmpty)
              _buildMessage(
                icon: Icons.error_outline,
                title: 'Gagal memuat data',
                message: _error,
              )
            else if (_items.isEmpty)
              _buildMessage(
                icon: Icons.folder_open,
                title: 'Data belum tersedia',
                message: 'Tidak ada data pada ${config.title}.',
              )
            else
              ..._items.map(
                (item) => _MasterDataCard(config: config, item: item),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(_MasterMenuConfig config) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: config.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(config.icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_items.length} data • ${config.subtitle}',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AdminPalette.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminPalette.border(context)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AdminPalette.mutedText(context)),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AdminPalette.text(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AdminPalette.mutedText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterMenuCard extends StatelessWidget {
  final _MasterMenuConfig config;

  const _MasterMenuCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminPalette.surface(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final screenBuilder = config.screenBuilder;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  screenBuilder ??
                  (_) => _CommonMasterListScreen(config: config),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(config.icon, color: config.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.text(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      config.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AdminPalette.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AdminPalette.mutedText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasterDataCard extends StatelessWidget {
  final _MasterMenuConfig config;
  final Map<String, dynamic> item;

  const _MasterDataCard({required this.config, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = _titleValue();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AdminPalette.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminPalette.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AdminPalette.text(context),
                  ),
                ),
              ),
              if (item['id'] != null)
                Text(
                  '#${item['id']}',
                  style: GoogleFonts.poppins(
                    color: AdminPalette.mutedText(context),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...config.fields.map((field) {
            final value = _fieldValue(field);
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 118,
                    child: Text(
                      field.label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AdminPalette.mutedText(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminPalette.text(context),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _titleValue() {
    for (final key in const [
      'company_name',
      'code',
      'name',
      'email',
      'description',
    ]) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return config.title;
  }

  String _fieldValue(_MasterField field) {
    if (field.isCompanyList) {
      final companies = item[field.keys.first];
      if (companies is List) {
        final names = companies
            .whereType<Map>()
            .map((company) {
              final name = company['company_name']?.toString() ?? '';
              final code = company['c_code']?.toString() ?? '';
              if (name.isEmpty) return code;
              if (code.isEmpty) return name;
              return '$name ($code)';
            })
            .where((value) => value.trim().isNotEmpty)
            .join(', ');
        return names.isEmpty ? '-' : names;
      }
      return '-';
    }

    dynamic raw;
    for (final key in field.keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        raw = value;
        break;
      }
    }

    if (raw == null) return '-';
    if (field.currency) return _formatCurrency(raw);
    if (field.percent) return _formatPercent(raw);
    return raw.toString();
  }

  String _formatCurrency(dynamic value) {
    final number = num.tryParse(value.toString()) ?? 0;
    return 'Rp ${number.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  String _formatPercent(dynamic value) {
    final number = num.tryParse(value.toString()) ?? 0;
    final normalized = number <= 1 ? number * 100 : number;
    return '${normalized.toStringAsFixed(normalized % 1 == 0 ? 0 : 2)}%';
  }
}

class _MasterMenuConfig {
  final String title;
  final String subtitle;
  final String endpoint;
  final IconData icon;
  final Color color;
  final List<_MasterField> fields;
  final String searchHint;
  final List<String> permissions;
  final List<String>? dataPath;
  final WidgetBuilder? screenBuilder;

  const _MasterMenuConfig({
    required this.title,
    required this.subtitle,
    required this.endpoint,
    required this.icon,
    required this.color,
    required this.fields,
    required this.searchHint,
    required this.permissions,
    this.dataPath,
    this.screenBuilder,
  });
}

class _MasterField {
  final String label;
  final List<String> keys;
  final bool currency;
  final bool percent;
  final bool isCompanyList;

  const _MasterField(
    this.label,
    this.keys, {
    this.currency = false,
    this.percent = false,
    this.isCompanyList = false,
  });
}
