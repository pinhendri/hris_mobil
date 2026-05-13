import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../models/calendar_event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/event_provider.dart';
import 'admin_palette.dart';
import 'add_edit_event_screen.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final companyCode = context.read<AuthProvider>().getCompanyCode();
      context.read<EventProvider>().fetchManagedEvents();
      context.read<EmployeeProvider>().fetchAllEmployees(
        companyCode: companyCode,
      );
    });
  }

  Future<void> _openForm([CalendarEvent? event]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditEventScreen(event: event)),
    );
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminPalette.surface(context),
        surfaceTintColor: AdminPalette.surface(context),
        title: Text(
          context.tr('meeting_delete_title'),
          style: TextStyle(color: AdminPalette.text(context)),
        ),
        content: Text(
          context
              .tr('meeting_delete_message')
              .replaceAll('{title}', event.title),
          style: TextStyle(color: AdminPalette.mutedText(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('meeting_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('meeting_delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<EventProvider>();
    final success = await provider.deleteEvent(event.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.tr('meeting_delete_success')
              : (provider.error ?? context.tr('meeting_delete_failed')),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminPalette.page(context),
      appBar: AppBar(
        title: Text(
          context.tr('meeting_page_title'),
          style: TextStyle(color: AdminPalette.text(context)),
        ),
        backgroundColor: AdminPalette.surface(context),
        surfaceTintColor: AdminPalette.surface(context),
        foregroundColor: AdminPalette.text(context),
        actions: [
          IconButton(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            tooltip: context.tr('meeting_create'),
          ),
          IconButton(
            onPressed: () => context.read<EventProvider>().fetchManagedEvents(),
            icon: Icon(Icons.refresh, color: AdminPalette.mutedText(context)),
            tooltip: context.tr('meeting_retry'),
          ),
        ],
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.managedEvents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.managedEvents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_busy,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AdminPalette.mutedText(context)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: provider.fetchManagedEvents,
                      child: Text(context.tr('meeting_retry')),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.managedEvents.isEmpty) {
            return Center(
              child: Text(
                context.tr('meeting_empty'),
                style: TextStyle(color: AdminPalette.mutedText(context)),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchManagedEvents,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.managedEvents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = provider.managedEvents[index];
                return _EventCard(
                  event: event,
                  onEdit: () => _openForm(event),
                  onDelete: () => _deleteEvent(event),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final primaryText = AdminPalette.text(context);
    final secondaryText = AdminPalette.mutedText(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminPalette.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminPalette.border(context)),
        boxShadow: AdminPalette.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: primaryText,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(context.tr('meeting_edit')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(context.tr('meeting_delete')),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(
                icon: Icons.schedule,
                label: dateFormat.format(event.startsAt),
                color: Colors.blue,
              ),
              _Badge(
                icon: event.isCompanyWide ? Icons.groups : Icons.mail_outline,
                label: event.isCompanyWide
                    ? context.tr('meeting_company_wide')
                    : context
                          .tr('meeting_invitee_count')
                          .replaceAll('{count}', event.inviteCount.toString()),
                color: event.isCompanyWide ? Colors.green : Colors.orange,
              ),
            ],
          ),
          if (event.location.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 18, color: secondaryText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.location,
                    style: TextStyle(color: primaryText),
                  ),
                ),
              ],
            ),
          ],
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(event.description, style: TextStyle(color: secondaryText)),
          ],
          const SizedBox(height: 12),
          Text(
            context
                .tr('meeting_created_by')
                .replaceAll('{name}', event.createdByName),
            style: TextStyle(fontSize: 12, color: secondaryText),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
