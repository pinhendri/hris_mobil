import 'package:flutter/material.dart';
import '../data/models/client_model.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  final VoidCallback onAssign; // Tambahkan parameter onAssign
  final VoidCallback onExtend;
  final VoidCallback onDelete;

  const ClientCard({
    Key? key,
    required this.client,
    required this.onTap,
    required this.onAssign, // Tambahkan required parameter
    required this.onExtend,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan nama dan status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: client.getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: client.getStatusColor(),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      client.status?.toUpperCase() ?? 'UNKNOWN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: client.getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Contact Person
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      client.contactPerson ?? '-',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Phone
              if (client.phone != null)
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        client.phone!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              
              // PKS Number
              if (client.pksNumber != null)
                Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'PKS: ${client.pksNumber}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              
              // Contract Period
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        client.getFormattedContractPeriod(),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Action Buttons - HANYA SATU VERSION, hapus yang duplikat
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Assign Button
                  TextButton.icon(
                    onPressed: onAssign,
                    icon: const Icon(Icons.assignment_ind, size: 16),
                    label: const Text('Assign'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Extend Button
                  TextButton.icon(
                    onPressed: onExtend,
                    icon: const Icon(Icons.update, size: 16),
                    label: const Text('Extend'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Delete Button
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
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
}