import 'package:flutter/material.dart';

import '../data/models/client_model.dart';
import '../screens/clients/vendor_palette.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  final VoidCallback onAssign;
  final VoidCallback onExtend;
  final VoidCallback onDelete;

  const ClientCard({
    super.key,
    required this.client,
    required this.onTap,
    required this.onAssign,
    required this.onExtend,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Card(
      elevation: 0,
      color: VendorPalette.surface(context),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: VendorPalette.border(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: VendorPalette.featureGradient(context),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.business_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: TextStyle(
                            color: VendorPalette.text(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          client.contactPerson ?? 'No contact person',
                          style: TextStyle(
                            color: VendorPalette.mutedText(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      client.status?.toUpperCase() ?? 'UNKNOWN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(icon: Icons.phone_outlined, value: client.phone ?? '-'),
              if (client.pksNumber != null) ...[
                const SizedBox(height: 7),
                _InfoRow(
                  icon: Icons.description_outlined,
                  value: 'PKS: ${client.pksNumber}',
                ),
              ],
              const SizedBox(height: 7),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                value: client.getFormattedContractPeriod(),
              ),
              const SizedBox(height: 12),
              Divider(color: VendorPalette.border(context), height: 1),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 6,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: onAssign,
                    icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                    label: const Text('Assign'),
                    style: TextButton.styleFrom(
                      foregroundColor: VendorPalette.accent(context),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onExtend,
                    icon: const Icon(Icons.update_outlined, size: 16),
                    label: const Text('Extend'),
                    style: TextButton.styleFrom(
                      foregroundColor: VendorPalette.warmAccent(context),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: VendorPalette.danger(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context) {
    switch (client.status) {
      case 'active':
        return VendorPalette.success(context);
      case 'expired':
        return VendorPalette.danger(context);
      case 'pending':
        return VendorPalette.warmAccent(context);
      default:
        return VendorPalette.mutedText(context);
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: VendorPalette.mutedText(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: VendorPalette.mutedText(context),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
