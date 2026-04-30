import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';

class UserManagementMenuScreen extends StatelessWidget {
  const UserManagementMenuScreen({super.key});

  static final List<_UserManagementConfig> _menus = [
    _UserManagementConfig(
      title: 'Master Permission',
      subtitle: 'Permission Master File',
      endpoint: '/permission-management/permissions',
      icon: Icons.key_outlined,
      color: Color(0xFF7C3AED),
      fields: [
        _UserField('Permission', ['name']),
        _UserField('Guard', ['guard_name']),
        _UserField('Dibuat', ['created_at']),
      ],
      searchHint: 'Cari permission...',
    ),
    _UserManagementConfig(
      title: 'Master Role',
      subtitle: 'Role Master',
      endpoint: '/role-management/roles',
      icon: Icons.admin_panel_settings_outlined,
      color: Color(0xFF2563EB),
      fields: [
        _UserField('Role', ['name']),
        _UserField('Guard', ['guard_name']),
      ],
      searchHint: 'Cari role...',
    ),
    _UserManagementConfig(
      title: 'Assign Role ke Grup',
      subtitle: 'Group Assign Roles',
      endpoint: '/role-management/group-roles',
      icon: Icons.fact_check_outlined,
      color: Color(0xFF059669),
      fields: [
        _UserField('Role', ['name']),
        _UserField('Guard', ['guard_name']),
        _UserField('Permissions', ['permissions'], isPermissionList: true),
      ],
      searchHint: 'Cari role group...',
    ),
    _UserManagementConfig(
      title: 'Assign Grup ke User',
      subtitle: 'User Assign Group',
      endpoint: '/roles',
      icon: Icons.manage_accounts_outlined,
      color: Color(0xFFEA580C),
      fields: [
        _UserField('Nama', ['name']),
        _UserField('Email', ['email']),
        _UserField('Roles', ['roles'], isStringList: true),
        _UserField('Permissions', ['permissions'], isStringList: true),
      ],
      searchHint: 'Cari user...',
      dataPath: ['data', 'users'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(
          'Manajemen User',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => _UserMenuCard(config: _menus[index]),
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemCount: _menus.length,
      ),
    );
  }
}

class _UserManagementListScreen extends StatefulWidget {
  final _UserManagementConfig config;

  const _UserManagementListScreen({required this.config});

  @override
  State<_UserManagementListScreen> createState() =>
      _UserManagementListScreenState();
}

class _UserManagementListScreenState extends State<_UserManagementListScreen> {
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
      final response = await _apiService.get(_buildEndpoint());
      setState(() => _items = _extractItems(response));
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _buildEndpoint() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return widget.config.endpoint;
    final separator = widget.config.endpoint.contains('?') ? '&' : '?';
    return '${widget.config.endpoint}${separator}search=${Uri.encodeQueryComponent(query)}';
  }

  List<Map<String, dynamic>> _extractItems(dynamic response) {
    final preferred = _readPath(response, widget.config.dataPath);
    if (preferred is List) {
      return preferred.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }

    if (response is List) {
      return response.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }

    if (response is Map) {
      for (final candidate in [
        response['data'],
        response['permissions'],
        response['roles'],
        response['users'],
      ]) {
        if (candidate is List) {
          return candidate
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .toList();
        }
        if (candidate is Map) {
          for (final key in const [
            'data',
            'items',
            'rows',
            'permissions',
            'roles',
            'users',
          ]) {
            final nested = candidate[key];
            if (nested is List) {
              return nested
                  .whereType<Map>()
                  .map(Map<String, dynamic>.from)
                  .toList();
            }
          }
        }
      }
    }

    return const [];
  }

  dynamic _readPath(dynamic source, List<String>? path) {
    if (path == null) return null;
    dynamic current = source;
    for (final key in path) {
      if (current is! Map) return null;
      current = current[key];
    }
    return current;
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(
          config.title,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _Header(config: config, count: _items.length),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _loadData(),
                    decoration: InputDecoration(
                      hintText: config.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _isLoading ? null : _loadData,
                  icon: const Icon(Icons.search),
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
              _MessageCard(
                icon: Icons.error_outline,
                title: 'Gagal memuat data',
                message: _error,
              )
            else if (_items.isEmpty)
              _MessageCard(
                icon: Icons.folder_open,
                title: 'Data belum tersedia',
                message: 'Tidak ada data pada ${config.title}.',
              )
            else
              ..._items.map(
                (item) => _UserDataCard(config: config, item: item),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserMenuCard extends StatelessWidget {
  final _UserManagementConfig config;

  const _UserMenuCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _UserManagementListScreen(config: config),
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
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      config.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final _UserManagementConfig config;
  final int count;

  const _Header({required this.config, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: config.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: Colors.white, size: 34),
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
                Text(
                  '$count data • ${config.subtitle}',
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
}

class _UserDataCard extends StatelessWidget {
  final _UserManagementConfig config;
  final Map<String, dynamic> item;

  const _UserDataCard({required this.config, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleValue(),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...config.fields.map(
            (field) => Padding(
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
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _fieldValue(field),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleValue() {
    for (final key in const ['name', 'email', 'guard_name']) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return config.title;
  }

  String _fieldValue(_UserField field) {
    final raw = item[field.keys.first];
    if (field.isPermissionList) {
      if (raw is List) {
        final values = raw
            .map((value) {
              if (value is Map) return value['name']?.toString() ?? '';
              return value.toString();
            })
            .where((value) => value.trim().isNotEmpty)
            .join(', ');
        return values.isEmpty ? '-' : values;
      }
      return '-';
    }
    if (field.isStringList) {
      if (raw is List) {
        final values = raw.map((value) => value.toString()).join(', ');
        return values.trim().isEmpty ? '-' : values;
      }
      return raw?.toString() ?? '-';
    }

    for (final key in field.keys) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '-';
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Colors.grey[500]),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _UserManagementConfig {
  final String title;
  final String subtitle;
  final String endpoint;
  final IconData icon;
  final Color color;
  final List<_UserField> fields;
  final String searchHint;
  final List<String>? dataPath;

  const _UserManagementConfig({
    required this.title,
    required this.subtitle,
    required this.endpoint,
    required this.icon,
    required this.color,
    required this.fields,
    required this.searchHint,
    this.dataPath,
  });
}

class _UserField {
  final String label;
  final List<String> keys;
  final bool isPermissionList;
  final bool isStringList;

  const _UserField(
    this.label,
    this.keys, {
    this.isPermissionList = false,
    this.isStringList = false,
  });
}
