import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/employee_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import 'admin_palette.dart';

class OrgStructureScreen extends StatefulWidget {
  const OrgStructureScreen({super.key});

  @override
  State<OrgStructureScreen> createState() => _OrgStructureScreenState();
}

class _OrgStructureScreenState extends State<OrgStructureScreen> {
  String _query = '';

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _screenBackgroundColor => AdminPalette.page(context);
  Color get _surfaceColor => AdminPalette.surface(context);
  Color get _borderColor => AdminPalette.border(context);
  Color get _primaryTextColor => AdminPalette.text(context);
  Color get _secondaryTextColor => AdminPalette.mutedText(context);
  Color get _accentColor =>
      _isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmployees();
    });
  }

  Future<void> _loadEmployees() async {
    final auth = context.read<AuthProvider>();
    await context.read<EmployeeProvider>().fetchAllEmployees(
      companyCode: auth.getCompanyCode(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final employees = provider.employees;
    final nodes = _buildTree(employees);
    final filteredNodes = _query.trim().isEmpty
        ? nodes
        : _filterTree(nodes, _query.trim().toLowerCase());
    final employeeCount = employees.length;
    final rootCount = nodes.length;

    return Scaffold(
      backgroundColor: _screenBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Struktur Organisasi',
          style: GoogleFonts.poppins(
            color: _primaryTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _screenBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryTextColor),
        actions: [
          IconButton(
            onPressed: provider.isLoading ? null : _loadEmployees,
            icon: Icon(Icons.refresh, color: _primaryTextColor),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEmployees,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _buildSummaryCard(
              employeeCount: employeeCount,
              rootCount: rootCount,
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              style: GoogleFonts.poppins(color: _primaryTextColor),
              cursorColor: _accentColor,
              decoration: InputDecoration(
                hintText: 'Cari nama, posisi, atau departemen...',
                hintStyle: GoogleFonts.poppins(color: _secondaryTextColor),
                prefixIcon: Icon(Icons.search, color: _secondaryTextColor),
                filled: true,
                fillColor: _surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _accentColor),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (provider.isLoading && employees.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: _accentColor),
                ),
              )
            else if ((provider.error ?? '').isNotEmpty && employees.isEmpty)
              _buildMessageCard(
                icon: Icons.error_outline,
                title: 'Gagal memuat struktur',
                message: provider.error ?? 'Terjadi kesalahan',
                actionLabel: 'Coba Lagi',
                onAction: _loadEmployees,
              )
            else if (filteredNodes.isEmpty)
              _buildMessageCard(
                icon: Icons.account_tree_outlined,
                title: 'Data struktur belum tersedia',
                message:
                    'Pastikan data karyawan dan immediate supervisor sudah diisi.',
              )
            else
              ...filteredNodes.map((node) => _OrgNodeTile(node: node)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required int employeeCount,
    required int rootCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_tree_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organizational Structure',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$employeeCount karyawan • $rootCount root level',
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

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 46, color: _secondaryTextColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _secondaryTextColor,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }

  List<_OrgNode> _buildTree(List<Employee> employees) {
    final nodesByUuid = <String, _OrgNode>{};
    final nodesById = <String, _OrgNode>{};

    for (final employee in employees) {
      final node = _OrgNode(employee: employee);
      if (employee.uuid.trim().isNotEmpty) {
        nodesByUuid[employee.uuid.trim()] = node;
      }
      if (employee.id.trim().isNotEmpty) {
        nodesById[employee.id.trim()] = node;
      }
    }

    final roots = <_OrgNode>[];
    for (final node in nodesByUuid.values) {
      final supervisorId = node.employee.managerId?.trim() ?? '';
      final parent = supervisorId.isEmpty
          ? null
          : nodesByUuid[supervisorId] ?? nodesById[supervisorId];

      if (parent == null || identical(parent, node)) {
        roots.add(node);
      } else {
        parent.children.add(node);
      }
    }

    int compareNode(_OrgNode a, _OrgNode b) =>
        a.employee.name.toLowerCase().compareTo(b.employee.name.toLowerCase());
    void sortChildren(_OrgNode node) {
      node.children.sort(compareNode);
      for (final child in node.children) {
        sortChildren(child);
      }
    }

    roots.sort(compareNode);
    for (final root in roots) {
      sortChildren(root);
    }

    return roots;
  }

  List<_OrgNode> _filterTree(List<_OrgNode> nodes, String query) {
    final result = <_OrgNode>[];
    for (final node in nodes) {
      final children = _filterTree(node.children, query);
      if (_matches(node.employee, query) || children.isNotEmpty) {
        result.add(_OrgNode(employee: node.employee, children: children));
      }
    }
    return result;
  }

  bool _matches(Employee employee, String query) {
    return [
      employee.name,
      employee.positionName,
      employee.position,
      employee.departmentDescription,
      employee.department,
      employee.supervisorName,
    ].whereType<String>().join(' ').toLowerCase().contains(query);
  }
}

class _OrgNode {
  final Employee employee;
  final List<_OrgNode> children;

  _OrgNode({required this.employee, List<_OrgNode>? children})
    : children = children ?? <_OrgNode>[];
}

class _OrgNodeTile extends StatelessWidget {
  final _OrgNode node;
  final int depth;

  const _OrgNodeTile({required this.node, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1B1D20) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2F3338)
        : const Color(0xFFE5E7EB);
    final primaryTextColor = isDark
        ? const Color(0xFFF5F7FA)
        : const Color(0xFF111827);
    final secondaryTextColor = isDark
        ? const Color(0xFFA8ADB7)
        : const Color(0xFF64748B);
    final mutedTextColor = isDark
        ? const Color(0xFF7D8592)
        : const Color(0xFF9CA3AF);
    final accentColor = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB);
    final employee = node.employee;
    final hasChildren = node.children.isNotEmpty;
    final department = _firstNonEmpty([
      employee.departmentDescription,
      employee.department,
      'No Department',
    ]);
    final position = _firstNonEmpty([
      employee.positionName,
      employee.position,
      'No Position',
    ]);

    return Padding(
      padding: EdgeInsets.only(left: depth == 0 ? 0 : 18.0, bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: depth == 0
                ? accentColor.withValues(alpha: 0.34)
                : borderColor,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            expansionTileTheme: ExpansionTileThemeData(
              iconColor: secondaryTextColor,
              collapsedIconColor: secondaryTextColor,
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: depth < 2,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: CircleAvatar(
              backgroundColor: accentColor.withValues(
                alpha: isDark ? 0.22 : 0.12,
              ),
              child: Text(
                _initials(employee.name),
                style: GoogleFonts.poppins(
                  color: isDark ? const Color(0xFFDBEAFE) : accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              employee.name.isEmpty ? 'Unknown' : employee.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                Text(
                  department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
            trailing: hasChildren
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(
                        alpha: isDark ? 0.18 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      node.children.length.toString(),
                      style: GoogleFonts.poppins(
                        color: isDark ? const Color(0xFFDBEAFE) : accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  )
                : const SizedBox(width: 24),
            children: hasChildren
                ? node.children
                      .map(
                        (child) => _OrgNodeTile(node: child, depth: depth + 1),
                      )
                      .toList(growable: false)
                : [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 62),
                        child: Text(
                          'Tidak ada bawahan langsung',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: mutedTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '-';
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
