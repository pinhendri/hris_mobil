import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'admin_palette.dart';

class UserManagementMenuScreen extends StatelessWidget {
  const UserManagementMenuScreen({super.key});

  static final List<_UserManagementConfig> _menus = [
    _UserManagementConfig(
      title: 'Master Permission',
      subtitle: 'Permission Master File',
      endpoint: '/permission-management/permissions',
      permissions: ['view-permissions', 'view-roles'],
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
      permissions: ['view-roles'],
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
      permissions: ['assign-roles', 'view-roles'],
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
      permissions: ['assign-user', 'assign-roles', 'view-roles'],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _pageColor(isDark),
      appBar: AppBar(
        title: Text(
          'Manajemen User',
          style: GoogleFonts.poppins(
            color: _primaryTextColor(isDark),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _surfaceColor(isDark),
        surfaceTintColor: _surfaceColor(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryTextColor(isDark)),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final visibleMenus = _menus
              .where((menu) => authProvider.hasAnyPermission(menu.permissions))
              .toList(growable: false);

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) =>
                _UserMenuCard(config: visibleMenus[index]),
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemCount: visibleMenus.length,
          );
        },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = _primaryTextColor(isDark);
    final secondaryTextColor = _secondaryTextColor(isDark);
    final borderColor = _borderColor(isDark);

    return Scaffold(
      backgroundColor: _pageColor(isDark),
      appBar: AppBar(
        title: Text(
          config.title,
          style: GoogleFonts.poppins(
            color: primaryTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _surfaceColor(isDark),
        surfaceTintColor: _surfaceColor(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: Icon(Icons.refresh, color: secondaryTextColor),
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
                    style: GoogleFonts.poppins(color: primaryTextColor),
                    decoration: InputDecoration(
                      hintText: config.searchHint,
                      hintStyle: GoogleFonts.poppins(color: secondaryTextColor),
                      prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                      filled: true,
                      fillColor: _mutedSurfaceColor(isDark),
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
                    disabledBackgroundColor: config.color.withValues(
                      alpha: 0.38,
                    ),
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
              _MessageCard(
                icon: Icons.error_outline,
                title: 'Gagal memuat data',
                message: _error,
                isDark: isDark,
              )
            else if (_items.isEmpty)
              _MessageCard(
                icon: Icons.folder_open,
                title: 'Data belum tersedia',
                message: 'Tidak ada data pada ${config.title}.',
                isDark: isDark,
              )
            else
              ..._items.map(
                (item) =>
                    _UserDataCard(config: config, item: item, isDark: isDark),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: _surfaceColor(isDark),
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
                        color: _primaryTextColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      config.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _secondaryTextColor(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: _secondaryTextColor(isDark),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.color,
            config.color.withValues(alpha: isDark ? 0.78 : 0.92),
          ],
        ),
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
  final bool isDark;

  const _UserDataCard({
    required this.config,
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleValue(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: _primaryTextColor(isDark),
            ),
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
                        color: _secondaryTextColor(isDark),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _fieldValue(field),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _primaryTextColor(isDark),
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
  final bool isDark;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surfaceColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor(isDark)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: _secondaryTextColor(isDark)),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: _primaryTextColor(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _secondaryTextColor(isDark),
            ),
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
  final List<String> permissions;
  final List<String>? dataPath;

  const _UserManagementConfig({
    required this.title,
    required this.subtitle,
    required this.endpoint,
    required this.icon,
    required this.color,
    required this.fields,
    required this.searchHint,
    required this.permissions,
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

Color _pageColor(bool isDark) {
  return isDark ? AdminPalette.darkPage : AdminPalette.lightPage;
}

Color _surfaceColor(bool isDark) {
  return isDark ? AdminPalette.darkSurface : AdminPalette.lightSurface;
}

Color _mutedSurfaceColor(bool isDark) {
  return isDark
      ? AdminPalette.darkMutedSurface
      : AdminPalette.lightMutedSurface;
}

Color _primaryTextColor(bool isDark) {
  return isDark ? AdminPalette.darkText : AdminPalette.lightText;
}

Color _secondaryTextColor(bool isDark) {
  return isDark ? AdminPalette.darkMutedText : AdminPalette.lightMutedText;
}

Color _borderColor(bool isDark) {
  return isDark ? AdminPalette.darkBorder : AdminPalette.lightBorder;
}
